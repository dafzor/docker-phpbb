FROM debian:trixie-slim

LABEL maintainer="selim013@gmail.com"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && printf '%s\n' \
        'deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ trixie main' \
        > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        bzip2 \
        ca-certificates \
        curl \
        gosu \
        imagemagick \
        libapache2-mod-php7.4 \
        netcat-openbsd \
        php7.4-cli \
        php7.4-curl \
        php7.4-gd \
        php7.4-mysql \
        php7.4-opcache \
        php7.4-pgsql \
        php7.4-sqlite3 \
        php7.4-xml \
        php7.4-zip \
    && rm -rf /var/lib/apt/lists/* /tmp/debsuryorg-archive-keyring.deb

### phpBB
ENV PHPBB_VERSION 3.2.11
ENV PHPBB_SHA256 'e863c354554c975e38d5ffca2ebbacea3e9c317fda4c925d6da242156286ce43'

WORKDIR /tmp

RUN curl -SL https://download.phpbb.com/pub/release/3.2/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.tar.bz2 -o phpbb.tar.bz2 \
    && echo "${PHPBB_SHA256}  phpbb.tar.bz2" | sha256sum -c - \
    && tar -xjf phpbb.tar.bz2 \
    && mkdir /phpbb \
    && mkdir /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && rm -f phpbb.tar.bz2

COPY phpbb/config.php /phpbb/www

### Server
RUN mkdir -p /run/apache2 /phpbb/opcache \
    && chown www-data:www-data /run/apache2 /phpbb/opcache

COPY apache2/httpd.conf /etc/apache2/sites-available/phpbb.conf
COPY apache2/conf.d/* /etc/apache2/conf-available/
RUN a2enmod rewrite \
    && a2dissite 000-default \
    && a2ensite phpbb \
    && a2enconf mpm

COPY php/php.ini /etc/php/7.4/apache2/php.ini
COPY php/php-cli.ini /etc/php/7.4/cli/php.ini
COPY php/conf.d/* /etc/php/7.4/apache2/conf.d/
COPY php/conf.d/* /etc/php/7.4/cli/conf.d/

COPY start.sh /usr/local/bin/

RUN chown -R www-data:www-data /phpbb
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