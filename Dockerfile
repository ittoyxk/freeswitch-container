# ============================================================
# 阶段 1: Builder —— 完全保留你原有的编译逻辑
# ============================================================
FROM debian:trixie AS builder
MAINTAINER xiaokang

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone -b v1.11.3 --depth=1 https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone -b v1.13.18 --depth=1 https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone -b v3.1.1 --depth=1 https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
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
# mod_vpx
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
RUN cd /usr/src/libs/spandsp  && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install
RUN cd /usr/src/libs/libpng && ./configure && make && make install

# ---- 直接修改 mod_av 源码以兼容 FFmpeg 6.0+（保持你原有逻辑）----
RUN cd /usr/src/freeswitch && \
    sed -i 's/s->oformat->priv_data_size > 0/0 > 0 \/* FFmpeg 6.0 compat *\//' src/mod/applications/mod_av/avformat.c && \
    sed -i 's/av_mallocz(s->oformat->priv_data_size)/av_mallocz(0) \/* FFmpeg 6.0 compat *\//' src/mod/applications/mod_av/avformat.c && \
    grep -q 'LIBAVFORMAT_N' src/mod/applications/mod_av/mod_av.h || \
    sed -i '/#define LIBAVFORMAT_V 59/a #define LIBAVFORMAT_N 60' src/mod/applications/mod_av/mod_av.h

# Enable modules（保持你原有逻辑）
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

RUN PKG_CONFIG_PATH=/usr/lib/pkgconfig
RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && PKG_CONFIG_PATH=/usr/lib/pkgconfig ./configure
RUN cd /usr/src/freeswitch && make -j`nproc` && make install

# ---- 收集体积优化 + 统一库路径 ----
# 将手动编译的库收集到 /usr/local/lib，供 Runtime 阶段确定性 COPY
RUN mkdir -p /usr/local/lib && \
    cp -a /usr/lib/libsofia-sip-ua.so* /usr/local/lib/ 2>/dev/null || true && \
    cp -a /usr/lib/libspandsp.so* /usr/local/lib/ 2>/dev/null || true && \
    cp -a /usr/lib/libks*.so* /usr/local/lib/ 2>/dev/null || true && \
    cp -a /usr/lib/libsignalwire*.so* /usr/local/lib/ 2>/dev/null || true && \
    cp -a /usr/local/lib/libpng*.so* /usr/local/lib/ 2>/dev/null || true

# strip 调试符号、删除静态库和头文件
RUN find /usr/local/freeswitch/lib /usr/local/freeswitch/mod -name '*.so' \
        -exec strip --strip-unneeded {} \; 2>/dev/null || true && \
    find /usr/local/freeswitch -name '*.a' -delete && \
    rm -rf /usr/local/freeswitch/include

RUN rm -rf /usr/src/* /var/lib/apt/lists/* && apt-get clean


# ============================================================
# 阶段 2: Runtime —— 仅保留运行所需（已修正 t64 包名）
# ============================================================
FROM debian:trixie
MAINTAINER xiaokang

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -yq install --no-install-recommends \
    ca-certificates libstdc++6 \
    libssl3t64 zlib1g libdb5.3t64 unixodbc libncurses6 libexpat1 libgdbm6t64 \
    libtiff6 libuuid1 libpcre2-8-0 libedit2 libsqlite3-0 libcurl4t64 \
    libogg0 libspeex1 libspeexdsp1 libldns3 \
    python3 \
    libavformat61 libavcodec61 libavutil59 libswscale8 libswresample5 \
    libvpx9 libyuv0 \
    liblua5.2-0 \
    libopus0 \
    libpq5 \
    libsndfile1 libflac14 libvorbis0a \
    libshout3 libmpg123-0 libmp3lame0 libpng16-16t64 \
    && rm -rf /var/lib/apt/lists/*

# 复制 FreeSWITCH 安装产物
COPY --from=builder /usr/local/freeswitch /usr/local/freeswitch

# 复制 Builder 阶段统一收集的手动编译库（路径确定）
COPY --from=builder /usr/local/lib/ /usr/local/lib/

RUN ldconfig

RUN ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch && \
    ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli

COPY docker-entrypoint.sh healthcheck.sh /
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  /healthcheck.sh

RUN chmod +x /healthcheck.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
