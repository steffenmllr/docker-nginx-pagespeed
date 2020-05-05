FROM debian:stretch-slim
ARG NGINX_VERSION=1.18.0
ARG NPS_VERSION=1.13.35.2

WORKDIR /build
RUN apt-get update && apt-get install -y build-essential uuid-dev gcc make curl wget zlib1g-dev libpcre3 libpcre3-dev unzip openssl libssl-dev
RUN curl -L https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-beta.tar.gz | tar zxvf - \
    && curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar zxvf - \
    && cd incubator-pagespeed-ngx-${NPS_VERSION}-beta && \
    psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
    wget ${psol_url} && \
    tar -xzvf $(basename ${psol_url})

RUN cd nginx-${NGINX_VERSION} \
    && ./configure --with-http_v2_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --sbin-path=/usr/sbin/nginx \
        --prefix=/etc/nginx \
        --add-module=/build/incubator-pagespeed-ngx-${NPS_VERSION}-beta \
    && make \
    && make install

COPY nginx.conf /etc/nginx/conf/nginx.conf
RUN mkdir -p /tmp/cache
RUN nginx -V

EXPOSE 80
EXPOSE 433

# Launch command
CMD ["nginx", "-g", "daemon off;"]
