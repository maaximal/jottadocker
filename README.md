# jottadocker
In order to persist the config add /var/lib/jottad as a mount or volume.

Add paths to backup as mounts under /backup/...
Each subfolder there is added as a backup path in jotta-cli

Login using env variables:
- JOTTA_TOKEN: Your JottaCloud personal login token
- JOTTA_DEVICE: The Device name for the JottaCloud backups 
- JOTTA_SCANINTERVAL: The scaninterval for the JottaCloud backups
- LOCALTIME: The [timezone file](https://packages.debian.org/sid/all/tzdata/filelist) in the docker image (e.g. Europe/Berlin)

To add a [ignore file](https://docs.jottacloud.com/en/articles/1437235-ignoring-files-and-folders-from-backup-with-jottacloud-cli) mount it to /config/ignorefile
