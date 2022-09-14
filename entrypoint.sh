#!/bin/bash
set -e

# set timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/$LOCALTIME /etc/localtime

# set up config volume
mkdir -p /config/jottad
ln -sfn /config/jottad /root/.jottad

# start the service
export JOTTAD_SYSTEMD=0
/usr/bin/run_jottad &

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
    expect {
    	\"Devicename*: \" {
		send \"$JOTTA_DEVICE\n\"
		exp_continue
	}
	\"Do you want to re-use this device? (yes/no):\" {
		send \"yes\n\"
		exp_continue
	}
    }
    expect eof
    "
    R=$?
    if [ $R -ne 0 ]; then
    	echo "Login failed"
    	exit 1
    fi
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
