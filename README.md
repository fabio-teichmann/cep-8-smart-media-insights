# cep_8_smart_media_insights
Smart Media Insights Platform for Images and Text


## System Architecture

The MVP is set out to have the following architecture:

![Smart Media Platform Arch MVP](arch/arch/system_arch_v2.png)

> [!NOTE]
> For testing and simplicity, I will omit DNS plus certification in the beginning, as well as the RDS database. For a simple lookup of results, DynamoDB can serve this purpose.


## Architecture Considerations

### EKS Load Balancing
There are essentially two ways to configure an ALB for EKS:
1. defining all resources in TerraForm declaratively, and 
2. using AWS Load Balancer Controller through Helm annotations + Ingress

> [!IMPORTANT]
> I diverted from declaring resources directly back to using the Controller. It is cleaner for setting ALB up, although it creates resources in AWS that TerraForm can't destroy out of the box.


### App-endpoint setup
1. single app for both endpoints: easier to setup and deploy (MVP), less appropriate if endpoints need different scaling behavior
2. separate deployments on EKS: more yamls and moving parts, slightly more complex to configure

> [!IMPORTANT]
> For simplicity I will choose a single app for both endpoints as a starting point. Option 2 will be kept in the refactor log for later versions (e.g., if endpoint access patterns reveal stark differences).
    