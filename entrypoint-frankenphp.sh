#!/bin/bash
set -e

PERSISTENT_CONFIG="/var/www/html/config/Config.php"
ACTIVE_CONFIG="/var/www/html/Include/Config.php"

if [ ! -f "$PERSISTENT_CONFIG" ]; then
    echo "[ChurchCRM] Config.php not found, generating from environment variables..."
    mkdir -p /var/www/html/config
    cat > "$PERSISTENT_CONFIG" << CFG
<?php
\$sSERVERNAME = '${MYSQL_DB_HOST:-localhost}';
\$dbPort = '${MYSQL_DB_PORT:-3306}';
\$sUSER = '${MYSQL_DB_USER:-root}';
\$sPASSWORD = '${MYSQL_DB_PASSWORD:-}';
\$sDATABASE = '${MYSQL_DB_NAME:-churchcrm}';
\$sRootPath = '';
\$bLockURL = FALSE;
\$URL[0] = '${CHURCHCRM_URL:-}';
error_reporting(E_ERROR);
require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . 'LoadConfigs.php');
CFG
    echo "[ChurchCRM] Config.php generated."
fi

cp "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"
# Mounted volumes may be root-owned; PHP runs as www-data
chown -R www-data:www-data /var/www/html/config /var/www/html/images /var/www/html/backup /data /config 2>/dev/null || true
chown www-data:www-data "$ACTIVE_CONFIG"
chmod 640 "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"

# Drop privileges: Caddy listens on 8080, so no NET_BIND_SERVICE is needed
exec setpriv --reuid=www-data --regid=www-data --init-groups \
    frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile
