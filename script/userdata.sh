#!/bin/bash
sudo yum update -y
sudo yum -y install git
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "hello world from $(hostname -f)"> /var/www/html/index.html|i

