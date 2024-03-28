output "ec2Id" {
  description = "The ID of the security group"
  value = aws_security_group.sg_ec2.id
}

output "lbId" {
  description = "The ID of the security group"
  value = aws_security_group.sg_lb.id
}