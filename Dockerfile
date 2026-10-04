# The CI resolves the current php:8.4-apache digest and pins it here, so the
# base.digest label below cannot drift from what was actually built.
ARG BASE_IMAGE=php:8.4-apache
FROM ${BASE_IMAGE}

# Metadata [SK: Metadáta obrazu]
ARG BASE_DIGEST=unknown
LABEL maintainer="kolumbus120 (with AI)"
LABEL description="Modernized ChurchCRM Docker image with PHP 8.4, Apache and automatic updates"
LABEL version="7.7.0"
LABEL org.opencontainers.image.base.name="php:8.4-apache"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"

# Install build dependencies, compile PHP extensions, then purge the toolchain so the
# final filesystem carries no compiler or -dev headers. Runtime libraries needed by
# the compiled extensions are marked manual first so the purge cannot remove them.
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl gettext locales locales-all unzip \
        libcurl4-openssl-dev libfreetype6-dev libicu-dev libjpeg-dev \
        libonig-dev libpng-dev libxml2-dev libzip-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath curl gd gettext intl mbstring mysqli pdo_mysql soap sockets xml zip; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    apt-mark manual curl gettext locales locales-all unzip; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | awk -F: '/^diversion/ { next } { print $1 }' | sort -u \
        | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get purge -y --auto-remove $PHPIZE_DEPS libc6-dev libc-dev-bin libcrypt-dev linux-libc-dev rpcsvc-proto || true; \
    rm -rf /var/lib/apt/lists/* /usr/src/php.tar.xz /usr/local/include/php

# Download and install ChurchCRM [SK: Stiahnutie a inštalácia ChurchCRM]
ARG CHURCHCRM_VERSION=7.7.0
ENV CHURCHCRM_VERSION=${CHURCHCRM_VERSION}
RUN curl -L -o /tmp/churchcrm.zip https://github.com/ChurchCRM/CRM/releases/download/${CHURCHCRM_VERSION}/ChurchCRM-${CHURCHCRM_VERSION}.zip \
    && unzip /tmp/churchcrm.zip -d /tmp/ \
    && rm -rf /var/www/html/* \
    && cp -R /tmp/churchcrm/* /var/www/html/ \
    && rm -rf /tmp/churchcrm /tmp/churchcrm.zip \
    && mkdir -p /var/www/html/config \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Slovak (sk_SK) ships natively in the release zip since 7.4.0, no patching needed.

# Enable Apache mod_rewrite and mod_remoteip. HTTPS is forwarded from the reverse proxy
# via X-Forwarded-Proto; the real client IP (used by ChurchCRM audit logs) is taken from
# X-Forwarded-For, but only from trusted proxies (CRM_TRUSTED_PROXY, default: Docker nets).
ENV CRM_TRUSTED_PROXY=172.16.0.0/12 \
    CRM_SERVER_NAME=localhost
RUN a2enmod rewrite remoteip \
    && echo 'SetEnvIf X-Forwarded-Proto "https" HTTPS=on' \
       > /etc/apache2/conf-available/reverse-proxy.conf \
    && printf 'RemoteIPHeader X-Forwarded-For\nRemoteIPTrustedProxy ${CRM_TRUSTED_PROXY}\nServerName ${CRM_SERVER_NAME}\n' \
       > /etc/apache2/conf-available/remoteip-proxy.conf \
    && a2enconf reverse-proxy remoteip-proxy \
    && chown -R www-data:www-data /var/run/apache2 /var/lock/apache2 /var/log/apache2

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

# Run as non-root. Port 80 still works because Docker defaults
# net.ipv4.ip_unprivileged_port_start to 0 inside containers.
USER www-data

# Healthcheck [SK: Kontrola zdravia kontajnera]
HEALTHCHECK --interval=1m --timeout=3s --start-period=30s \
  CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
