FROM php:8.0-apache AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git libxml2-dev libpng-dev watchman libonig-dev \
    curl gnupg2 lsb-release ca-certificates \
    # Install PHP extensions manager
    && curl -sL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    # PHP extensions
    && install-php-extensions \
    openssl xmlrpc json xmlreader pcre spl zip curl \
    && docker-php-ext-install \
    mysqli iconv mbstring tokenizer soap ctype simplexml gd dom xml intl \
    && docker-php-ext-enable \
    mysqli iconv mbstring tokenizer soap ctype simplexml gd dom xml intl \
    # Setup Node.js
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g grunt-cli npx \
    # Setup Composer
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    # Final pune
    && rm -rf /var/lib/apt/lists/*

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