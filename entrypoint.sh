#!/bin/bash
set -e

# set timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/$LOCALTIME /etc/localtime

# make sure we are running the latest version of jotta-cli
apt-get update
apt-get install jotta-cli
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/lists/*

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

# Exit on error no longer needed. Also, it would prevent detecting jotta-cli status
set +e

# Checking if jotta runs correctly
jotta-cli status >/dev/null 2>&1
R=$?

if [ $R -ne 0 ]; then
  echo "Could not start jotta. Checking why."

  # Assuming we are not logged in
  if [[ "$(jotta-cli status 2>&1)" =~ "Not logged in" ]]; then
    echo "First time login. Logging in."

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
    echo "ERROR: Not able to determine why Jotta cannot start:"
    jotta-cli status
    exit 1
  fi

else
  echo "Jotta started."

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

R=0
while [[ $R -eq 0 ]]
do
	sleep 15
	jotta-cli status >/dev/null 2>&1
        R=$?
done

echo "Exiting:"
jotta-cli status
exit 1
