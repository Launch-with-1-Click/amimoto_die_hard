#!/usr/bin/env bash

# should fail when yum update crashed.
set -e

## Wait Amimot setup
I_ID=`/opt/aws/bin/ec2-metadata | grep instance-id | awk '{print $2}'`

while :
do
echo -n "."
sleep 5
  if [ -f /var/www/vhosts/${I_ID}/wp-config.php ] ; then
    echo
    break
  fi
  # for autoscale version
  if [ -f /var/www/html/wp-config.php ] ; then
    echo
    break
  fi
done

# check nginx is healty?
timeout 300 bash -c 'while ! curl -sf 127.0.0.1:80 ; do sleep 1 ; done'

## Note: WorkAround for Aug 2015.
# sudo yum -y erase php55-cli php55-opcache php55-xml  php55-process php55-common
sudo yum -y update

for x in nginx hhvm php-fpm ; do
  if service $x status ; then
    service $x stop
    sleep 1
    service $x start
  fi
done

sleep 3

MPHP=`cat /opt/local/amimoto.json | jq .mod_php7.enabled`
if [ "$MPHP" == "true" ] ; then
  set -x
  echo 'waitting for httpd 5mins...'
  timeout 300 bash -c 'while ! curl -sf 127.0.0.1:8080 ; do sleep 1 ; done'
fi
