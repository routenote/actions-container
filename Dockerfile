FROM php:7.4-cli

ARG BUILD_DATE
ARG VCS_REF

ENV COMPOSER_NO_INTERACTION=1
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV NVM_VERSION v0.33.5

RUN apt-get update

# Required to add yarn package repository
RUN apt-get install -y apt-transport-https gnupg2

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y \
    libbz2-dev \
    libsodium-dev \
    git \
    unzip \
    wget \
    libpng-dev \
    libgconf-2-4 \
    libfontconfig1 \
    chromium \
    xvfb \
    yarn \
    libzip-dev \
    libsqlite3-dev \
    libgmp-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev

RUN apt-get install -y libmagickwand-dev --no-install-recommends

RUN pecl install imagick

RUN docker-php-ext-enable imagick

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/

RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    bz2 \
    calendar \
    exif \
    gd \
    sodium \
    pcntl \
    pdo_mysql \
    shmop \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    zip \
    gmp \
    intl \
    gd

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash

COPY ./scripts ./scripts

RUN ./scripts/composer.sh

# Install Vapor + Prestissimo (parallel/quicker composer install)
RUN set -xe && \
    composer global require hirak/prestissimo && \
    composer global require laravel/vapor-cli && \
    composer clear-cache

# Install Node.js (needed for Vapor's NPM Build)
RUN apk add --update nodejs npm

# Prepare out Entrypoint (used to run Vapor commands)
COPY vapor-entrypoint /usr/local/bin/vapor-entrypoint

ENTRYPOINT ["/usr/local/bin/vapor-entrypoint"]
