FROM node:22.11.0 AS node
FROM composer
FROM php:8.0-apache AS base

# Install system and PHP deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git libxml2-dev libpng-dev watchman libonig-dev \
    curl gnupg2 lsb-release ca-certificates \
    && curl -sL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions openssl xmlrpc json xmlreader pcre spl zip curl \
    && docker-php-ext-install mysqli iconv mbstring tokenizer soap ctype simplexml gd dom xml intl \
    && docker-php-ext-enable mysqli iconv mbstring tokenizer soap ctype simplexml gd dom xml intl \
    && rm -rf /var/lib/apt/lists/*

# Install Node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Install composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Clone Moodle and grant permissions
RUN git clone -b MOODLE_402_STABLE --depth 1 \
    git://git.moodle.org/moodle.git /var/www/html/moodle \
    && mkdir -p /var/www/moodledata \
    && chmod -R 777 /var/www/html/moodle /var/www/moodledata

# Add custom config to php
RUN {\
    echo 'max_input_vars=5000'; \
    echo 'php_admin_flag[log_errors] = on'; \
    echo 'php_flag[display_errors] = off'; \
    }>/usr/local/etc/php/conf.d/custom.ini

EXPOSE 3000

WORKDIR /var/www/html/moodle/

# Node deps (Moodle tooling)
RUN npm ci