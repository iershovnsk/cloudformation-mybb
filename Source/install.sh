#!/bin/bash -x

#
# MyBB AMI installation script invoked by AWS CloudFormation template.
# (C) Valeriu Paloş <valeriupalos@gmail.com>
# (C) Ivan Ershov <iershov.nsk@gmail.com>
# Apache2, Php5x and required dependencies for MyBB are expected to be
# properly added to the system by this point.
#

# Environment variables (expected).
echo $MYBB_ADMINEMAIL
echo $MYBB_DOMAINNAME
echo $MYBB_DBNAME
echo $MYBB_DBUSERNAME
echo $MYBB_DBPASSWORD
echo $MYBB_DBHOSTNAME
echo $MYBB_DBPORT
echo $MYBB_FILESYSTEM
echo $MYBB_REGION

# Configuration.
CONFIG="./mybb-config"
SOURCE="./mybb-source"
TARGET="/var/www/html"

# Clean-up and copy files.
rm -rf "$TARGET"/*
cp -r "$SOURCE"/* "$TARGET"/

# Prepare and copy dynamic configuration files.
sed -e "s/MYBB_ADMINEMAIL/${MYBB_ADMINEMAIL}/g" \
    -e "s/MYBB_DOMAINNAME/${MYBB_DOMAINNAME}/g" \
    "${CONFIG}/settings.php" > "${TARGET}/inc/settings.php"

sed -e "s/MYBB_DBNAME/${MYBB_DBNAME}/g" \
    -e "s/MYBB_DBUSERNAME/${MYBB_DBUSERNAME}/g" \
    -e "s/MYBB_DBPASSWORD/${MYBB_DBPASSWORD}/g" \
    -e "s/MYBB_DBHOSTNAME/${MYBB_DBHOSTNAME}/g" \
    -e "s/MYBB_DBPORT/${MYBB_DBPORT}/g" \
    "${CONFIG}/config.php" > "${TARGET}/inc/config.php"

# Initialize database if it is empty.

tables=`mysql --user=${MYBB_DBUSERNAME} \
        --password=${MYBB_DBPASSWORD} \
        --host=${MYBB_DBHOSTNAME} \
        --port=${MYBB_DBPORT} \
        -s --skip-column-names -e "SELECT COUNT(DISTINCT table_name) FROM information_schema.columns WHERE table_schema = '${MYBB_DBNAME}'"`

if [[ $tables -eq 0 ]]; then
  sed -e "s/MYBB_ADMINEMAIL/${MYBB_ADMINEMAIL}/g" \
    -e "s/MYBB_DOMAINNAME/${MYBB_DOMAINNAME}/g" \
    "${CONFIG}/mybb.sql" | mysql \
    --user="$MYBB_DBUSERNAME" \
    --password="$MYBB_DBPASSWORD" \
    --host="$MYBB_DBHOSTNAME" \
    --port="$MYBB_DBPORT" \
    --database="$MYBB_DBNAME" || echo "WE ASSUME DATA ALREADY EXISTS!"
else
  echo "$MYBB_DBNAME is not empty, skipping initialization..."
fi


# Set proper ownership and permissions.
cd "$TARGET"
chmod 666 inc/config.php inc/settings.php
chmod 666 inc/languages/english/*.php inc/languages/english/admin/*.php

mkdir -p ${TARGET}/uploads
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${MYBB_FILESYSTEM}.efs.${MYBB_REGION}.amazonaws.com:/ ${TARGET}/uploads
mkdir -p uploads/avatars
chown -R apache:apache ${TARGET}/
chmod 777 cache/ cache/themes/ admin/backups/
chmod 777 uploads/ uploads/avatars/
