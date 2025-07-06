#!/bin/bash
if [[ -z "${AWS_REGION}" || -z "${CLUSTER_NAME}" ]]; then
  echo "[ERROR] AWS_REGION or CLUSTER_NAME is empty."
  exit 1
fi

echo "☸️ -- acquiring kubeconfig..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

echo "🔁 -- updating kube config path (root user)..."
export KUBECONFIG="../../root/.kube/config"

# deploy app using helm
echo "🪖 -- installing helm charts...
helm upgrade -i smart-media ./helm-charts/smart-media \
    --set image.repository="${DOCKERHUB_USER}"/smart-media \
    --set env.logfireUrl="${LOGFIRE_URL}" \
    --set env.logfireProjectName="${LOGFIRE_PROJECT_NAME}" \
    --set secrets.logfireApiToken="${LOGFIRE_API_KEY}" \
    --set serviceAccount.name="${SVC_ACC_NAME}" ${{ steps.extract.outputs.svc_acc_name }} \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${SVC_ACC_ANNOT"} ${{steps.extract.outputs.svc_acc_annot}}

    