#!/bin/bash
set -e

# set timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/$LOCALTIME /etc/localtime

# make sure we are running the latest version of jotta-cli
apt-get install jotta-cli

# set the jottad user and group id
usermod -u $PUID jottad
usermod --gid $PGID jottad
usermod -a -G jottad jottad

sed -i 's+user="jottad"+user="'$JOTTAD_USER'"+g' /etc/init.d/jottad
sed -i 's+user="jottad"+group="'$JOTTAD_GROUP'"+g' /etc/init.d/jottad

chown jottad /var/lib/jottad -R

# start the service
/etc/init.d/jottad start

# wait for service to fully start
sleep 5

if [[ "$(jotta-cli status)" =~ ERROR.* ]]; then

  echo "First time login"

  # Login user
  /usr/bin/expect -c "
  set timeout 20
  spawn jotta-cli login
  expect \"accept license (yes/no): \" {send \"yes\n\"}
  expect \"Personal login token: \" {send \"$JOTTA_TOKEN\n\"}
  expect \"Devicename*: \" {send \"$JOTTA_DEVICE\n\"}
  expect eof
  "

else
  echo "User is logged in"

fi

echo "Adding backups"

for dir in /backup/* ; do if [ -d "${dir}" ]; then set +e && jotta-cli add /$dir && set -e; fi; done

# load ignore file
if [ -f /config/ignorefile ]; then
  echo "loading ignore file"
  jotta-cli ignores set /config/ignorefile
fi

# set scan interval
echo "Setting scan interval"
jotta-cli config set scaninterval $JOTTA_SCANINTERVAL

jotta-cli tail &

cliout="OK"
while [[ $cliout == "OK" ]]
do
	sleep 15
	cliout=$(jotta-cli status | tail -1)
done
exit 1
