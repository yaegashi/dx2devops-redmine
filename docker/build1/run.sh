#!/bin/bash

set -ex

apt-get update
apt-get install -y --no-install-recommends \
    lsb-release

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" >/etc/apt/sources.list.d/pgdg.list
curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get update
apt-get install -y --no-install-recommends \
    less vim ghostscript openssh-server \
    sqlite3 \
    default-mysql-client \
    postgresql-client-11 \
    postgresql-client-12 \
    postgresql-client-13 \
    postgresql-client-14 \
    postgresql-client-15

apt-get clean

gem install thor webrick

echo "root:Docker!" | chpasswd
cp /docker/build1/sshd_config /etc/ssh
mkdir -p /run/sshd
