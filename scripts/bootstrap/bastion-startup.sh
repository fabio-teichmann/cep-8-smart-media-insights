#!/bin/bash
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

echo "region: $AWS_REGION"
echo "cluster-name: $CLUSTER_NAME"

aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"