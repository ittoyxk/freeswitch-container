FROM debian:trixie
MAINTAINER xiaokang

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone -b v1.11.3 --depth=1 https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c
RUN git clone --depth=1 --branch v1.6.51 https://github.com/pnggroup/libpng.git /usr/src/libs/libpng

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
# build
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config \
# general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff-dev uuid-dev \
# core
    libpcre2-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
# core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
# mod_enum
    libldns-dev \
# mod_python3
    python3-dev \
# mod_av
    libavformat-dev libswscale-dev libswresample-dev \
# mod_vpx（VP8/VP9，WebRTC 视频）
    libvpx-dev libyuv-dev \
# mod_lua
    liblua5.2-dev \
# mod_opus
    libopus-dev \
# mod_pgsql
    libpq-dev \
# mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
# mod_shout
    libshout3-dev libmpg123-dev libmp3lame-dev libpng-dev

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/spandsp && git checkout 0d2e6ac && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install
RUN cd /usr/src/libs/libpng && ./configure && make && make install


# ---- 应用 mod_av 的 FFmpeg 6.0+ 兼容补丁 ----
RUN cd /usr/src/freeswitch && cat > /tmp/mod_av_ffmpeg6.patch <<'EOF'
From 2e75bb8b2c7f70c5d16c9e3d14b1427f4eb80c9c Mon Sep 17 00:00:00 2001
From: Korynkai <matt@qmxtech.com>
Date: Thu, 17 Aug 2023 21:10:31 +0200
Subject: [PATCH] mod_av: fix build with ffmpeg 6.0

Upstream: https://github.com/signalwire/freeswitch/issues/2202

---
 src/mod/applications/mod_av/avformat.c | 2 ++
 src/mod/applications/mod_av/mod_av.h   | 1 +
 2 files changed, 3 insertions(+)

diff --git a/src/mod/applications/mod_av/avformat.c b/src/mod/applications/mod_av/avformat.c
index 69475c169f..0a1662aed6 100644
--- a/src/mod/applications/mod_av/avformat.c
+++ b/src/mod/applications/mod_av/avformat.c
@@ -455,6 +455,7 @@ static int mod_avformat_alloc_output_context2(AVFormatContext **avctx, const cha
 	}
 
 	s->oformat = oformat;
+#if (LIBAVFORMAT_VERSION_MAJOR < LIBAVFORMAT_N)
 	if (s->oformat->priv_data_size > 0) {
 		s->priv_data = av_mallocz(s->oformat->priv_data_size);
 		if (!s->priv_data) {
@@ -468,6 +469,7 @@ static int mod_avformat_alloc_output_context2(AVFormatContext **avctx, const cha
 	} else {
 		s->priv_data = NULL;
 	}
+#endif
 
 	if (filename) {
 #if (LIBAVCODEC_VERSION_INT < AV_VERSION_INT(58,7,100))
diff --git a/src/mod/applications/mod_av/mod_av.h b/src/mod/applications/mod_av/mod_av.h
index a89e6cb8f7..ef9bd48d73 100644
--- a/src/mod/applications/mod_av/mod_av.h
+++ b/src/mod/applications/mod_av/mod_av.h
@@ -42,6 +42,7 @@
 
 #define LIBAVCODEC_V 59
 #define LIBAVFORMAT_V 59
+#define LIBAVFORMAT_N 60
 #define LIBAVUTIL_V 57
 
 struct mod_av_globals {
EOF
RUN cd /usr/src/freeswitch && git apply /tmp/mod_av_ffmpeg6.patch

# Enable modules
RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_abstraction|applications/mod_abstraction|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_curl|applications/mod_curl|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_directory|applications/mod_directory|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_distributor|applications/mod_distributor|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_easyroute|applications/mod_easyroute|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#applications/mod_http_cache|applications/mod_http_cache|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#endpoints/mod_rtmp|endpoints/mod_rtmp|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#xml_int/mod_xml_curl|xml_int/mod_xml_curl|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#event_handlers/mod_format_cdr|event_handlers/mod_format_cdr|' /usr/src/freeswitch/build/modules.conf.in && \
    sed -i 's|#event_handlers/mod_json_cdr|event_handlers/mod_json_cdr|' /usr/src/freeswitch/build/modules.conf.in

#RUN PKG_CONFIG_PATH=/usr/lib/pkgconfig
RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && PKG_CONFIG_PATH=/usr/lib/pkgconfig ./configure
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
