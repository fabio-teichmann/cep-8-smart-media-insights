apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${role_arn}
      username: ${role_name}bastion-ssm-role
      groups:
        - system:masters
