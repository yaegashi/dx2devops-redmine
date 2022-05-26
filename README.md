# Redmine on Azure App Service

## Introduction

DX2 DevOps solution for [Redmine] or [RedMica] on [Azure Web App for Containers].

The project provides public container images at ghcr.io
and suggests the workflow that supports the full life cycle of Redmine apps (create/update/backup/restore)
on the Azure App Service infrastructure.

[Redmine]: https://github.com/redmine/redmine
[RedMica]: https://github.com/redmica/redmica
[Azure Web App for Containers]: https://azure.microsoft.com/ja-jp/services/app-service/containers

## Container features

### Application settings / environment variables

|Variable|Description|
|---|---|
|`WEBSITES_ENABLE_APP_SERVICE_STORAGE`|Set `true` to mount a persistent storage on /home in App Service containers.|
|`RAILS_ENV`|Set `production` or `development`|
|`RAILS_IN_SERVICE`|Set a non-emptpy string to start the rails server normally.  Otherwise it enters the maintenance mode.|
|`SECRET_KEY_BASE`|Set a random string to encrypt rails session cookies.|
|`DATABASE_URL`|Rails database configuration.  See [the guide for configuring a database](https://guides.rubyonrails.org/configuring.html#configuring-a-database)|

### Files and directories in a container

|Path|Description|
|---|---|
|`/redmine/`|Redmine app|
|`/docker/`|Various DevOps scripts and assets|
|`/docker/do-setup.sh`|Rails initial setup script|
|`/docker/init/entrypoint.sh`|Container entrypoint script|
|`/home/site/wwwroot/`|Persistent data|
|`/home/site/wwwroot/redmine.sqlite3`|Default sqlite3 database in development|
|`/home/site/wwwroot/staticsite/`|Static site root for the maintenance mode|
|`/home/site/wwwroot/backups/`|Site backups|
|`/home/site/wwwroot/files/`|Symlinked from `/redmine/files`|
|`/home/site/wwwroot/config/*`|Symlinked from `/redmine/config/*`|
|`/home/site/wwwroot/plugins/*`|Symlinked from `/redmine/plugins/*`|
|`/home/site/wwwroot/public/themes/*`|Symlinked from `/redmine/public/themes/*`|
|`/home/site/wwwroot/public/plugin_assets`|Symlinked from `/redmine/public/plugin_assets`|

### Maintenance mode

When the container boots with `RAILS_IN_SERVICE` being unset or empty,
it enters the maintenance mode.

In the maintenance mode,
the container only serves a static site from `/home/site/wwwroot/staticsite/`.
You can safely get the shell and do any maintenance tasks in the container with an SSH connection
via Azure Portal or Azure CLI ([az webapp ssh] or [az webapp create-remote-connection]).

It assumes that admins should perform the initial setup for the Redmine app in the maintenance mode:
so you should run common rake tasks like `db:migrate` and `redmine:plugins:migrate` there.
After the setup, you should set `RAILS_IN_SERVICE=1`
and restart the container to make the Redmine app in service.

[az webapp ssh]: https://docs.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-ssh
[az webapp create-remote-connection]: https://docs.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-create-remote-connection

### Persistent data

In Azure App Service,
files to preserve should be stored in the persistent storage
mounted on `/home/site/wwwroot`.
Any changes outside `/home/site/wwwroot` will be lost when the instance restarts.
Note that you have to set `WEBSITES_ENABLE_APP_SERVICE_STORAGE=true` in the application settings
to mount the persistent storage on `/home/site/wwwroot`.

Therefore, in the Redmine containers,
many files and directories in `/redmine` are symbolic links to ones in `/home/site/wwwroot`.
Creating links is done by [`/docker/init/entrypoint.sh`](docker/init/entrypoint.sh)
every time a container boots.
You can utilize it to inject your instance-specific modifications.
For example, you can place Redmine plugins in `/home/site/wwwroot/plugins`,
Redmine themes in `/home/site/wwwroot/public/themes`,
Rails `configuration.yml` in `/home/site/wwwroot/config/configuration.yml`, and so on.

## App Service deployment

### Manual deployment steps

1. Prepare a database instance for your Redmine app.
Azure Database for MySQL/MariaDB/PostgreSQL are supported.
2. Create an Azure App Service instance.
Configure a Linux single container app and specify a container image from the following:
   - `ghcr.io/yaegashi/dx2devops-redmine/redmine`
   - `ghcr.io/yaegashi/dx2devops-redmine/redmica`
3. Specify the following application settings:
    ```
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true
    RAILS_ENV=production
    RAILS_IN_SERVICE=
    SECRET_KEY_BASE=<very long random string>
    DATABASE_URL=<database connection settings, see below>
    ```
4. Restart the instance.  It gets up and running in the maintenance mode.
5. Log into the instance using SSH on Azure Portal.
Run `/docker/do-setup.sh` to set up the database and perform the initial migration:
6. Set a non-empty string in `RAILS_IN_SERVICE` in the application settings:
    ```
    RAILS_IN_SERVICE=1
    ```
7. Restart the instance.  This time it starts the rails server and your Redmine app is now in service.

### Database connection settings

You have to specify the database connection settings in `DATABSE_URL`.
See [the guide for configuring a database](https://guides.rubyonrails.org/configuring.html#configuring-a-database) for details.

`DATABSE_URL` example for a MariaDB instance:

    mysql2://username%40servername:password@servername.mariadb.database.azure.com/dbname?encoding=utf8mb4&sslca=/etc/ssl/certs/Baltimore_CyberTrust_Root.pem

- Note that you have to use `username@servername` for authenticatation.
- `sslca=/etc/ssl/certs/Baltimore_CyberTrust_Root.pem` is specified to force Rails to connect the database using SSL.
You usually need SSL to connect to public endpoints of Azure database services.

### Terraform deployment

Using Terraform definitions in [terraform/test1](terraform/test1),
you can easily deploy your Redmine app for testing along with dependent resources on Azure.

## Local development

[docker-compose.yml](docker-compose.yml) is provided
so that you can easily build and test Redmine container images.
Using a devcontainer is also recommended.

1. Place Redmine sources in `redmine` directory.
You can clone it from the official repository by either of the following commands:
    * Run `git clone https://github.com/redmine/redmine` for Redmine
    * Run `git clone https://github.com/redmica/redmica redmine` for RedMica
2. Copy file `docker.env.example` to `docker.env`.
3. Create file `.env` with content like this.  Choose one of the supported database profiles (`sqlite`, `mysql`, `mariadb`, `postgres`).
    ```
    COMPOSE_PROFILES=sqlite
    ```
4. Run `docker-compose build` to build a container image.
5. Run `docker-compose up -d` to start containers in the background.
    * The redmine container creates `wwwroot` directory for `/home/site/wwwroot` volume.
    * The redmine container enters the maintenance mode because `RAILS_IN_SERVICE` is empty in `docker.env`.
    * The database container creates `db` directory for the data volume.
6. Do the following initial setups in the container:
    1. Invoke a shell in the redmine container by either of the following methods:
        * Run `docker-compose exec redmine-<profile> bash`
        * Run `ssh root@localhost -p 3333`.  The password is `Docker!`.
    2. Run `/docker/do-setup.sh`
    4. Exit the shell.
7. Edit `docker.env` and set `RAILS_IN_SERVICE=1`
8. Run `docker-compose up -d` again to restart the redmine container.
9. Open http://localhost:8080 with your web browser to test the Redmine app.
