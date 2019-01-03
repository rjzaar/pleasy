#!/bin/bash

#this script will overwrite the production site with qa. All data on production will be lost.
# this is good for a first setup of production.
Name=$(date +"%Y-%m-%d")
#move what's there
Bname="OC-"$(date +"%Y-%m-%d")".sql"
echo backup external database externally
ssh cathnet "cd opencat.org/opencourse/docroot/ && drush sql-dump > ../../../ocbackup/$Bname"
echo cp settings.local.php to backup
ssh cathnet "cd opencat.org/opencourse/docroot/sites/default/ && cp settings.local.php ~/ocbackup/settings.local.php"
echo move external files to backup name
ssh cathnet mv opencat.org opencat.$Name

#git clone
echo git clone opencat
ssh cathnet eval `ssh-agent -s`
ssh cathnet ssh-add ~/.ssh/github
ssh cathnet git clone git@github.com:rjzaar/opencat.git
echo composer install
ssh cathnet "cd opencat/opencourse && composer install --no-dev"
echo copy settings.local.php to new server
ssh cathnet cp ocbackup/settings.local.php opencat/opencourse/docroot/sites/default/settings.local.php
echo copy localdb to external
cd
cd opencat/opencourse/docroot
drush sql-dump > ~/ocbackup/localdb/OC-$(date +"%Y-%m-%d").sql
scp ocbackup/localdb/OC-$(date +"%Y-%m-%d").sql cathnet:ocbackup/localdb/OC-$(date +"%Y-%m-%d").sql
echo fix file permissions, requires sudo on external server
ssh cathnet -t "sudo bash ./fix-p.sh --drupal_user=puregift --drupal_path=opencat/opencourse/docroot"
echo "The restoring the database requires sudo on the external server."
ssh cathnet -t "sudo ./restoredb.sh"
echo "clearing cache"
ssh cathnet "cd opencat/opencourse/docroot && drush cr"
echo "renaming folder to opencat.org to make it live"
ssh cathnet mv opencat opencat.org





