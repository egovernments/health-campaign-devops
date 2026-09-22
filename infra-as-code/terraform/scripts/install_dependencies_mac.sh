#!/bin/bash

# Install Homebrew (if not installed)
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew
brew update

# Install curl
brew install curl

# Verify curl installation
curl --version

# Download and install kubectl
KUBECTL_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fLO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --short --client

# Install k9s
brew install k9s
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
curl -fL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm -f AWSCLIV2.pkg
aws --version

# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version

# Install Git
brew install git
git --version

# Install Go
brew install go

# Add Helm GPG key

# Install Helm
brew install helm
