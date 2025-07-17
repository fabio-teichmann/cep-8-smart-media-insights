## TerraForm
- upgrade to 6.0 ?
- restrict resources in eks IRSA policies
```hcl
resources = [
  "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stream/${var.kinesis_stream_name}",
  "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}",
  "arn:aws:s3:::${var.app_bucket_name}/*"
]
```

## Networking
- add VPC endpoint for logging once NAT gateway is disabled:
```hcl
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Dynamo (status lookup)
- set TTL parameter
    - attribute of type Number
    - Represent a Unix epoch timestamp in seconds

## Security
- Store PEMs (if used) in AWS Secrets Manager or Parameter Store.


## CI/CD (GHA and GitOps)
- create self-hosted runner for smoother and more complete destruction (run `kubectl` commands within the CI/CD flow)
- persist bastion access key:
```zsh
terraform output -raw bastion_private_key > bastion.pem
chmod 600 bastion.pem
ssh -i bastion.pem ec2-user@<bastion-public-ip>
```
- ~~install ALB Controller first, THEN the local helm chart~~
- install eks module: `helm repo add eks https://aws.github.io/eks-charts`
- self-hosted github actions runner for deployment instead of through bastion host
- use Flux / ArgoCD from inside the cluster for deployments


## Helm
When you're ready to install controllers or cluster add-ons via Helm, remember to include:
- AWS ALB Ingress Controller (via Helm)
- Metrics Server (for HPA/autoscaling)

- Make sure `var.app_alb_port` matches the containerPort in your Kubernetes Service and Deployment.


## ALB
- Use AWS WAF with the ALB to filter malicious traffic.
- In production: ensure SSL termination at the ALB, and use HTTPS only.


## EKS
- ensure IAM roles complete
- IRSA annotations (kinesis + dynamo)
- add SG rules for Kinesis and Dynamo 
- use SA (svc acc) for bastion to access cluster for bootstrap?

💡 Tip: You can use AWS-managed prefix lists (e.g., com.amazonaws.us-east-1.dynamodb) to target VPC endpoint destinations in SGs:
cidr_blocks = [aws_vpc_endpoint.dynamodb.prefix_list_id]



## Bastion Host
- ~~decide whether to use locally generated key-pair or AWS SSM agent~~ --> SSM
- script for SSM:
```hcl
resource "aws_iam_role" "ssm_role" {
  name = "ssm-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name = "bastion"
  }
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "bastion-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}
```