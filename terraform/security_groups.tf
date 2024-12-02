# Security Group for Gatekeeper
resource "aws_security_group" "gatekeeper_sg" {
  name        = "gatekeeper-sg"
  description = "Allow internet access and communication with the trusted host (proxy)"
  vpc_id      = var.vpc_id

  # Allow HTTP and HTTPS traffic from the internet
  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow MySQL traffic to Proxy (using Proxy CIDR range)
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }
}

# Security Group for Proxy (Trusted Host)
resource "aws_security_group" "proxy_sg" {
  name        = "proxy-sg"
  description = "Allow traffic from Gatekeeper and communicate with Manager and Workers"
  vpc_id      = var.vpc_id

  # Allow MySQL traffic from Gatekeeper
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }

  # Allow MySQL traffic from Manager and Workers
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }

  # Allow egress to Manager and Workers
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }
}

# Security Group for Manager
resource "aws_security_group" "manager_sg" {
  name        = "manager-sg"
  description = "Allow traffic from Proxy for read and write operations"
  vpc_id      = var.vpc_id

  # Allow MySQL traffic from Proxy
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }

  # Allow outgoing traffic to Workers for replication
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }
}

# Security Group for Workers
resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "Allow traffic from Proxy for read-only operations"
  vpc_id      = var.vpc_id

  # Allow read-only traffic from Proxy
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }

  # Allow outgoing responses to Proxy
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Adjust based on your VPC CIDR
  }
}
