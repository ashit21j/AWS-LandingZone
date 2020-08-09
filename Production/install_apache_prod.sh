#! /bin/bash
sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo <h1>Deployed via Terraform on Production</h1> > /var/www/html/index.html
