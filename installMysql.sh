#!/bin/bash

set -e

# Ensure 'sudo' is available
if ! command -v sudo &> /dev/null; then
    echo "Installing sudo..."
    apt-get update
    apt-get install -y sudo
fi

# Update the package list
sudo apt-get update -y

# Install MySQL server and sysbench
sudo apt-get install -y mysql-server sysbench wget

# Secure MySQL installation
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'root_password'; FLUSH PRIVILEGES;"

# Configure MySQL to allow remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Create the sakila database and user
sudo mysql -u root -p'root_password' -e "CREATE DATABASE sakila;"
sudo mysql -u root -p'root_password' -e "CREATE USER 'sakila_user'@'%' IDENTIFIED BY 'password';"
sudo mysql -u root -p'root_password' -e "GRANT ALL PRIVILEGES ON sakila.* TO 'sakila_user'@'%'; FLUSH PRIVILEGES;"

# Download and install Sakila database
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xvzf sakila-db.tar.gz
cd sakila-db
sudo mysql -u root -p'root_password' sakila < sakila-schema.sql
sudo mysql -u root -p'root_password' sakila < sakila-data.sql

# Run sysbench to benchmark the database
sudo sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" prepare
sudo sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" run
