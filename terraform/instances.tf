resource "aws_instance" "gatekeeper" {
  ami           = var.ami_id
  instance_type = var.instance_type_gatekeeper
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.gatekeeper_sg.id]

  tags = {
    Name = "Gatekeeper"
  }


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

}

