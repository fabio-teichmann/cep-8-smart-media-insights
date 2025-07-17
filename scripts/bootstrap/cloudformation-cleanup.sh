#!/bin/bash

CLUSTER_NAME="smart-media-eks"
NAMESPACE="kube-system"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
AWS_REGION="us-east-1"

# Delete ServiceAccount if it exists
if kubectl get sa "$SERVICE_ACCOUNT_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Deleting ServiceAccount: $SERVICE_ACCOUNT_NAME"
  kubectl delete sa "$SERVICE_ACCOUNT_NAME" -n "$NAMESPACE"
fi

# Delete related CloudFormation stack
STACK_NAME="eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-${NAMESPACE}-${SERVICE_ACCOUNT_NAME}"

if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Deleting CloudFormation stack: $STACK_NAME"
  aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION"
else
  echo "No CFN stack named $STACK_NAME found."
fi
