FROM debian:bullseye
MAINTAINER xiaokang

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone -b v1.10.11 --depth=1 https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
# build
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config \
# general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
# core
    libpcre3-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
# core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
# mod_enum
    libldns-dev \
# mod_python3
    python3-dev \
# mod_av
    libavformat-dev libswscale-dev libavresample-dev \
# mod_lua
    liblua5.2-dev \
# mod_opus
    libopus-dev \
# mod_pgsql
    libpq-dev \
# mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
# mod_shout
    libshout3-dev libmpg123-dev libmp3lame-dev

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/spandsp && git checkout 0d2e6ac && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Enable modules
RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_abstraction|applications/mod_abstraction|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_curl|applications/mod_curl|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_directory|applications/mod_directory|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_distributor|applications/mod_distributor|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_easyroute|applications/mod_easyroute|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_http_cache|applications/mod_http_cache|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_ladspa|applications/mod_ladspa|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_mp4|applications/mod_mp4|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_mp4v2|applications/mod_mp4v2|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#endpoints/mod_rtmp|endpoints/mod_rtmp|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#formats/mod_imagick|formats/mod_imagick|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#xml_int/mod_xml_curl|xml_int/mod_xml_curl|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#event_handlers/mod_format_cdr|event_handlers/mod_format_cdr|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#event_handlers/mod_json_cdr|event_handlers/mod_json_cdr|' /usr/src/freeswitch/build/modules.conf.in

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && ./configure
RUN cd /usr/src/freeswitch && make -j`nproc` && make install

# Cleanup the image
RUN apt-get clean

# Uncomment to cleanup even more
RUN rm -rf /usr/src/*

RUN ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch && ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli

COPY docker-entrypoint.sh healthcheck.sh /
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  /healthcheck.sh

RUN chmod +x /healthcheck.sh && chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]