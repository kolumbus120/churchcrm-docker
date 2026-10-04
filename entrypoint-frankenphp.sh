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

# Seed a fresh Images/ mount with the default assets (logos, login photo, Person/, Family/).
# Existing files are never overwritten (--skip-old-files).
if [ -d /opt/churchcrm-Images.dist ]; then
    mkdir -p /var/www/html/Images 2>/dev/null || true
    (cd /opt/churchcrm-Images.dist && tar cf - .) \
        | tar xf - --skip-old-files -C /var/www/html/Images 2>/dev/null \
        || echo "[ChurchCRM] WARNING: could not populate /var/www/html/Images, check that it is writable by UID 33" >&2
fi

cp "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"
chmod 640 "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"

# Runs as www-data (USER in the Dockerfile); Caddy listens on 8080, no extra capabilities
exec frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile
