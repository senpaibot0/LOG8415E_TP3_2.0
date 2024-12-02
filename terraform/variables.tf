# Key Pair Name
variable "key_name" {
  description = "Key pair name to access the instances"
  default     = "anouar_Key"
}
# Subnet ID
variable "subnet_id" {
  description = "Subnet ID to launch the instances in"
  default     = "subnet-04c9bebc2d09b29bb"
}

# VPC ID
variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  default     = "vpc-09d763f760182231c"
}

# AMI ID
variable "ami_id" {
  description = "AMI ID for the instances"
  default     = "ami-0866a3c8686eaeeba"
}

# Instance Types
variable "instance_type_gatekeeper" {
  description = "Instance type for the Gatekeeper"
  default     = "t2.large"
}

variable "instance_type_proxy" {
  description = "Instance type for the Proxy (Trusted Host)"
  default     = "t2.large"
}

variable "instance_type_manager" {
  description = "Instance type for the Manager"
  default     = "t2.micro"
}

variable "instance_type_worker" {
  description = "Instance type for the Workers"
  default     = "t2.micro"
}

# Number of Workers
variable "worker_count" {
  description = "Number of worker instances to create"
  default     = 2
}

# VPC and Subnet Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

# Security Group Port Configuration
variable "http_port" {
  description = "HTTP port for incoming connections"
  default     = 80
}

variable "https_port" {
  description = "HTTPS port for incoming connections"
  default     = 443
}

variable "mysql_port" {
  description = "MySQL port for database connections"
  default     = 3306
}
