#!/bin/bash
# dont forget to set all of these and make the passwords long
WPDBNAME="poo"
WPDBUSERNAME="poo"
WPDBUSERPW="!1newmedia"
DOMAINNAME="cooldomain.com"
WWWDOMAINNAME="www.cooldomain.com"
echo "Your worpdress databasename is: $WPDBNAME"

# install auto-upgrades for ubuntu so you dont need to worry about it
sudo apt-get update -y
sudo apt-get install unattended-upgrades -y
sudo dpkg-reconfigure unattended-upgrades

# add new user

# install nginx & lock it down
sudo apt-get install nginx nginx-extras -y
# turn server tokens off for nginx (shuts off header info)
sudo sed -i "21i server_tokens off;" /etc/nginx/nginx.conf
# set headers to a fake Server name to mess with people trying to scan for exploits
sudo sed -i "22i more_set_headers 'Server: FUCK_OFF_KIDDIES';" /etc/nginx/nginx.conf
#sudo echo "server_tokens off;" >> /etc/nginx/nginx.conf
#sudo echo "more_set_headers 'Server: FUCK_OFF_KIDDIES';" >> /etc/nginx/nginx.conf
sudo nginx -s reload

# install mysql and lock it down
sudo apt-get install mysql-server
# dont forget your root password for mysql
sudo mysql_install_db
sudo mysql_secure_installation

echo $(mysql -uroot -e 'create database $WPDBNAME;' -p)
echo $(mysql -uroot -e "create user `$WPDBUSERNAME`@`localhost` IDENTIFIED BY '$WPDBUSERPW';")
echo $(mysql -uroot -e "grant all privileges on `$WPDBNAME`.* to `$WPDBUSERNAME`@`localhost`;FLUSH PRIVILEGES;")

# get wordpress setup
cd ~
mkdir projects && cd projects
wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz # creates directory called wordpress with all necessary files
sudo apt-get install php5-gd libssh2-php -y

# clone this repo
sudo apt-get install git -y
git clone https://github.com/the-pharos-group/secure-wordpress.git

# move the custom wordpress config to the previously downloaded and tarred wordpress folder
cp secure-wordpress/wp-config.php wordpress/

# mod the config file with the updated settings
cd wordpress
sed -i "20i define( 'DB_NAME',     '$WPDBNAME' );" wp-config.php
sed -i "21i define( 'DB_USER',     '$WPDBUSERNAME' );" wp-config.php
sed -i "22i define( 'DB_PASSWORD',     '$WPDBUSERPW' );" wp-config.php
sed -i "23i define( 'DB_NAME',     '$WPDBNAME' );" wp-config.php

# mod the nginx default from the repo with updated variables from above and move into place
cd ~/projects/secure-wordpress
sed -i "3i server_name $DOMAINNAME;" default
sed -i "4i 301 redirect http://$WWWDOMAINNAME\$request_uri;" default
sed -i "12i server_name $WWWDOMAINNAME;"
sudo cp default /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

#restart nginx to make sure everything is working
sudo service nginx restart
sudo service php5-fpm restart

# move wordpress code to proper place for nginx default virtual web server path
sudo mkdir -p /var/www/html
sudo rsync -avP ~/projects/wordpress/ /var/www/html/
cd /var/www/html/
sudo chown -R $USER:www-data /var/www/html/*
mkdir wp-content/uploads
echo $(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')

echo "ALL DONE! GO TO THE IP ADDRESS OF THIS SERVER LISTED ABOVE IN BROWSER AND FINISH INSTALL"
echo "DONT FORGET TO RUN THE SERVER LOCKDOWN SCRIPT AS WELL TO REALLY SECURE THIS BOX"
echo "ALSO DONT FORGET TO UPDATE DNS ZONE FILE WITH A RECORDS"
