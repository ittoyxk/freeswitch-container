FROM debian:11
MAINTAINER xiaokang

RUN SIGNALWIRE_ACCESS_TOKEN=pat_MUdNwXaLqtUSzvK7fa86vD5s  && apt-get update -qq     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends                ca-certificates                curl                gnupg2                lsb-release                wget     && wget --http-user=signalwire --http-password=$SIGNALWIRE_ACCESS_TOKEN        -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg        https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg     && echo "machine freeswitch.signalwire.com login signalwire password $SIGNALWIRE_ACCESS_TOKEN" > /etc/apt/auth.conf     && echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list     && echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list     && apt-get update -qq     && DEBIAN_FRONTEND=noninteractive apt-get install -y                freeswitch-meta-all                freeswitch-mod-format-cdr                opus-tools                vorbis-tools                xmlstarlet     && apt-get clean autoclean     && apt-get autoremove --yes
# Cleanup the image
RUN apt-get clean


COPY docker-entrypoint.sh healthcheck.sh /
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  /healthcheck.sh

ENTRYPOINT ["/docker-entrypoint.sh"]