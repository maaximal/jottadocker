FROM debian:10.6-slim

ENV JOTTA_TOKEN=**None** \
    JOTTA_DEVICE=**None** \
    JOTTA_SCANINTERVAL=1h\
    PUID=101 \
    PGID=101 \
    LOCALTIME=Europe/Amsterdam

COPY entrypoint.sh /src/
WORKDIR /src
RUN chmod +x entrypoint.sh

RUN apt-get update -y &&\
	apt-get upgrade -y &&\
	apt-get -y install wget gnupg apt-transport-https ca-certificates expect &&\
	wget -O - https://repo.jotta.us/public.gpg | apt-key add - &&\
	echo "deb https://repo.jotta.us/debian debian main" | tee /etc/apt/sources.list.d/jotta-cli.list &&\
	apt-get update -y &&\
	apt-get install jotta-cli -y &&\
	apt-get autoremove -y &&\
	apt-get clean &&\
	rm -rf /var/lib/lists/*

EXPORT 14443

ENTRYPOINT [ "/src/entrypoint.sh" ]
