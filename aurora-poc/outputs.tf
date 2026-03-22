output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "aurora_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command to connect Aurora via Bastion"
  value       = "ssh -i <your-key.pem> -L 3306:${aws_rds_cluster.aurora.endpoint}:3306 ec2-user@${aws_instance.bastion.public_ip} -N"
}

output "mysql_connect_command" {
  description = "MySQL connect command (after SSH tunnel)"
  value       = "mysql -h 127.0.0.1 -P 3306 -u ${var.db_username} -p ${var.db_name}"
}
