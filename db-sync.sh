#!/bin/bash

LOCALDOMAIN='http://localdomain.dev'
REMOTEDOMAIN='https://remotedomain.com'

SSH_SERVER='remotedomain.com'
SSH_USER='user'
SSH_PORT='2'
SSH_ADDITIONAL='' # additional parameters for SSH, for example SSH key
SCP_ADDITIONAL='' # additional parameters for SCP, for example SSH key
REMOTE_WP_DIR='/var/www' #fill in the full path to WordPress instalatio directory on remote host

TMPDBNAME='db-dump-tmp.sql'

WPDBNAME=`cat wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`
WPDBHOST=`cat wp-config.php | grep DB_HOST | cut -d \' -f 4`


mysqldump -u $WPDBUSER -p$WPDBPASS -h $WPDBHOST $WPDBNAME > ./$TMPDBNAME

sed -i -e "s|$LOCALDOMAIN|$REMOTEDOMAIN|g" ./$TMPDBNAME

scp $SCP_ADDITIONAL -P $SSH_PORT ./$TMPDBNAME $SSH_USER@$SSH_SERVER:$REMOTE_WP_DIR/$TMPDBNAME 

ssh $SSH_ADDITIONAL -p $SSH_PORT $SSH_USER@$SSH_SERVER REMOTE_WP_DIR=$REMOTE_WP_DIR TMPDBNAME=$TMPDBNAME 'bash -s'<<'ENDSSH'
#commands to run on remote host
#get parameters from remote wp-config.php
WPDBNAME_REMOTE=`cat $REMOTE_WP_DIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER_REMOTE=`cat $REMOTE_WP_DIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS_REMOTE=`cat $REMOTE_WP_DIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`
WPDBHOST_REMOTE=`cat $REMOTE_WP_DIR/wp-config.php | grep DB_HOST | cut -d \' -f 4`
#update DB
mysql -u $WPDBUSER_REMOTE -p$WPDBPASS_REMOTE -h $WPDBHOST_REMOTE $WPDBNAME_REMOTE < $REMOTE_WP_DIR/$TMPDBNAME
#remove temporary file
rm $REMOTE_WP_DIR/$TMPDBNAME
ENDSSH

#back to local host
rm ./$TMPDBNAME