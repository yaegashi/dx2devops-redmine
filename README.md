# Redmine on Azure App Service

## Introduction

DX2 DevOps solution for [Redmine] or [RedMica] on [Azure Web App for Containers].

The project provides public container images at ghcr.io
and suggests the workflow that supports the complete life cycle of Redmine apps (create/update/backup/restore)
on the Azure App Service infrastructure.
It utilizes a variety of App Service features like app settings, persistent storage, SSH connections, etc.

[Redmine]: https://github.com/redmine/redmine
[RedMica]: https://github.com/redmica/redmica
[Azure Web App for Containers]: https://azure.microsoft.com/ja-jp/services/app-service/containers


## Container features

### Application settings / environment variables

|Variable|Description|
|---|---|
|`WEBSITES_ENABLE_APP_SERVICE_STORAGE`|Set `true` to mount a persistent storage on /home in App Service containers.|
|`RAILS_ENV`|Set `production` or `development`|
|`RAILS_IN_SERVICE`|Set `true` to start the rails server normally.  Otherwise it enters the maintenance mode.|
|`SECRET_KEY_BASE`|Set a random string to encrypt rails session cookies.|
|`DATABASE_URL`|Rails database configuration.  See [the guide for configuring a database](https://guides.rubyonrails.org/configuring.html#configuring-a-database)|

### Files and directories in a container

|Path|Description|
|---|---|
|`/redmine/`|Redmine app|
|`/docker/`|Various DevOps scripts and assets|
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

When the container boots with `RAILS_IN_SERVICE=false` in the app settings,
it enters the maintenance mode.

In the maintenance mode,
the container only serves a static site from `/home/site/wwwroot/staticsite/`.
You can safely get the shell and do any maintenance tasks in the container with an SSH connection
via Azure Portal or Azure CLI ([az webapp ssh] or [az webapp create-remote-connection]).

After the maintenance is over, you should set `RAILS_IN_SERVICE=true` in the app settings.
It causes the container to restart and make the Redmine app in service.

[az webapp ssh]: https://docs.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-ssh
[az webapp create-remote-connection]: https://docs.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-create-remote-connection

### `rmops` command

`rmops` is a maintenance command available in the container.
It has many sub commands and helps you with various tasks like
the database initialization, the initial setup of Redmine app, backup/restore (planned), etc.

```console
root@6228b40cf3a8:~# rmops
Commands:
  rmops entrypoint      # Container entrypoint
  rmops help [COMMAND]  # Describe available commands or one specific command
  rmops passwd          # Reset user password
  rmops setup           # Set up Redmine instance
  rmops sql             # Generate SQL to initialize database
```

The usage details will be explained as needed in the document.

### Persistent files

In Azure App Service,
files to preserve should be stored in the persistent storage
mounted on `/home/site/wwwroot`.
Any changes outside `/home/site/wwwroot` will be lost when the instance restarts.
Note that you have to set `WEBSITES_ENABLE_APP_SERVICE_STORAGE=true` in the app settings
to mount the persistent storage on `/home/site/wwwroot`.

Therefore, in the Redmine containers,
many files and directories in `/redmine` are symbolic links to ones in `/home/site/wwwroot`.
Creating links is done by `rmops entrypoint` every time a container boots.
You can utilize it to inject your instance-specific modifications.
For example, you can place Redmine plugins in `/home/site/wwwroot/plugins`,
Redmine themes in `/home/site/wwwroot/public/themes`,
Rails `configuration.yml` in `/home/site/wwwroot/config/configuration.yml`, and so on.

## Deploy to Azure App Service

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
    RAILS_IN_SERVICE=false
    SECRET_KEY_BASE=<very long random string>
    DATABASE_URL=<database connection settings, see below>
    ```
4. Restart the instance.  It gets up and running in the maintenance mode.
5. Log into the instance using SSH on Azure Portal.
    - Run `rmops sql` to generate SQL statement to initialize the database:
        ```console
        root@6228b40cf3a8:~# rmops sql
        -- Database URL: mysql2://test1_7ee9e7cf%40test1-7ee9e7cf:CI8zeEf5r2%24%26%28r%249zQvNSA2%3EYh3lq7%7B7@test1-7ee9e7cf.mariadb.database.azure.com/test1_7ee9e7cf?encoding=utf8mb4&sslverify=true
        -- Run the following command to connect to the database host as an admin user:
        -- mysql -vv -u <admin-user> -p -h test1-7ee9e7cf.mariadb.database.azure.com --ssl
        DROP DATABASE IF EXISTS `test1_7ee9e7cf`;
        DROP USER IF EXISTS 'test1_7ee9e7cf'@'%';
        CREATE USER 'test1_7ee9e7cf'@'%' IDENTIFIED BY 'CI8zeEf5r2$&(r$9zQvNSA2>Yh3lq7{7';
        CREATE DATABASE IF NOT EXISTS `test1_7ee9e7cf` DEFAULT CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_520_ci`;
        GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, REFERENCES ON `test1_7ee9e7cf`.* TO 'test1_7ee9e7cf'@'%';
        ```
      You have to enter the SQL into your database server using the standard client like `mysql` or `psql`:
        ```console
        root@6228b40cf3a8:~# rmops sql | mysql -vv -u db_admin@test1-7ee9e7cf -p -h test1-7ee9e7cf.mariadb.database.azure.com --ssl
        Password: <- Enter db_admin@test1-7ee9e7cf password
        ```
    - Run `rmops setup` to run the database migration and do the initial setup of the Redmine app.
      It will show initial password for `admin` user at last.  Don't forget to note this.
        ```console
        root@6228b40cf3a8:~# rmops setup
        ...
        I, [2022-06-05T18:52:11.206518 #72]  INFO -- : Enter Redmine at /redmine
        I, [2022-06-05T18:52:31.645480 #72]  INFO -- : Reset password for user "admin"
        I, [2022-06-05T18:52:31.647095 #72]  INFO -- : New password: "tLtLGWFK7VqzZ8TS"
        ```
6. Set `RAILS_IN_SERVICE=true` in the app settings.  It causes the instance to restart.
7. Open the app web site with your browser.

### Database connection configuration

You have to specify the database connection configuration in `DATABASE_URL` in the app settings.
See [the guide for configuring a database](https://guides.rubyonrails.org/configuring.html#configuring-a-database) for details.

`DATABASE_URL` example for MySQL or MariaDB servers (mysql2 adapter):

    mysql2://username%40servername:password@servername.mariadb.database.azure.com/dbname?encoding=utf8mb4&sslverify=true

- Caveats for Azure Database products:
    - `username@servername` (URL encoded) for the login name.
    - `sslverify=true` is required to connect the server using SSL.

### Automation with Terraform

Using the Terraform project in [terraform/test1](terraform/test1),
you can easily deploy your Redmine app for testing along with a MariaDB instance on Azure.

## Local development

[docker-compose.yml](docker-compose.yml) is provided
so that you can easily build and test Redmine container images.
Using a devcontainer is also recommended.

1. Place Redmine sources in `redmine` directory.
You can clone it from the official repository by either of the following commands:
    * Run `git clone https://github.com/redmine/redmine` for Redmine
    * Run `git clone https://github.com/redmica/redmica redmine` for RedMica
2. Copy file [`docker.env.example`](docker.env.example) to `docker.env`.
3. Copy file [`.env.example`](.env.example) to `.env` and set `COMPOSE_PROFILES` in it.
Choose one of the supported profiles: `sqlite`, `mysql`, `mariadb`, `postgres`.
4. Run `docker-compose build` to build a container image.
5. Run `docker-compose up -d` to start containers in the background.
    * The redmine container creates `./data/wwwroot` for `/home/site/wwwroot` volume.
    * The redmine container enters the maintenance mode because `RAILS_IN_SERVICE=false` in `docker.env`.
    * The database container creates `./data/mysql` etc. for the database volume.
6. Do the following initial setups in the container:
    1. Invoke a shell in the redmine container by either of the following methods:
        * Run `docker-compose exec redmine-<profile> bash`
        * Run `ssh root@localhost -p 3333`.  The password is `Docker!`.
    2. Run `rmops sql | $DB_ADMIN_CMD`
    3. Run `rmops setup`.  Note the admin user's password.
    4. Exit from the shell.
7. Update `RAILS_IN_SERVICE=true` in `docker.env`.
8. Run `docker-compose up -d` again to restart the redmine container.
9. Open http://localhost:8080 with your web browser to test the Redmine app.

## Development roadmap

### Done

- Support persistent storage (uploaded files, themes, plugins, etc.)
- Support SSH remote shell and maintenance mode
- `rmops` maintenance commands
    - Generate SQL to initialize a database
    - Database migration and initial setupnitial setup
    - Reset user password

### Todo

- Support sending emails from the App Service environment
- Support EasyAuth integration to Redmine user authentication
- `rmops` features
    - Backup/restore
