# coming soon the entire bash script to do it all run as sudo ./just_wordpress_secure_me.sh
#!/bin/bash
# dont forget to set all of these and make the passwords long
WPDBNAME="your wordpress database name"
WPDBUSERNAME="your wordpress database username"
WPDBUSERPW="your wordpress database user password"
echo "Your worpdress databasename is: $WPDBNAME"

# install auto-upgrades for ubuntu so you dont need to worry about it
sudo apt-get update -y
sudo apt-get install unattended-upgrades -y
sudo dpkg-reconfigure unattended-upgrades

# install nginx & lock it down
sudo apt-get install nginx nginx-extras -y
sed -i "21i server_tokens off;" /etc/nginx/nginx.conf
sed -i "22i more_set_headers 'Server: FUCK_OFF_KIDDIES';" /etc/nginx/nginx.conf
#sudo echo "server_tokens off;" >> /etc/nginx/nginx.conf
#sudo echo "more_set_headers 'Server: FUCK_OFF_KIDDIES';" >> /etc/nginx/nginx.conf
sudo nginx -s reload

# install mysql and lock it down
sudo apt-get install mysql-server
sudo mysql_install_db
sudo mysql_secure_installation
