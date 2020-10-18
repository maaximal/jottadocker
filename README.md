# jottadocker
In order to persist the config add /var/lib/jottad as a mount or volume.

Login by opening a shell into the container

`docker exec -it jottadocker /bin/bash`

and log in using `jotta-cli login`
