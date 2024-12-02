# Output for Gatekeeper
output "gatekeeper_public_dns" {
  description = "Public DNS for the Gatekeeper instance"
  value       = aws_instance.gatekeeper.public_dns
}

output "gatekeeper_public_ip" {
  description = "Public IP for the Gatekeeper instance"
  value       = aws_instance.gatekeeper.public_ip
}

output "gatekeeper_private_ip" {
  description = "Private IP for the Gatekeeper instance"
  value       = aws_instance.gatekeeper.private_ip
}

output "gatekeeper_instance_id" {
  description = "Instance ID for the Gatekeeper instance"
  value       = aws_instance.gatekeeper.id
}

# Output for Proxy
output "proxy_public_dns" {
  description = "Public DNS for the Proxy instance"
  value       = aws_instance.proxy.public_dns
}

output "proxy_public_ip" {
  description = "Public IP for the Proxy instance"
  value       = aws_instance.proxy.public_ip
}

output "proxy_private_ip" {
  description = "Private IP for the Proxy instance"
  value       = aws_instance.proxy.private_ip
}

output "proxy_instance_id" {
  description = "Instance ID for the Proxy instance"
  value       = aws_instance.proxy.id
}

# Output for Manager
output "manager_public_dns" {
  description = "Public DNS for the Manager instance"
  value       = aws_instance.manager.public_dns
}

output "manager_public_ip" {
  description = "Public IP for the Manager instance"
  value       = aws_instance.manager.public_ip
}

output "manager_private_ip" {
  description = "Private IP for the Manager instance"
  value       = aws_instance.manager.private_ip
}

output "manager_instance_id" {
  description = "Instance ID for the Manager instance"
  value       = aws_instance.manager.id
}

# Output for Workers
output "worker_public_dns" {
  description = "Public DNS for the Worker instances"
  value       = [for instance in aws_instance.workers : instance.public_dns]
}

output "worker_public_ips" {
  description = "Public IPs for the Worker instances"
  value       = [for instance in aws_instance.workers : instance.public_ip]
}

output "worker_private_ips" {
  description = "Private IPs for the Worker instances"
  value       = [for instance in aws_instance.workers : instance.private_ip]
}

output "worker_instance_ids" {
  description = "Instance IDs for the Worker instances"
  value       = [for instance in aws_instance.workers : instance.id]
}
