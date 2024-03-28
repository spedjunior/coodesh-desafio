output "subnetId1" {
  value = aws_subnet.private_subnet1.id
}
output "subnetId2" {
  value = aws_subnet.private_subnet2.id
}
output "vpcId" {
  value = aws_vpc.vpc.id
}