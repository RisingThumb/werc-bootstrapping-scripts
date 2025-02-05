# Werc Bootstrapping Scripts

## What?

Provided are 2 seperate scripts for bootstrapping werc on a Debian 12 machine. They may also work on Debian 11. This should make poking around and trying Werc an easy and painless experience

### bootstrapScript.sh

This script handles installing and preparing dependencies. Mostly apache2, certbot, cronjob stuff for renewals etc. It should just be a case of running this shell script. It will also add a daily cronjob for doing certbot renewals

### addSite.sh

This script takes 4 positional parameters ordered as follows: Domain Name, Webmaster email, Username for use on the site and a password for use on the site.
This assumes there is a tst.cat-v.org folder in the sites/ directory, as we use that as the base folder for newly added sites. This folder contains demos of some of the apps
This will additionally get an SSL certificate for the site and set up and enable apache2 site configs.
