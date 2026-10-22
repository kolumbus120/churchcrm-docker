#!/bin/bash
set -e

PERSISTENT_CONFIG="/var/www/html/config/Config.php"
ACTIVE_CONFIG="/var/www/html/Include/Config.php"

# Config.php is generated only when MYSQL_DB_PASSWORD is set. Without it the container behaves
# like the upstream image (setup wizard at /setup).
if [ ! -f "$PERSISTENT_CONFIG" ] && [ -n "${MYSQL_DB_PASSWORD:-}" ]; then
    if [ -z "${CHURCHCRM_URL:-}" ]; then
        echo "[ChurchCRM] CHURCHCRM_URL is required when MYSQL_DB_PASSWORD is set." >&2
        exit 1
    fi
    echo "[ChurchCRM] Config.php not found, generating from environment variables..."
    mkdir -p "$(dirname "$PERSISTENT_CONFIG")"
    # var_export() quotes and escapes values, so special characters in the password are safe.
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
    chmod 600 "$PERSISTENT_CONFIG"
    echo "[ChurchCRM] Config.php generated."
fi

# Seed Images/ when it is a fresh volume/bind mount (existing files are never overwritten).
if [ -d /opt/churchcrm-Images.dist ]; then
    mkdir -p /var/www/html/Images 2>/dev/null || true
    (cd /opt/churchcrm-Images.dist && tar cf - .) \
        | tar xf - --skip-old-files -C /var/www/html/Images 2>/dev/null \
        || echo "[ChurchCRM] WARNING: could not populate /var/www/html/Images, check that it is writable by UID 33" >&2
fi

if [ -f "$PERSISTENT_CONFIG" ]; then
    cp "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"
    chmod 600 "$ACTIVE_CONFIG"
fi

exec "$@"
