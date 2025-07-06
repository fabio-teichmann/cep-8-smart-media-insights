#!/bin/bash
if [[ -z "${AWS_REGION}" || -z "${CLUSTER_NAME}" ]]; then
  echo "[ERROR] AWS_REGION or CLUSTER_NAME is empty."
  exit 1
fi
echo "Acquiring kubeconfig..."

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
echo "kube config path..."
ls $PATH/.kube
sudo $PATH/.kube

echo "Caller Identity:"
echo aws sst get-caller-identity

echo "Setting config path..."
export KUBECONFIG="../../root/.kube/"

# echo "Copying config to user dir 'ssm-user'..."
# sudo mv ~/.kube/config ../../home/ssm-user/.kube/config

# Create required policies for ALB controller
echo "Creating service account for ALB Controller..."

sudo curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.0/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
    --cluster="${CLUSTER_NAME}" \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
    --override-existing-serviceaccounts \
    --region "${AWS_REGION}" \
    --approve

# Add to Helm
echo "Installing ALB Controller from Helm chart..."

helm repo add eks https://aws.github.io/eks-charts

helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${CLUSTER_NAME}" \
  --set region="${AWS_REGION}" \
  --set vpcId="${VPC_ID}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --version 1.13.0
