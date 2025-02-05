#!/bin/sh

# Preparing dependencies
## We start out making sure Debian is up to date and upgraded
apt-get update;
apt-get upgrade;


## Get apache2, certbot for https and 9base for werc iptables-persistent to open port 80
apt-get --assume-yes install apache2 libapache2-mod-fcgid git certbot 9base iptables-persistent dos2unix

## As port 80 must be open for certbot challenges, we open it up. We do also allow http requests, but these are redirected to https(port 443)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

## Enable apache2 modules. Some of these are enabled by default, some are not
a2enmod rewrite
a2enmod ssl cgi cgid fcgid dir include deflate


## Set up cronjob for automatic certbot renewals. We need to turn off apache2 during renewals as certbot uses port 80 for its cert challenges
cat >/etc/cron.daily/daily_certbot_renewal.sh << EOF
#!/bin/sh
systemctl stop apache2.service
certbot renew
systemctl start apache2.service
EOF
chmod +x /etc/cron.daily/daily_certbot_renewal.sh


# Preparing werc
## Install werc.
## NOTE! This may be a section that needs changing if Werc updates or you wish to use a different base installation or fork of werc. Change as you see fit

cd /var/www/
git clone "https://github.com/RisingThumb/werc.git"


## Install any additional werc apps
### Make everything owned by www-data. If this isn't done, we might run into permission issues
chown -R www-data /var/www/werc

echo "Werc successfully installed!\nYou will find it located in /var/www/werc\nFurther steps you may need to do...\n  1. In your Domain Registrar create an A/AAAA record that points $DOMAIN_NAME to the right IP Address\nHappy wercing!"
