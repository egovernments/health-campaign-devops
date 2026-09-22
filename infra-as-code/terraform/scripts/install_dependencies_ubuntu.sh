#!/bin/bash

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install curl
sudo apt install -y curl

# Verify curl installation
curl --version

# Download and install kubectl
KUBECTL_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fLO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --short --client

# Install k9s
curl -fLO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
sudo apt install -y ./k9s_linux_amd64.deb
rm -f k9s_linux_amd64.deb
k9s version

# Download and install aws-iam-authenticator
AIA_VER=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/aws-iam-authenticator/releases/latest | grep -m1 '"tag_name"' | cut -d'"' -f4)
AIA_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
AIA_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fLo aws-iam-authenticator "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${AIA_VER}/aws-iam-authenticator_${AIA_VER#v}_${AIA_OS}_${AIA_ARCH}"
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
aws-iam-authenticator help

# Download and install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform version

# Update system packages
sudo apt update

# Install Git
sudo apt install -y git
git --version

# Install Go
sudo apt install -y golang-go

# Install Helm using the official installer script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
rm -f get_helm.sh
