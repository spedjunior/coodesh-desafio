output "subnetPrivate" {
  value = aws_subnet.private_subnet1.id
}
output "subnetPublic" {
  value = aws_subnet.public_subnet1.id
}
output "vpcId" {
  value = aws_vpc.vpc.id
}