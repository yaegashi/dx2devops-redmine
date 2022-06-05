#!/bin/bash

set -ex

apt-get update
apt-get install -y --no-install-recommends \
    less vim ghostscript openssh-server \
    default-mysql-client postgresql-client sqlite3
apt-get clean
gem install thor
echo "root:Docker!" | chpasswd
cp /docker/build1/sshd_config /etc/ssh
mkdir -p /run/sshd
