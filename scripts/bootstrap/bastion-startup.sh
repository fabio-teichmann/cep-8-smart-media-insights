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

# TODO: link waiting time to actual object existence in S3
echo "⏳ -- Waiting for bootstrap script upload to complete..."
for i in {1..30}; do
    sleep 1
done

echo "📥 -- downloading bootstrap scripts from s3://${AWS_STATIC_BUCKET}/scripts/bootstrap/..."
echo " -> eks-alb-controller script"
sudo aws s3 cp s3://${AWS_STATIC_BUCKET}/scripts/bootstrap/eks-alb-controller.sh /usr/local/src/bootstrap/eks-alb-controller.sh
sudo chmod +x /usr/local/src/bootstrap/eks-alb-controller.sh

echo " -> helm-deploy-eks script"
sudo aws s3 cp s3://${AWS_STATIC_BUCKET}/scripts/bootstrap/helm-deploy-eks.sh /usr/local/src/bootstrap/helm-deploy-eks.sh
sudo chmod +x /usr/local/src/bootstrap/helm-deploy-eks.sh

echo " -> cloudformation-cleanup script"
sudo aws s3 cp s3://${AWS_STATIC_BUCKET}/scripts/bootstrap/cloudformation-cleanup.sh /usr/local/src/bootstrap/cloudformation-cleanup.sh
sudo chmod +x /usr/local/src/bootstrap/cloudformation-cleanup.sh

# signal bootstrap ready
touch /var/log/startup_done
echo "START_UP SUCCESS" > /var/log/startup_done

#     if aws s3api head-object --bucket "{$AWS_STATIC_BUCKET}" --key "scripts/bootstrap/eks-alb-controller.sh" 2>/dev/null; then
#         echo "✅ -- Object exists"

        
#         exit 0
    
#     else
#         echo "⏳ -- Waiting for bootstrap script upload to complete..."
#         sleep 5
#     fi
# done

# echo "❌ -- Object does NOT exist"
# exit 1