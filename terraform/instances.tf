resource "aws_instance" "gatekeeper" {
  ami           = var.ami_id
  instance_type = var.instance_type_gatekeeper
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.gatekeeper_sg.id]

  tags = {
    Name = "Gatekeeper"
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    # Add custom setup for the gatekeeper application
  EOT
}

resource "aws_instance" "proxy" {
  ami           = var.ami_id
  instance_type = var.instance_type_proxy
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.proxy_sg.id]

  tags = {
    Name = "Proxy"
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y haproxy
    # Add custom setup for proxy configuration
  EOT
}

# Manager Instance
resource "aws_instance" "manager" {
  ami           = var.ami_id
  instance_type = var.instance_type_manager
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.manager_sg.id]

  tags = {
    Name = "Manager"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Update packages and install MySQL
    sudo apt-get update
    sudo apt-get install -y mysql-server sysbench wget

    # Secure MySQL installation
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'root_password'; FLUSH PRIVILEGES;"

    # Allow MySQL remote access
    sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql

    # Create sakila database and user
    sudo mysql -u root -p'root_password' -e "CREATE DATABASE sakila;"
    sudo mysql -u root -p'root_password' -e "CREATE USER 'sakila_user'@'%' IDENTIFIED BY 'password';"
    sudo mysql -u root -p'root_password' -e "GRANT ALL PRIVILEGES ON sakila.* TO 'sakila_user'@'%'; FLUSH PRIVILEGES;"

    # Download and install Sakila database
    wget https://downloads.mysql.com/docs/sakila-db.tar.gz
    tar -xvzf sakila-db.tar.gz
    cd sakila-db
    sudo mysql -u root -p'root_password' sakila < sakila-schema.sql
    sudo mysql -u root -p'root_password' sakila < sakila-data.sql

    # Benchmark the database with sysbench
    sudo sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" prepare
    sudo sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" run
  EOT
}

# Worker Instances
resource "aws_instance" "workers" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type_worker
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.worker_sg.id]

  tags = {
    Name = "Worker-${count.index + 1}"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Update packages and install MySQL
    sudo apt-get update
    sudo apt-get install -y mysql-server sysbench wget

    # Secure MySQL installation
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'root_password'; FLUSH PRIVILEGES;"

    # Allow MySQL remote access
    sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql

    # Create sakila database and user
    sudo mysql -u root -p'root_password' -e "CREATE DATABASE sakila;"
    sudo mysql -u root -p'root_password' -e "CREATE USER 'sakila_user'@'%' IDENTIFIED BY 'password';"
    sudo mysql -u root -p'root_password' -e "GRANT ALL PRIVILEGES ON sakila.* TO 'sakila_user'@'%'; FLUSH PRIVILEGES;"

    # Download and install Sakila database
    wget https://downloads.mysql.com/docs/sakila-db.tar.gz
    tar -xvzf sakila-db.tar.gz
    cd sakila-db
    sudo mysql -u root -p'root_password' sakila < sakila-schema.sql
    sudo mysql -u root -p'root_password' sakila < sakila-data.sql

    # Benchmark the database with sysbench
    sudo sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" prepare
    sudo sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sakila --mysql-user="sakila_user" --mysql-password="password" run
  EOT
}

