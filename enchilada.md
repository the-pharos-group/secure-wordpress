_This guide is meant to be a signpost to guide the way, not a dictionary to memorize. Your mileage may vary._
_Two great sites to check speed and security: http://tools.pingdom.com/fpt/ & https://securityheaders.io_

_This is provided totally without gaurantee or warrenty. Buyer beware._

## Initial setup

### GET DIGITAL OCEAN
Buy a new [Digital Ocean](http://www.digitalocean.com) droplet with Wordpress pre-installed ($10 per month) or install Wordpress from scratch on a basic Ubuntu 14.04 VPS (skip if pre-installed):
```
sudo apt-get update
sudo apt-get install nginx
sudo apt-get install mysql-server
sudo mysql_install_db
sudo mysql_secure_installation
sudo apt-get install php5-fpm php5-mysql
sudo nano /etc/php5/fpm/php.ini
cgi.fix_pathinfo=0 # uncomment and add 0
sudo service php5-fpm restart

# change default nginx web config
sudo nano /etc/nginx/sites-available/default
# copy and paste this in to replace the entire file
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    server_name server_domain_name_or_IP;

    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
# CTRL + X to save and exit nano
sudo service nginx restart

# setup mysql
mysql -u root -p
CREATE DATABASE supersecurewp;
CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost;
FLUSH PRIVILEGES;
exit

# download wordpress
cd ~
mkdir projects && cd projects
wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz # creates directory called wordpress with all necessary files
sudo apt-get update
sudo apt-get install php5-gd libssh2-php

# config wordpress
cd wordpress
cp wp-config-sample.php wp-config.php
nano wp-config.php
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpressuser');

/** MySQL database password */
define('DB_PASSWORD', 'password');

# press CTRL + X to save and exit nano
sudo mkdir -p /var/www/html
sudo rsync -avP ~/projects/wordpress/ /var/www/html/
cd /var/www/html/
sudo chown -R supersecureuser:www-data /var/www/html/*
mkdir wp-content/uploads
sudo chown -R :www-data /var/www/html/wp-content/uploads
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/wordpress

# edit wordpress file to be the following:
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        root /var/www/html;
        index index.php index.html index.htm;

        server_name your_domain.com;

        location / {
                # try_files $uri $uri/ =404;
                try_files $uri $uri/ /index.php?q=$uri&$args;
        }

        error_page 404 /404.html;

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
                root /usr/share/nginx/html;
        }

        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
        }
}

sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo service nginx restart
sudo service php5-fpm restart
# now go to the url and you should be greeted with the wordpress five-minute install screen
```

## CREATE USERS AND LOCK DOWN SSH
ssh into the new instance based on the credentials Digital Ocean provided.

`ssh root@[new ip address]`

Add a new user.

` adduser supersecureuser `

Follow the prompts to set a new strong password.

Edit visudo and add the new user with all the rights as root just below the root (ALL:ALL) line:

` supersecureuser ALL=(ALL:ALL) ALL `

Edit the sshd_config file and change the default port 22 and PermitRootLogin no:

```
nano /etc/ssh/sshd_config 
port 1900 
PermitRootLogin no 
AllowUsers supersecureuser
CTRL + X and then y to save and exit
service ssh restart 
```

## LOCK DOWN UBUNTU
Install ufw and [fail2ban](http://fail2ban.org).
```
apt-get install ufw fail2ban vim -y
cp /etc/fail2ban/jail.{conf,local}
sudo vim /etc/fail2ban/filter.d/sshd.conf
# add this right below the other regex lines: ^%(__prefix_line)sReceived disconnect from <HOST>: 11: Bye Bye \[preauth\]\s*$
# exit vim by typing :wq and hitting enter
sudo service fail2ban restart
```

Install _unattended-upgrades_ to keep your server up-to-date with having to login all of the time.
```
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```



## LOCK DOWN APACHE AND PHP (for NGINX, see below this section)
Edit the apache.conf file and add the following lines:

```
nano /etc/apache2/apache2.conf
ServerTokens ProductOnly
ServerSignature Off
TraceEnable off
Header set X-Frame-Options SAMEORIGIN
Header set X-XSS-Protection 1;mode=block
Header set X-Content-Type-Options nosniff

or

echo "ServerTokens ProductOnly" >> /etc/apache2/apache2.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
echo "TraceEnable off" >> /etc/apache2/apache2.conf

a2enmod headers
sudo service apache2 restart
```
Edit the php.ini file to stop publishing that it even exists by switching expose_php from On to Off:

```
nano /etc/php5/apache2/php.ini
expose_php = Off # use CTRL + W and search for expose to get to this line quickly
service apache2 restart # restart your instance now that php and apache2 are both locked down correctly
```

## LOCK DOWN NGINX!
Install nginx-extras to make the donuts.
```
sudo apt-get install nginx-extras -y
```
Edit nginx.conf in the html section, you will find #server_tokens:
```
sudo nano /etc/nginx/nginx.conf
server_tokens off;
more_set_headers 'Server: FUCK_YOU_SCRIPT_KIDDIE';
sudo service nginx restart
```

In the server section of either your custom vhost or your default vhost file in sites-available, add the following headers:
```
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security max-age=7776000;
add_header Content-Security-Policy "default-src 'self'; 
script-src 'self' 'unsafe-eval' https://ssl.google-analytics.com https://ajax.cloudflare.com; 
img-src 'self' https://ssl.google-analytics.com ; 
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; 
font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; 
object-src 'none'";
```

make sure to restart nginx:
```
sudo nginx -s reload
```

Log into another terminal session as the new user you created to check to make sure it is working.

```
ssh wpuser@[new ip address] -p 1900
```
If that works, then you are good to go to close your root session and never log into root again.

Congratulations! You now can visit the ip address in your web browser and go through the wordpress installation knowing that you locked down your server properly.

## POST WORDPRESS INSTALL

###Recommended Plug-ins and post-Wordpress install

[ithemes security](https://wordpress.org/plugins/better-wp-security/) - set the /wp-login.php to be a different made up path and block xml-rpc attack vectors   
[wordfence security](https://wordpress.org/plugins/wordfence/) - auto-ban fake crawlers, pingers, attackers - don't forget to whitelist your ip address   
[math captcha](https://wordpress.org/plugins/wp-math-captcha/) - add to login page   
[wp slimstat](https://wordpress.org/plugins/wp-slimstat/) - track visitors      
[media vault](https://wordpress.org/plugins/media-vault/) - lock down attachments of all types   
[download manager](https://wordpress.org/plugins/download-manager/) - track downloads    
[disable comments](https://wordpress.org/plugins/disable-comments/) - completely disable comments   
[WP Plugins&Themes Auto Update](https://wordpress.org/plugins/wp-pluginsthemes-auto-update/) - keep everything up to date auto-magically  
