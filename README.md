# Redmine on Azure App Service

## Introduction

DevOps solution for [Redmine] or [RedMica] on [Azure Web App for Containers].

[Redmine]: https://github.com/redmine/redmine
[RedMica]: https://github.com/redmica/redmica
[Azure Web App for Containers]: https://azure.microsoft.com/ja-jp/services/app-service/containers

## Architecture

App settings or environment variables

|Variable|Description|
|---|---|
|`WEBSITES_ENABLE_APP_SERVICE_STORAGE`|Set `true` to mount a persistent storage on /home in the App Service environment.|
|`RAILS_ENV`|Set `production` or `development`|
|`RAILS_IN_SERVICE`|Set a non-emptpy string to start the rails server normally.  Otherwise it enters the maintenance mode.|
|`SECRET_KEY_BASE`|Set a random string to encrypt rails session cookies.|
|`DATABASE_URL`|Rails database configuration.  See [the guide for configuring a database](https://guides.rubyonrails.org/configuring.html#configuring-a-database)|

Files and directories in a container

|Path|Description|
|---|---|
|`/redmine/`|Redmine app|
|`/docker/`|Various DevOps scripts and assets|
|`/docker/entrypoint.sh`|Container entrypoint|
|`/home/site/wwwroot/`|Persistent data|
|`/home/site/wwwroot/redmine.sqlite3`|Default sqlite3 database in development|
|`/home/site/wwwroot/staticsite/`|Static site root for the maintenance mode|
|`/home/site/wwwroot/backups/`|Site backups|
|`/home/site/wwwroot/files/`|Symlinked from `/redmine/files`|
|`/home/site/wwwroot/plugins/*`|Symlinked from `/redmine/plugins/*`|
|`/home/site/wwwroot/public/themes/*`|Symlinked from `/redmine/public/themes/*`|
|`/home/site/wwwroot/public/plugin_assets`|Symlinked from `/redmine/public/plugin_assets`|

## Local development

Use docker-compose to build a container image and test a Redmine app in it:

1. Place a Redmine app in `redmine` directory.
You can clone the official repository by eihter of the following commands:
    * Run `git clone https://github.com/redmine/redmine` for Redmine
    * Run `git clone https://github.com/redmica/redmica redmine` for RedMica
2. Copy `docker.env.example` to `docker.env`
3. Run `docker-compose build` to build a container image.
4. Run `docker-compose up -d` to start a container in the background.
    * It creates `wwwroot` directory for `/home/site/wwwroot` volume in the container.
    * It enters the maintenance mode because `RAILS_IN_SERVICE` in `docker.env` is empty.
5. Do the following initial setups in the container:
    1. Invoke a shell in the container by either of the following methods:
        * Run `docker-compose exec redmine /bin/bash`
        * Run `ssh root@localhost -p 3333`.  The password is `Docker!`.
    2. Run `rake db:migrate` in `/redmine`
    3. Run `rake redmine:plugins:migrate` in `/redmine`
    4. Exit the shell.
6. Edit `docker.env` and set `RAILS_IN_SERVICE=1`
7. Run `docker-compose restart` to restart the container.
8. Open http://localhost:8080 with your web browser to test the Redmine app.
