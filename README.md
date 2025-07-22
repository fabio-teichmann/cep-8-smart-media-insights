# cep_8_smart_media_insights
Smart Media Insights Platform for Images and Text


## System Architecture

The MVP is set out to have the following architecture:

![Smart Media Platform Arch MVP](/arch/system_arch_v2.png)

> [!NOTE]
> For testing and simplicity, I will omit DNS plus certification in the beginning, as well as the RDS database. For a simple lookup of results, DynamoDB can serve this purpose.

**Excluded from MVP**:
- DNS + Certification
- extended monitoring (e.g., Cluster metrics) --> logging across app and lambda functions implemented using Pydantic Logfire
- ECR --> used Docker Hub for testing
- RDS database as result storage


## Architecture Considerations

### EKS Load Balancing
There are essentially two ways to configure an ALB for EKS:
1. defining all resources in TerraForm declaratively, or 
2. using AWS Load Balancer Controller through Helm annotations + Ingress

> [!IMPORTANT]
> I diverted from declaring resources directly back to using the Controller. It is cleaner for setting ALB up, although it creates resources in AWS that TerraForm can't destroy out of the box. (Need to delete `Ingress` objects that hook into the controller before Terraform teardown).


### App-endpoint setup
1. single app for both endpoints: easier to setup and deploy (MVP), less appropriate if endpoints need different scaling behavior
2. separate deployments on EKS: more yamls and moving parts, slightly more complex to configure

> [!IMPORTANT]
> For simplicity I will choose a **single app for both endpoints** as a starting point. Option 2 will be kept in the refactor log for later versions (e.g., if endpoint access patterns reveal stark differences).

---

## Current manual setups:
> [!NOTE]
> Currently, the CI/CD automation does not work end-to-end due to EKS's additional security layer (user registered in ConfigMap -- `aws-auth`) for authentication. Once this is done from the admin, all else works as expected. I deferred solving this "minor" issue for the benefit of moving forward with the MVP.

After `terraform apply`, update cluster ConfigMap to add bastion host:
```bash
aws eks update-kubeconfig --region us-east-1 --name smart-media-eks

eksctl create iamidentitymapping --cluster smart-media-eks --region us-east-1 --arn arn:aws:iam::<ACC_NUM>:role/smart-media-bastion-ssm-role --group system:masters --username smart-media-bastion-ssm-role
```

---

## Next Steps:

| Feature | Description | Priority |
| :-- | :-- | :--: |
| Self-hosted GHA runner | This will allow to reduce the multitude of responsibilities the bastion host currently has (also potential security risk) | medium |
| GitOps for CD | | high |
| Ramp-up Monitoring | Currently only using Logfire which greatly helped debugging the app and lambda functions. Need a more consolidated picture of the other components (esp. k8s) | high |
| Replace Kinesis with Kafka | Goal is understand complexity and cost implications. Kafka might be overkill for this project | medium-high |
| Add RDS for ML results | As intended in the architecture diagram | high |
| API Docs | For completeness; the API itself is rather simple | medium |
| Separate API endpoints into single deployments | This will allow independent scaling of resources for the endpoints | medium-high |
