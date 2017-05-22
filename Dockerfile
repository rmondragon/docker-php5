FROM ubuntu:14.04.4
MAINTAINER Rolando Galindo <rmondragon@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive \
    APACHE_DOCUMENTROOT=/var/www/htdocs \
    APACHE_LOG_DIR=/logs \
    PHP_INI_DIR=/usr/local/etc/php \
    PHP_FILENAME=php-5.5.38.tar.xz \
    TERM=xterm

#dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    autoconf \
    file \
    g++ \
    gcc \
    pkg-config \
    build-essential \
    libc-dev \
    make \
    re2c \
    ca-certificates \
    curl \
    aspell \
    libedit2 \
    libedit-dev \
    libreadline-dev \
    libsqlite3-0 \
    libsqlite3-dev \
    libxml2 \
    libxml2-dev \
    libxslt1-dev \
    libbz2-dev \
    libmcrypt-dev \
    libcurl4-openssl-dev \
    libltdl-dev \
    libpspell-dev \
    openssl \
    libssl-dev \
    liblua5.1-dev \
    libmemcached-dev \
    libgeoip-dev \
    language-pack-en-base \
    software-properties-common \
    mysql-client-5.6 \
    mysql-client-core-5.6 \
    mysql-common-5.6 \
    postgresql \
    postgresql-contrib \
    gettext \
    libjpeg-turbo8-dev \
    libjpeg8-dev \
    libjpeg-dev \
    libtiff-dev \
    libgd-dev \
    libgd2-xpm-dev \
    libfreetype6-dev \
    libpng-dev \
    libgcrypt11-dev \
    zlib1g-dev \
    fonttools \
    libpcre3 \
    libpcre3-dev \
    libt1-dev \
    xz-utils \
    wget \
    vim \
    git-core \
    imagemagick \
    imagemagick-common \
    libmagickcore-dev \
    libmagickcore5 \
    libmagickcore5-extra \
    libmagickwand-dev \
    libmagickwand5 \
    zip \
    unzip \
    --no-install-recommends

#bison
RUN cd /tmp/ \
    && wget http://launchpadlibrarian.net/140087283/libbison-dev_2.7.1.dfsg-1_amd64.deb \
    && wget http://launchpadlibrarian.net/140087282/bison_2.7.1.dfsg-1_amd64.deb \
    && dpkg -i libbison-dev_2.7.1.dfsg-1_amd64.deb \
    && dpkg -i bison_2.7.1.dfsg-1_amd64.deb \
    && apt-mark hold libbison-dev \
    && apt-mark hold bison

#apache
RUN apt-get update \
    && apt-get install -y \
    apache2 \
    apache2-dev \
    apache2-utils \
    --no-install-recommends

#setup host
RUN a2enmod rewrite \
    && echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf \
    && a2enconf fqdn \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork

# setup directories and permissions
RUN mkdir -p "$APACHE_DOCUMENTROOT" \
    && mkdir -p "$APACHE_LOG_DIR"

#php
COPY "extras/php/$PHP_FILENAME" /tmp/

RUN mkdir -p $PHP_INI_DIR/conf.d \
    mkdir -p /usr/src/php \
    && tar -xf "/tmp/$PHP_FILENAME" -C /usr/src/php --strip-components=1 \
    && rm "/tmp/$PHP_FILENAME" \
    && cd /usr/src/php \
    && ./configure \
        --with-apxs2=/usr/bin/apxs2 --with-mysql --with-mysqli \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --with-pgsql=/usr/local/bin/postgres \
        --enable-bcmath \
        --enable-calendar \
        --enable-exif \
        --enable-dba \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --enable-pcntl \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-wddx \
        --with-bz2 \
        --with-curl \
        --with-gettext \
        --with-gd \
        --with-iconv \
        --enable-gd-native-ttf \
        --with-vpx-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-freetype-dir \
        --with-t1lib \
        --with-libedit \
        --with-libxml-dir \
        --with-xsl \
        --with-mcrypt \
        --with-mhash \
        --with-pcre-regex \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-pgsql=/usr/local/bin/postgres \
        --with-pgsql \
        --with-openssl \
        --with-pspell \
        --with-readline \
        --with-zlib \
        --enable-zip \
    && make -j"$(nproc)" \
    && make install

# phpunit 4.8.9 last version for php 5.5
RUN cd /tmp/ \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer \
    && curl -sSLo phpunit.phar https://phar.phpunit.de/phpunit-4.8.9.phar \
    && chmod 755 phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit

#memcached 2.2.0 last version for php 5.5
RUN cd /tmp/ \
    && git clone https://github.com/php-memcached-dev/php-memcached.git \
    && cd php-memcached \
    && git checkout tags/2.2.0 \
    && phpize \
    && ./configure --disable-memcached-sasl \
    && make \
    && make install \
    && bash -c "echo 'extension=/usr/local/lib/php/extensions/no-debug-non-zts-20121212/memcached.so' >> /usr/local/etc/php/conf.d/10-memcached.ini"

# aerospike 3.4.14 last version
RUN cd /tmp/ \
    && composer require aerospike/aerospike-client-php "3.4.14" \
    && cd vendor/aerospike/aerospike-client-php/ \
    && find src/aerospike -name "*.sh" -exec chmod +x {} \; \
    && composer run-script post-install-cmd \
    && cd src/aerospike \
    && make install \
    && bash -c "echo 'extension=/usr/local/lib/php/extensions/no-debug-non-zts-20121212/aerospike.so' >> /usr/local/etc/php/conf.d/20-aerospike.ini" \
    && bash -c "echo 'aerospike.udf.lua_system_path=/usr/local/aerospike/lua' >> /usr/local/etc/php/conf.d/20-aerospike.ini" \
    && bash -c "echo 'aerospike.udf.lua_user_path=/usr/local/aerospike/usr-lua' >> /usr/local/etc/php/conf.d/20-aerospike.ini"

# imagick 3.4.3 last version
RUN cd /tmp/ \
    && pecl install imagick  \
    && bash -c "echo 'extension=imagick.so' >> /usr/local/etc/php/conf.d/30-imagick.ini" \

# geo-ip beta 1.1.1
RUN cd /tmp/ \
    && pecl install geoip-beta  \
    && bash -c "echo 'extension=geoip.so' >> /usr/local/etc/php/conf.d/40-geoip.ini" \
    && mkdir -p /usr/share/GeoIP \
    && cd /usr/share/GeoIP \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
    && gunzip GeoLiteCity.dat.gz \
    && cp GeoLiteCity.dat GeoIPCity.dat

#phash 0.9.6 last version for php 5.5
RUN add-apt-repository ppa:mc3man/trusty-media \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y ffmpeg libavformat-dev libmpg123-dev libsamplerate-dev \
    libsndfile-dev cimg-dev libavcodec-dev libswscale-dev \
    && cd /tmp/ \
    && git clone -b master https://github.com/rmondragon/pHash-0.9.6-patches \
    && cd pHash-0.9.6-patches/pHash-0.9.6/ \
    && ./configure \
    && make \
    && make install \
    && cd bindings/php \
    && phpize \
    && ./configure LIBS="-lpthread" \
    && make \
    && make install \
    && bash -c "echo 'extension=/usr/local/lib/php/extensions/no-debug-non-zts-20121212/pHash.so' >> /usr/local/etc/php/conf.d/50-phash.ini"

#xdebug 2.5.4 last version
RUN cd /tmp/ \
    && wget https://xdebug.org/files/xdebug-2.5.4.tgz \
    && tar -xvzf xdebug-2.5.4.tgz \
    && cd xdebug-2.5.4/ \
    && phpize \
    && ./configure \
    && make \
    && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20121212 \
    && bash -c "echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20121212/xdebug.so' >> /usr/local/etc/php/conf.d/60-xdebug.ini"

# default vhost
COPY extras/apache/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# php ini
COPY extras/php/php.ini "$PHP_INI_DIR/php.ini"

# new default index
COPY extras/php/phpinfo.php "$APACHE_DOCUMENTROOT/phpinfo.php"

# clean up
RUN apt-get purge -y \
    && apt-get clean \
    && rm -rf /usr/share/locale \
    && rm -rf /usr/share/man    \
    && rm -rf /usr/share/doc    \
    && rm -rf /usr/share/info   \
    && rm -rf /home/*           \
    && rm -rf /tmp/*            \
    && rm -rf /var/lib/apt/*

WORKDIR /var/www/htdocs

# ports
EXPOSE 80 9000

CMD ["apache2ctl", "-D FOREGROUND"]