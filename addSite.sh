#!/bin/bash

if [[ $# -lt 4 ]] ; then
echo "
This script requires 4 positional parameters.
  - The domain name
  - The email address for the webmaster/server admin
  - The site username
  - The site user password
NOTE: There must not be any spaces in these parameters.

For example:
./addSite.sh risingthumb.xyz risingthumb@risingthumb.xyz risingthumb risingthumb_password
"
    exit;
fi

DOMAIN_NAME=$1
WEBMASTER_EMAIL=$2
SITE_USERNAME=$3
SITE_PASSWORD=$4

# Add a site

## Prepare the werc-side of the site
cd /var/www/werc/sites
# git clone werc site template
cp -r tst.cat-v.org $DOMAIN_NAME

## Set up LetsEncrypt cert

systemctl stop apache2.service
certbot certonly --standalone -d $DOMAIN_NAME
systemctl start apache2.service



### This is the Apache2 config for handling HTTP requests. We redirect to the HTTPS site
cat >/etc/apache2/sites-available/$1.conf <<EOF
<VirtualHost *:80>
	ServerName $DOMAIN_NAME
	ServerAdmin $WEBMASTER_EMAIL
RewriteEngine on
RewriteCond %{SERVER_NAME} =$DOMAIN_NAME
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOF

### This is the Apache2 config for handling HTTPS requests. This does CGI, and sets up deflate compression for a handful of various mimetypes
cat >/etc/apache2/sites-available/$1-le-ssl.conf <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerName $DOMAIN_NAME
	ServerAdmin $WEBMASTER_EMAIL
RewriteEngine on


AddHandler cgi-script .rc
AddHandler cgi-script .cgi


AddOutputFilterByType DEFLATE text/plain
AddOutputFilterByType DEFLATE text/html
AddOutputFilterByType DEFLATE text/xml
AddOutputFilterByType DEFLATE text/css
AddOutputFilterByType DEFLATE application/xml
AddOutputFilterByType DEFLATE application/xhtml+xml
AddOutputFilterByType DEFLATE application/rss+xml
AddOutputFilterByType DEFLATE application/javascript
AddOutputFilterByType DEFLATE application/x-javascript

# Or, compress certain file types by extension:
<files *.html>
SetOutputFilter DEFLATE
</files>

<files *.wasm>
SetOutputFilter DEFLATE
</files>

<files *.pck>
SetOutputFilter DEFLATE
</files>

<Directory /var/www/werc/bin>
	Options ExecCGI
	AllowOverride None
	Order allow,deny
	Allow from all
</Directory>

<IfModule mod_dir.c>
	DirectoryIndex /werc.rc
</IfModule>

RewriteRule (.*) /var/www/werc/sites/%{HTTPS_HOST}/\$1

RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule .* /var/www/werc/bin/werc.rc

RewriteRule /werc.rc /var/www/werc/bin/werc.rc
DocumentRoot "/var/www/werc/bin/"
ErrorDocument 404 /werc.rc

SSLEngine on

# Intermediate configuration, tweak to your needs
SSLProtocol             all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLOptions +StrictRequire

# Add vhost name to log entries:
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" vhost_combined
LogFormat "%v %h %l %u %t \"%r\" %>s %b" vhost_common

SSLCertificateFile /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem
</VirtualHost>
</IfModule>
EOF



## Chown the site so that it has the correct permissions
chown -R www-data /var/www/werc/sites/$DOMAIN_NAME



## Add a root user for this new Domain Name
cd /var/www/werc/etc/users/
mkdir $SITE_USERNAME
echo $SITE_PASSWORD > $SITE_USERNAME/password

cat > /var/www/werc/sites/$DOMAIN_NAME/_werc/ <<EOF
siteTitle=$DOMAIN_NAME
conf_enable_wiki $SITE_USERNAME
EOF

cat > /var/www/werc/sites/$DOMAIN_NAME/apps/goralog/_werc/ <<EOF
conf_enable_goralog
conf_blog_editors=$SITE_USERNAME
conf_blog_title=$DOMAIN_NAME
EOF


## Enable the sites configs and reload apache2
a2ensite $DOMAIN_NAME
a2ensite $DOMAIN_NAME-le-ssl
systemctl reload apache2.service

echo "Added $DOMAIN_NAME! Look under /var/www/werc/sites/$DOMAIN_NAME for the files! Suggested next steps...
  - Play around with werc in your browser! Log in as your created user and try out the different apps!
  - Change your config settings under /var/www/werc/sites/$DOMAIN_NAME/_werc/config!

Happy wercing!
"
