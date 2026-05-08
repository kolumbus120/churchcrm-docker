FROM php:8.4-apache

# Inštalácia systémových závislostí
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    gettext \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Konfigurácia a inštalácia PHP rozšírení
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    intl \
    gd \
    gettext \
    bcmath \
    zip

# Stiahnutie a inštalácia ChurchCRM (verzia sa dá predefinovať pri builde)
ARG CHURCHCRM_VERSION=7.3.1
ENV CHURCHCRM_VERSION=${CHURCHCRM_VERSION}
RUN curl -L -o /tmp/churchcrm.zip https://github.com/ChurchCRM/CRM/releases/download/${CHURCHCRM_VERSION}/ChurchCRM-${CHURCHCRM_VERSION}.zip \
    && unzip /tmp/churchcrm.zip -d /tmp/ \
    && rm -rf /var/www/html/* \
    && cp -R /tmp/churchcrm/* /var/www/html/ \
    && rm -rf /tmp/churchcrm /tmp/churchcrm.zip

# Povolenie Apache mod_rewrite a nastavenie práv
RUN a2enmod rewrite \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Nastavenie odporúčaných PHP hodnôt
RUN { \
    echo 'memory_limit=512M'; \
    echo 'upload_max_filesize=100M'; \
    echo 'post_max_size=100M'; \
    echo 'max_execution_time=300'; \
    echo 'date.timezone=Europe/Bratislava'; \
    } > /usr/local/etc/php/conf.d/churchcrm-limits.ini

WORKDIR /var/www/html
EXPOSE 80
