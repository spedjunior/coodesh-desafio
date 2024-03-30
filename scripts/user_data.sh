#!/bin/bash

#Install AWS CLI
apt-get update
apt  install -y awscli 

#Download Site Content
 aws s3 cp s3://site-coodesh/index.html /var/www/html/index.html

# Install Nginx
 apt-get install -y nginx
 systemctl enable nginx && systemctl start nginx

# Install AWS CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
echo '{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "coodesh_log"
                    },
                    {
                        "file_path": "/var/log/auth.log",
                        "log_group_name": "coodesh_log"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "coodesh_log"
                    },
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "coodesh_log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "append_dimensions": {
            "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
            "ImageId": "$${aws:ImageId}",
            "InstanceId": "$${aws:InstanceId}",
            "InstanceType": "$${aws:InstanceType}"
        },
        "metrics_collected": {
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}' > /opt/aws/amazon-cloudwatch-agent/bin/config.json

# Start the CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
systemctl start amazon-cloudwatch-agent.service


