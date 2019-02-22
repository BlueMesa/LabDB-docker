FROM php:7.1-fpm

RUN apt update -y && \
apt upgrade -y && \
mkdir -p /usr/share/man/man1 && \
apt install -y default-jre git libc-client2007e-dev libkrb5-dev libssl-dev libzip-dev unzip  && \
docker-php-ext-install -j$(nproc) iconv && \
docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
docker-php-ext-install -j$(nproc) imap && \
docker-php-ext-install -j$(nproc) pdo_mysql && \
docker-php-ext-install -j$(nproc) zip && \
echo '' | pecl install redis && \
docker-php-ext-enable redis && \
curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt install -y git gnupg && \
curl -sL https://deb.nodesource.com/setup_11.x | bash - && \
apt-get install -y nodejs && \
npm install --global bower

RUN echo 'memory_limit = 2G' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
git clone --recursive https://github.com/BlueMesa/LabDB.git /usr/src/LabDB && \
LASTPWD=$( pwd ) && \
cd /usr/src/LabDB && \
cp app/config/security.imap.yml app/config/security.yml && \
composer install -n && \
bower --allow-root install && \
chown -R www-data:www-data /usr/src/LabDB && \
cd $LASTPWD

ENV DB_DRIVER=pdo_mysql
ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_NAME=labdb
ENV DB_USER=labdb
ENV CACHE_DRIVER=redis
ENV CACHE_HOST=localhost
ENV CACHE_PORT=6379
ENV PRINT_HOST=null
ENV PRINT_QUEUE=null

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
