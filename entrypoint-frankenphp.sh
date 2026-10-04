#!/bin/bash
set -e

PERSISTENT_CONFIG="/var/www/html/config/Config.php"
ACTIVE_CONFIG="/var/www/html/Include/Config.php"

if [ ! -f "$PERSISTENT_CONFIG" ]; then
    for var in MYSQL_DB_PASSWORD CHURCHCRM_URL; do
        if [ -z "${!var:-}" ]; then
            echo "[ChurchCRM] $var is required but empty, cannot generate Config.php." >&2
            exit 1
        fi
    done

    echo "[ChurchCRM] Config.php not found, generating from environment variables..."
    mkdir -p /var/www/html/config
    # var_export() escapes the values, so quotes, backslashes or $ in a password
    # cannot break out of the PHP string literal.
    php -r '
        $q = function (string $k, string $d = ""): string {
            $v = getenv($k);
            return var_export(($v === false || $v === "") ? $d : $v, true);
        };
        $php = "<?php\n"
            . "\$sSERVERNAME = " . $q("MYSQL_DB_HOST", "localhost") . ";\n"
            . "\$dbPort = " . $q("MYSQL_DB_PORT", "3306") . ";\n"
            . "\$sUSER = " . $q("MYSQL_DB_USER", "root") . ";\n"
            . "\$sPASSWORD = " . $q("MYSQL_DB_PASSWORD") . ";\n"
            . "\$sDATABASE = " . $q("MYSQL_DB_NAME", "churchcrm") . ";\n"
            . "\$sRootPath = " . $q("CHURCHCRM_ROOT_PATH") . ";\n"
            . "\$bLockURL = FALSE;\n"
            . "\$URL[0] = " . $q("CHURCHCRM_URL") . ";\n"
            . "error_reporting(E_ERROR);\n"
            . "require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . \x27LoadConfigs.php\x27);\n";
        if (file_put_contents("/var/www/html/config/Config.php", $php) === false) {
            fwrite(STDERR, "[ChurchCRM] could not write Config.php\n");
            exit(1);
        }
    '
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
