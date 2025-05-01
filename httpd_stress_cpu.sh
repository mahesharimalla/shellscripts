#!bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
amazon-linux-extras install epel -y
yum install stress -y
stress --cpu 1 --timeout 300
echo "<h1>This is my test custom webpage</h1>" > /var/www/html/index.html

