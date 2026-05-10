#!/bin/bash
set -e

PERSISTENT_CONFIG="/var/www/html/config/Config.php"
ACTIVE_CONFIG="/var/www/html/Include/Config.php"

if [ ! -f "$PERSISTENT_CONFIG" ]; then
    echo "[ChurchCRM] Config.php not found, generating from environment variables..."
    mkdir -p /var/www/html/config
    cat > "$PERSISTENT_CONFIG" << EOF
<?php
\$sSERVERNAME = '${MYSQL_DB_HOST:-localhost}';
\$dbPort = '${MYSQL_DB_PORT:-3306}';
\$sUSER = '${MYSQL_DB_USER:-root}';
\$sPASSWORD = '${MYSQL_DB_PASSWORD:-}';
\$sDATABASE = '${MYSQL_DB_NAME:-churchcrm}';
\$sRootPath = '';
\$bLockURL = FALSE;
\$URL[0] = '';
error_reporting(E_ERROR);
require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . 'LoadConfigs.php');
EOF
    chown www-data:www-data "$PERSISTENT_CONFIG"
    chmod 640 "$PERSISTENT_CONFIG"
    echo "[ChurchCRM] Config.php generated."
fi

cp "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"
chown www-data:www-data "$ACTIVE_CONFIG"
chmod 640 "$ACTIVE_CONFIG"

exec apache2-foreground
