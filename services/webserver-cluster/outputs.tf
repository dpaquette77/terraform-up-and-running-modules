output "public_ip" {
  value = aws_lb.example.dns_name
  description = "DNS name of the load balancer"
}

output "asg_name" {
  value = aws_autoscaling_group.example.name
  description = "the autoscaling group name"
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "the alb's dns name"
}
