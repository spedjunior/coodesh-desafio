terraform { 
  cloud {
    organization = "spedjunior" 
    workspaces { name = "coodesh-challenge" } 
    }
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">= 5.42.0"
      }
      null = {
        source  = "hashicorp/null"
        version = ">= 3.2.2"
      }
      template = {
        source  = "hashicorp/template"
        version = ">= 2.2.0"
      }
    }
    required_version = ">= 1.7.5"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      "IaC" = "terraform"
      "project" = "coodesh"
      "env" = "dev"
      "owners" = "coodesh"
      "costcenter" = "sre"
    }
  }
}

module "s3" {
    source = "./modules/s3"
    bucket_name = "site-coodesh"
}

module "aws_iam_instance_profile" {
    source = "./modules/iam"
  
}
module "network" {
    source = "./modules/network"
}

module "security_group" {
    source = "./modules/security_group"
    vpc_id = module.network.vpcId
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-mantic-23.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}

data "template_file" "user_data" {
  template = file("./scripts/user_data.sh")
}

resource "aws_cloudwatch_log_group" "coodesh_log" {
  name = "coodesh_log"
}

resource "aws_launch_template" "lt_coodesh" {
  name_prefix   = "lt-coodesh"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  iam_instance_profile {
    name = module.aws_iam_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups = [module.security_group.ec2Id]
  }
  
  block_device_mappings {
    device_name =  "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      delete_on_termination = true
    }
  }
  user_data = base64encode(data.template_file.user_data.rendered)
  key_name = "my-key"
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "coodesh-instance",
      Iac = "terraform",
      project = "coodesh",
      env = "dev",
      owners = "coodesh",
    }

  
  }
  
}

resource "aws_autoscaling_group" "asg" {
  name             = "asg-coodesh"
  launch_template {
    id      = aws_launch_template.lt_coodesh.id
    version = "$Latest"
  }
  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [module.network.subnetId1]
  health_check_type = "EC2"
  termination_policies = ["OldestInstance"]
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "asg-cpu-scaling"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}

resource "aws_lb" "lb" {
  name               = "lb-coodesh"
  internal           = false
  load_balancer_type = "application"
  subnets            = [module.network.subnetId1, module.network.subnetId2]
  security_groups = [module.security_group.lbId]
}


resource "aws_lb_target_group" "tg" {
  name     = "tg-coodesh"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpcId
  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 10
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn = aws_lb_target_group.tg.arn
}


output "load_balancer_dns" {
  value = aws_lb.lb.dns_name
}

output "bucket" {
  value = module.s3.id
}