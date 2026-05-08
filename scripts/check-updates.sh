#!/bin/bash
# Skript na manuálnu kontrolu aktualizácií
# Použitie: ./scripts/check-updates.sh

set -e

echo "🔍 Kontrola aktualizácií pre ChurchCRM Docker..."
echo ""

# 1. Skontroluj najnovšiu verziu ChurchCRM
 echo "1. ChurchCRM verzia:"
LATEST_CHURCHCRM=$(curl -s https://api.github.com/repos/ChurchCRM/CRM/releases/latest | jq -r '.tag_name' | sed 's/^v//')
CURRENT_CHURCHCRM=$(grep -oP 'CHURCHCRM_VERSION=\K[0-9.]+' Dockerfile || echo "7.3.1")

echo "   Aktuálna verzia v Dockerfile: $CURRENT_CHURCHCRM"
echo "   Najnovšia verzia na GitHub:   $LATEST_CHURCHCRM"

if [ "$CURRENT_CHURCHCRM" != "$LATEST_CHURCHCRM" ]; then
    echo "   ⚡ NOVÁ VERZIA DOSTUPNÁ!"
else
    echo "   ✅ Aktuálna"
fi

echo ""

# 2. Skontroluj PHP base image
 echo "2. PHP 8.4-apache base image:"
PHP_IMAGE="php:8.4-apache"
PHP_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $PHP_IMAGE 2>/dev/null | cut -d'@' -f2 || echo "unknown")

echo "   Aktuálny digest: $PHP_DIGEST"
echo "   💡 Pre skontrolovanie nového digesta: docker pull $PHP_IMAGE"

echo ""

# 3. Skontroluj MariaDB image
 echo "3. MariaDB 11.4 image:"
MARIADB_IMAGE="mariadb:11.4"
MARIADB_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $MARIADB_IMAGE 2>/dev/null | cut -d'@' -f2 || echo "unknown")

echo "   Aktuálny digest: $MARIADB_DIGEST"
echo "   💡 Pre skontrolovanie nového digesta: docker pull $MARIADB_IMAGE"

echo ""
echo "✨ Ak chceš rebuildnúť: docker-compose build --no-cache"
