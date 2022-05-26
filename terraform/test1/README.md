# Terraform deployment

```
az login
terraform init
terraform plan
terraform apply
```

It deploys the following resources in a single resource group:

- App Service plan
- App Service instance
- Azure Database for MariaDB
- Log Analytics workspace

Configuration variables:

|Variable|Default|Description|
|---|---|---|
|`prefix`|`test1`|Name prefix of resources|
|`location`|`westus2`||
|`docker_image`|`ghcr.io/yaegashi/dx2devops-redmine/redmica`||
|`docker_image_tag`|`latest`||
