# test1: basic deployment

## Introduction

This Terraform project deploys the following resources in a single resource group:

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

## Deployment

Run the following commands in this directory:

```
az login
terraform init
terraform plan
terraform apply
```

`terraform apply` will show you output like the following at last:

```text
...
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

appsvc_id = "/subscriptions/1345aada-c7ce-4a7a-aa5f-35fa9a8ccb79/resourceGroups/test1-7ee9e7cf/providers/Microsoft.Web/sites/test1-7ee9e7cf"
appsvc_name = "test1-7ee9e7cf"
db_admin_cmd = "mysql --ssl -vv -p -u db_admin@test1-7ee9e7cf -h test1-7ee9e7cf.mariadb.database.azure.com"
db_admin_name = "db_admin@test1-7ee9e7cf"
db_admin_pass = <sensitive>
db_host = "test1-7ee9e7cf.mariadb.database.azure.com"
db_name = "test1_7ee9e7cf"
db_user_cmd = "mysql --ssl -vv -p -u test1_7ee9e7cf@test1-7ee9e7cf -h test1-7ee9e7cf.mariadb.database.azure.com"
db_user_name = "test1_7ee9e7cf@test1-7ee9e7cf"
db_user_pass = <sensitive>
rg_name = "test1-7ee9e7cf"
```

Use `terraform output` to get the sensitive values:

```console
$ terraform output db_admin_pass
"oJARL5ksBUyyg9a)snKgL7n&&%iXL#cU"
```

`db_admin_cmd` value is exposed to `DB_ADMIN_CMD` in the app settings.
After connecting to the app container via SSH in Azure Portal,
you can create the app database with the following command:

```console
root@09bd1557a6d3:~# rmops sql | $DB_ADMIN_CMD 
Enter password: <- Enter db_admin_pass here
--------------
DROP DATABASE IF EXISTS `test1_7ee9e7cf`
--------------

Query OK, 0 rows affected, 1 warning

--------------
DROP USER IF EXISTS 'test1_7ee9e7cf'@'%'
--------------

Query OK, 0 rows affected, 1 warning

--------------
CREATE USER 'test1_7ee9e7cf'@'%' IDENTIFIED BY 'CI8zeEf5r2$&(r$9zQvNSA2>Yh3lq7{7'
--------------

Query OK, 0 rows affected

--------------
CREATE DATABASE IF NOT EXISTS `test1_7ee9e7cf` DEFAULT CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_520_ci`
--------------

Query OK, 1 row affected

--------------
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, REFERENCES ON `test1_7ee9e7cf`.* TO 'test1_7ee9e7cf'@'%'
--------------

Query OK, 0 rows affected

Bye
```

After creating the app database,
run `rmops setup` to migrate it and set up the app:

```console
root@09bd1557a6d3:~# rmops setup
I, [2022-06-05T16:56:44.367366 #23]  INFO -- : Enter directory at /redmine
I, [2022-06-05T16:56:44.375745 #23]  INFO -- : Remove ["files", "public/plugin_assets"]
I, [2022-06-05T16:56:44.376481 #23]  INFO -- : Create ["/home/site/wwwroot/files", "/home/site/wwwroot/public/plugin_assets"]
I, [2022-06-05T16:56:44.380988 #23]  INFO -- : Symlink "/home/site/wwwroot/files" to "./files"
I, [2022-06-05T16:56:44.381597 #23]  INFO -- : Symlink "/home/site/wwwroot/public/plugin_assets" to "./public/plugin_assets"
I, [2022-06-05T16:56:44.386952 #23]  INFO -- : Enter directory at /redmine
I, [2022-06-05T16:56:44.387326 #23]  INFO -- : Run "rake db:migrate"
...
I, [2022-06-05T16:59:01.125947 #23]  INFO -- : Enter Redmine at /redmine
I, [2022-06-05T16:59:01.316846 #23]  INFO -- : Reset password for user "admin"
I, [2022-06-05T16:59:01.317972 #23]  INFO -- : New password: "WuP4eeKLJvQByqi4"
```

Note the new password for the Redmine admin user shown at last.

Update `RAILS_IN_SERVICE=true` in the app settings.
It causes the app to restart and leave the maintenance mode.

Open the app web site with your browser.
You will finally get the Redmine app running on Azure App Service.
