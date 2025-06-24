FROM node:22.11.0 AS node
FROM composer
FROM php:8.0-apache
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install git and Moodle
RUN apt-get update && \
    apt-get install -y git \
    libxml2-dev \
    libpng-dev \
    watchman \
    libonig-dev && \
    git clone -b MOODLE_402_STABLE --depth 1 git://git.moodle.org/moodle.git /var/www/html/moodle

# Install node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Install composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer


# Install grunt, grunt-cli and npx
WORKDIR /var/www/html/moodle/

RUN npm i
RUN npm i -g grunt-cli
RUN npm i -g npx

# Grant permissions to docker-php-extension-installer
RUN chmod +x /usr/local/bin/install-php-extensions

# Grant permissions to read, write and exec to all users in /var/www/
RUN chmod 777 /var/www/

# Grant permissions to read, write and exec to all users in /var/www/moodle
RUN chmod 777 /var/www/html/moodle

# Install dependencies

RUN install-php-extensions openssl
RUN install-php-extensions xmlrpc
RUN install-php-extensions json
RUN install-php-extensions xmlreader
RUN install-php-extensions pcre
RUN install-php-extensions spl
RUN install-php-extensions zip
RUN install-php-extensions curl

RUN docker-php-ext-install mysqli 
RUN docker-php-ext-install iconv
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install tokenizer
RUN docker-php-ext-install soap
RUN docker-php-ext-install ctype
RUN docker-php-ext-install simplexml
RUN docker-php-ext-install gd
RUN docker-php-ext-install dom
RUN docker-php-ext-install xml
RUN docker-php-ext-install intl

# Enable dependencies
RUN docker-php-ext-enable mysqli \
    iconv \
    mbstring \
    tokenizer \
    soap \
    ctype \
    simplexml \
    gd \
    dom \
    xml \
    intl

# Create moodledata directory and grant permissions
RUN mkdir /var/www/moodledata/ && \
    chmod 777 /var/www/moodledata

# Add custom config to php
RUN {\
    echo 'max_input_vars=5000'; \
    echo 'php_admin_flag[log_errors] = on'; \
    echo 'php_flag[display_errors] = off'; \
}>/usr/local/etc/php/conf.d/custom.ini

EXPOSE 3000
