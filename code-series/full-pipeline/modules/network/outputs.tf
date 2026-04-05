output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "blue_target_group_name" {
  value = aws_lb_target_group.blue.name
}

output "green_target_group_name" {
  value = aws_lb_target_group.green.name
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}
