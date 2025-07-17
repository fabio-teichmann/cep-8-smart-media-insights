#!/bin/bash
if [[ -z "${AWS_REGION}" || -z "${CLUSTER_NAME}" ]]; then
  echo "[ERROR] AWS_REGION or CLUSTER_NAME is empty."
  exit 1
fi

echo "☸️ -- acquiring kubeconfig..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

echo "🔁 -- updating kube config path (root user)..."
export KUBECONFIG="/root/.kube/config"

echo "📥 -- downloading Helm charts from S3..."
sudo aws s3 cp s3://cep-8-static-bucket/helm/smart-media-0.1.0.tgz .
sudo tar -xzf smart-media-0.1.0.tgz

echo "🔍 -- Waiting for ALB webhook endpoint to become available..."

for i in {1..30}; do
  ready=$(kubectl get endpoints -n kube-system aws-load-balancer-webhook-service -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
  if [[ ! -z "$ready" ]]; then
    echo "✅ -- ALB webhook service is ready."
    break
  fi
  echo "⏳ -- Waiting for webhook endpoint..."
  sleep 5
done

# deploy app using helm
echo "🪖 -- installing helm charts..."
helm upgrade -i smart-media ./smart-media \
    --set region="${AWS_REGION}" \
    --set image.repository="${DOCKERHUB_USER}"/smart-media \
    --set env.logfireUrl="${LOGFIRE_URL}" \
    --set env.logfireProjectName="${LOGFIRE_PROJECT_NAME}" \
    --set secrets.logfireApiToken="${LOGFIRE_API_KEY}" \
    --set env.dynamoTable="${DYNAMO_TABLE}" \
    --set env.kdsStreamName="${KDS_STREAM_NAME}" \
    --set env.s3MediaBucket="${S3_MEDIA_BUCKET}" \
    --set serviceAccount.name="${SVC_ACC_NAME}" \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${SVC_ACC_ANNOT}"
