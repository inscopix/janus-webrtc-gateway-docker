FROM buildpack-deps:stretch

RUN sed -i 's/archive.ubuntu.com/mirror.aarnet.edu.au\/pub\/ubuntu\/archive/g' /etc/apt/sources.list

RUN rm -rf /var/lib/apt/lists/*
RUN apt-get -y update && apt-get install -y \
    libmicrohttpd-dev \
    libjansson-dev \
    libnice-dev \
    libssl-dev \
    libsrtp-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libini-config-dev \
    libcollection-dev \
    libconfig-dev \
    pkg-config \
    gengetopt \
    libtool \
    autopoint \
    automake \
    build-essential \
    subversion \
    git \
    cmake \
    unzip \
    zip \
    lsof wget vim sudo rsync cron mysql-client openssh-server supervisor locate mplayer valgrind certbot python-certbot-apache dnsutils tcpdump gstreamer1.0-tools


# RUN apt-get install -y libx264-dev libmatroska-dev libopus-dev libssl1.0-dev libtheora-dev libogg-dev python3-pip flex bison libsoup2.4-dev libjpeg-dev nasm libvpx-dev
# RUN sudo pip3 install meson ninja
# RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-build
# WORKDIR /gst-build
# RUN git log -n 1 HEAD
# RUN git checkout 1016bf23
# RUN git log -n 1 HEAD
# RUN mkdir builddir
# # RUN meson builddir
# RUN meson builddir
# RUN ninja -C builddir update
# RUN ninja install -C builddir
# RUN ldconfig
# RUN which gst-launch-1.0
# RUN ldd /usr/local/bin/gst-launch-1.0
# RUN gst-launch-1.0


# FFmpeg build section


# nginx-rtmp with openresty
RUN ZLIB="zlib-1.2.11" && vNGRTMP="v1.1.11" && PCRE="8.41" && nginx_build=/root/nginx && mkdir $nginx_build && \
    cd $nginx_build && \
    wget https://ftp.pcre.org/pub/pcre/pcre-$PCRE.tar.gz && \
    tar -zxf pcre-$PCRE.tar.gz && \
    cd pcre-$PCRE && \
    ./configure && make && make install && \
    cd $nginx_build && \
    wget http://zlib.net/$ZLIB.tar.gz && \
    tar -zxf $ZLIB.tar.gz && \
    cd $ZLIB && \
    ./configure && make &&  make install && \
    cd $nginx_build && \
    wget https://github.com/arut/nginx-rtmp-module/archive/$vNGRTMP.tar.gz && \
    tar zxf $vNGRTMP.tar.gz && mv nginx-rtmp-module-* nginx-rtmp-module


RUN OPENRESTY="1.13.6.2" && ZLIB="zlib-1.2.11" && PCRE="pcre-8.41" &&  openresty_build=/root/openresty && mkdir $openresty_build && \
    wget https://openresty.org/download/openresty-$OPENRESTY.tar.gz && \
    tar zxf openresty-$OPENRESTY.tar.gz && \
    cd openresty-$OPENRESTY && \
    nginx_build=/root/nginx && \
    ./configure --sbin-path=/usr/local/nginx/nginx \
    --conf-path=/usr/local/nginx/nginx.conf  \
    --pid-path=/usr/local/nginx/nginx.pid \
    --with-pcre-jit \
    --with-ipv6 \
    --with-pcre=$nginx_build/$PCRE \
    --with-zlib=$nginx_build/$ZLIB \
    --with-http_ssl_module \
    --with-stream \
    --with-mail=dynamic \
    --add-module=$nginx_build/nginx-rtmp-module && \
    make && make install && mv /usr/local/nginx/nginx /usr/local/bin




# Boringssl build section
# If you want to use the openssl instead of boringssl
RUN apt-get update -y && apt-get install -y libssl-dev
RUN apt-get -y update && apt-get install -y --no-install-recommends \
        g++ \
        gcc \
        libc6-dev \
        make \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*
ENV GOLANG_VERSION 1.7.5
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 2e4dd6c44f0693bef4e7b46cc701513d74c3cc44f2419bf519d7868b12931ac3
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"



# https://boringssl.googlesource.com/boringssl/+/chromium-stable

RUN LIBWEBSOCKET="3.1.0" && wget https://github.com/warmcat/libwebsockets/archive/v$LIBWEBSOCKET.tar.gz && \
    tar xzvf v$LIBWEBSOCKET.tar.gz && \
    cd libwebsockets-$LIBWEBSOCKET && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_MAX_SMP=1 -DLWS_IPV6="ON" .. && \
    make && make install


RUN SRTP="2.2.0" && apt-get remove -y libsrtp0-dev && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && sudo make install



# March, 2019 1 commit 67807a17ce983a860804d7732aaf7d2fb56150ba
RUN apt-get remove -y libnice-dev libnice10 && \
    echo "deb http://deb.debian.org/debian  stretch-backports main" >> /etc/apt/sources.list && \
    apt-get  update && \
    apt-get install -y gtk-doc-tools libgnutls28-dev -t stretch-backports  && \
    git clone https://gitlab.freedesktop.org/libnice/libnice.git && \
    cd libnice && \
    git checkout 67807a17ce983a860804d7732aaf7d2fb56150ba && \
    bash autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install


RUN COTURN="4.5.0.8" && wget https://github.com/coturn/coturn/archive/$COTURN.tar.gz && \
    tar xzvf $COTURN.tar.gz && \
    cd coturn-$COTURN && \
    ./configure && \
    make && make install


# RUN GDB="8.0" && wget ftp://sourceware.org/pub/gdb/releases/gdb-$GDB.tar.gz && \
#     tar xzvf gdb-$GDB.tar.gz && \
#     cd gdb-$GDB && \
#     ./configure && \
#     make && \
#     make install


# ./configure CFLAGS="-fsanitize=address -fno-omit-frame-pointer" LDFLAGS="-lasan"


# datachannel build
RUN cd / && git clone https://github.com/sctplab/usrsctp.git && cd /usrsctp && \
    git checkout origin/master && git reset --hard 1c9c82fbe3582ed7c474ba4326e5929d12584005 && \
    ./bootstrap && \
    ./configure && \
    make && make install

RUN apt-get install -y texinfo
WORKDIR /tmp
RUN git clone https://git.gnunet.org/libmicrohttpd.git
WORKDIR /tmp/libmicrohttpd
RUN git checkout v0.9.71
RUN autoreconf -fi
RUN ./configure
RUN make && make install


RUN cd / && git clone https://github.com/meetecho/janus-gateway.git && cd /janus-gateway && \
    git checkout refs/tags/v0.10.4 && \
    sh autogen.sh &&  \
    PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix=/opt/janus \
#    --enable-post-processing \
#    --enable-boringssl \
#    --enable-data-channels \
#    --disable-rabbitmq \
#    --disable-mqtt \
#    --disable-unix-sockets \
#    --enable-dtls-settimeout \
#    --enable-plugin-echotest \
#    --enable-plugin-recordplay \
#    --enable-plugin-sip \
#    --enable-plugin-videocall \
#    --enable-plugin-voicemail \
#    --enable-plugin-textroom \
#    --enable-rest \
#    --enable-turn-rest-api \
#    --enable-plugin-audiobridge \
#    --enable-plugin-nosip \
    --enable-all-handlers && \
    make && make install && make configs && ldconfig

RUN mkdir /opt/janus/share/janus/certs && \
    cd /opt/janus/share/janus/certs && \ 
    openssl req -x509 -newkey rsa:4096 -keyout mycert.key -out mycert.pem -days 10000 -nodes \
    -subj "/C=US/CN=inscopix.com"

COPY nginx.conf /usr/local/nginx/nginx.conf
WORKDIR /opt/janus/bin

#CMD nginx && janus

# RUN apt-get -y install iperf iperf3
# RUN git clone https://github.com/HewlettPackard/netperf.git && \
#     cd netperf && \
#     bash autogen.sh && \
#     ./configure && \
#     make && \
#     make install
