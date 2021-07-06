resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.vpc_name}-EKS-Cluster-Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.vpc_name}-EKS-Node-Group-Role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.public_subnets[*].id
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

data "aws_security_group" "eks_security_group" {
  id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "eks_allow_http" {
  security_group_id = data.aws_security_group.eks_security_group.id

  description = "Allow HTTP from ANY"
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.vpc_name}-Node-Group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public_subnets[*].id

  ami_type = "AL2_x86_64"

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}

output "eks_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}
