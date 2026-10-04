#!/bin/bash
set -e

PERSISTENT_CONFIG="/var/www/html/config/Config.php"
ACTIVE_CONFIG="/var/www/html/Include/Config.php"

if [ ! -f "$PERSISTENT_CONFIG" ]; then
    # ConfigLoader rejects an empty DB password and the app redirects every page to
    # "Invalid URL" without CHURCHCRM_URL, so fail here with a clear message.
    for var in MYSQL_DB_PASSWORD CHURCHCRM_URL; do
        if [ -z "${!var:-}" ]; then
            echo "[ChurchCRM] $var is required but empty, cannot generate Config.php." >&2
            exit 1
        fi
    done

    echo "[ChurchCRM] Config.php not found, generating from environment variables..."
    mkdir -p /var/www/html/config
    # var_export() quotes and escapes the values, so a password containing
    # quotes, backslashes or $ cannot break out of the PHP string literal.
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
    chmod 640 "$PERSISTENT_CONFIG"
    echo "[ChurchCRM] Config.php generated."
fi

# ChurchCRM stores photos in Images/ (capital I). When it is a fresh bind mount or volume it
# hides the default assets (logos, login photo, Person/ and Family/), so seed it from the copy
# kept in the image. Existing files are never overwritten (--skip-old-files).
if [ -d /opt/churchcrm-Images.dist ]; then
    mkdir -p /var/www/html/Images 2>/dev/null || true
    (cd /opt/churchcrm-Images.dist && tar cf - .) \
        | tar xf - --skip-old-files -C /var/www/html/Images 2>/dev/null \
        || echo "[ChurchCRM] WARNING: could not populate /var/www/html/Images, check that it is writable by UID 33" >&2
fi

cp "$PERSISTENT_CONFIG" "$ACTIVE_CONFIG"
chmod 640 "$ACTIVE_CONFIG"

exec apache2-foreground
