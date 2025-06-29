#!/bin/bash
# check successful parameter injection
if [[ -z "${AWS_REGION}" || -z "${CLUSTER_NAME}" ]]; then
  echo "[ERROR] AWS_REGION or CLUSTER_NAME is empty."
  exit 1
fi

yum update -y
yum install -y curl unzip amazon-ssm-agent --skip-broken --allowerasing

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# curl "https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.0/2023-06-23/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
# chmod +x /usr/local/bin/kubectl

# installations for GitHub Actions
# Helm
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
sudo chmod 700 get_helm.sh && \
sudo ./get_helm.sh

# kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
sudo chmod +x kubectl 
sudo mv kubectl /usr/local/bin/

# eksctl
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

sudo curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
sudo curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
sudo tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && sudo rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

sudo aws s3 cp s3://${AWS_STATIC_BUCKET}/scripts/bootstrap/eks-alb-controller.sh /usr/local/src/bootstrap/eks-alb-controller.sh
sudo chmod +x /usr/local/src/bootstrap/eks-alb-controller.sh

# setting up kubeconfig
# echo "region: ${AWS_REGION}"
# echo "cluster-name: ${CLUSTER_NAME}"

# echo "Setting up kubeconfig..."
# aws eks update-kubeconfig \
#     --region "${AWS_REGION}" \
#     --name "${CLUSTER_NAME}"