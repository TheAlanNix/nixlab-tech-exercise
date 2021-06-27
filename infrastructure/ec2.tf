data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "mongodb" {
  availability_zone = var.db_availability_zone

  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.db_instance_type
  key_name             = var.db_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_allow_all_profile.id

  network_interface {
    network_interface_id = aws_network_interface.mongodb.id
    device_index         = 0
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.db_volume_size
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ${path.module}/../provisioning/hosts"
  }
}

resource "aws_network_interface" "mongodb" {
  subnet_id       = aws_subnet.public_subnets[0].id
  security_groups = [aws_security_group.mongodb.id]
}

resource "aws_security_group" "mongodb" {
  name        = "MongoDB"
  description = "Security Group for MongoDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Access from Self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow MongoDB from VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Allow SSH from ANY"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "ec2_allow_all_profile" {
  name = "ec2AllowAllProfile"
  role = aws_iam_role.ec2_allow_all_role.name
}

resource "aws_iam_role" "ec2_allow_all_role" {
  name = "ec2AllowAllRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_allow_all_policy" {
  name = "ec2AllowAllPolicy"

  role   = aws_iam_role.ec2_allow_all_role.name
  policy = data.aws_iam_policy_document.ec2_allow_all_policy.json
}

data "aws_iam_policy_document" "ec2_allow_all_policy" {
  version = "2012-10-17"

  statement {
    sid       = "EC2AllowAll"
    actions   = ["ec2:*"]
    resources = ["*"]
  }
}
