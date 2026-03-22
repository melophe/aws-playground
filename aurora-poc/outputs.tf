output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = aws_instance.bastion.id
}

output "aurora_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "ssm_tunnel_command" {
  description = "SSM port forwarding command to connect Aurora via Bastion"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{\"host\":[\"${aws_rds_cluster.aurora.endpoint}\"],\"portNumber\":[\"3306\"],\"localPortNumber\":[\"3306\"]}'"
}

output "mysql_connect_command" {
  description = "MySQL connect command (after SSM tunnel)"
  value       = "mysql -h 127.0.0.1 -P 3306 -u ${var.db_username} -p ${var.db_name}"
}
