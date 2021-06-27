#!/bin/sh

SSH_KEY_PATH=""

# Install infrastructure
cd /infrastructure
terraform init --upgrade
terraform apply --auto-approve

# Run the Ansible Playbook to install/configure MongoDB
cd ../provisioning
ansible-playbook --private-key $SSH_KEY_PATH -u ubuntu ./mongodb.yml

# Build the custom container with plain-text connection string
cd ../application
docker build -t alannix/frontend:latest .
docker push alannix/frontend:latest

# kubectl apply -f kubernetes-manifests.yaml
