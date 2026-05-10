FROM php:8.4-apache

# Metadata [SK: Metadáta obrazu]
LABEL maintainer="kolumbus120 (with AI)"
LABEL description="Modernized ChurchCRM Docker image with PHP 8.4, Apache and automatic updates"
LABEL version="7.3.1"

# Install system dependencies [SK: Inštalácia systémových závislostí]
RUN apt-get update && apt-get install -y \
    curl \
    gettext \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libonig-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions [SK: Inštalácia PHP rozšírení]
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    curl \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    pdo_mysql \
    soap \
    sockets \
    xml \
    zip

# Download and install ChurchCRM [SK: Stiahnutie a inštalácia ChurchCRM]
ARG CHURCHCRM_VERSION=7.3.1
ENV CHURCHCRM_VERSION=${CHURCHCRM_VERSION}
RUN curl -L -o /tmp/churchcrm.zip https://github.com/ChurchCRM/CRM/releases/download/${CHURCHCRM_VERSION}/ChurchCRM-${CHURCHCRM_VERSION}.zip \
    && unzip /tmp/churchcrm.zip -d /tmp/ \
    && rm -rf /var/www/html/* \
    && cp -R /tmp/churchcrm/* /var/www/html/ \
    && rm -rf /tmp/churchcrm /tmp/churchcrm.zip

# Enable Apache mod_rewrite and set permissions [SK: Povolenie Apache mod_rewrite a nastavenie práv]
RUN a2enmod rewrite \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Set recommended PHP values [SK: Nastavenie odporúčaných PHP hodnôt]
RUN { \
    echo 'memory_limit=512M'; \
    echo 'upload_max_filesize=100M'; \
    echo 'post_max_size=100M'; \
    echo 'max_execution_time=300'; \
    echo 'short_open_tag=On'; \
    echo 'date.timezone=Europe/Bratislava'; \
    } > /usr/local/etc/php/conf.d/churchcrm-limits.ini

WORKDIR /var/www/html
EXPOSE 80

# Entrypoint: auto-generates Config.php from env vars if missing
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Healthcheck [SK: Kontrola zdravia kontajnera]
HEALTHCHECK --interval=1m --timeout=3s --start-period=30s \
  CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
