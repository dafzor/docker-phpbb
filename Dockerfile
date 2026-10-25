FROM alpine:3.24

LABEL maintainer="selim013@gmail.com"

RUN apk add --no-cache curl \
    imagemagick \
    apache2 \
    php83 \
    php83-apache2 \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-ftp \
    php83-gd \
    php83-iconv \
    php83-json \
    php83-mbstring \
    php83-mysqli \
    php83-opcache \
    php83-openssl \
    php83-pgsql \
    php83-sqlite3 \
    php83-tokenizer \
    php83-xml \
    php83-zlib \
    php83-zip \
    su-exec

### phpBB
ENV PHPBB_VERSION 3.3.19
ENV PHPBB_SHA256  66f35fa3d9bf3b90269205bbb281e1156727a0014eea344fe15f9c7376b78c66

WORKDIR /tmp

RUN curl -SL https://download.phpbb.com/pub/release/3.3/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.tar.bz2 -o phpbb.tar.bz2 \
    && echo "${PHPBB_SHA256}  phpbb.tar.bz2" | sha256sum -c - \
    && tar -xjf phpbb.tar.bz2 \
    && mkdir /phpbb \
    && mkdir /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && rm -f phpbb.tar.bz2

COPY phpbb/config.php /phpbb/www

### Server
RUN mkdir -p /run/apache2 /phpbb/opcache \
    && chown apache:apache /run/apache2 /phpbb/opcache

COPY apache2/httpd.conf /etc/apache2/
COPY apache2/conf.d/* /etc/apache2/conf.d/
COPY php/php.ini php/php-cli.ini /etc/php83/
COPY php/conf.d/* /etc/php83/conf.d
COPY start.sh /usr/local/bin/

RUN chown -R apache:apache /phpbb
WORKDIR /phpbb/www

#VOLUME /phpbb/sqlite
#VOLUME /phpbb/www/files
#VOLUME /phpbb/www/store
#VOLUME /phpbb/www/images/avatars/upload

ENV PHPBB_INSTALL= \
    PHPBB_DB_DRIVER=sqlite3 \
    PHPBB_DB_HOST=/phpbb/sqlite/sqlite.db \
    PHPBB_DB_PORT= \
    PHPBB_DB_NAME= \
    PHPBB_DB_USER= \
    PHPBB_DB_PASSWD= \
    PHPBB_DB_TABLE_PREFIX=phpbb_ \
    PHPBB_DB_AUTOMIGRATE= \
    PHPBB_DISPLAY_LOAD_TIME= \
    PHPBB_DEBUG= \
    PHPBB_DEBUG_CONTAINER=

EXPOSE 80
CMD ["start.sh"]