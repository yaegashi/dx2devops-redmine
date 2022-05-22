#!/bin/bash

set -ex

apt-get update
apt-get install -y --no-install-recommends openssh-server default-mysql-client-core postgresql-client sqlite3
apt-get clean
echo "root:Docker!" | chpasswd
cp /docker/build1/sshd_config /etc/ssh
mkdir -p /run/sshd
