output "name" {
    description = "The name of the IAM Instance Profile"
    value = aws_iam_instance_profile.ec2-profile.name  
}