# ChurchCRM Docker Hub Repository Overview

**Toto je Repository Description pre Docker Hub - kopíruj do polia "Full Description"**

---

[![Docker Pulls](https://img.shields.io/docker/pulls/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Docker Stars](https://img.shields.io/docker/stars/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Image Size](https://img.shields.io/docker/image-size/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Latest Version](https://img.shields.io/docker/v/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![PHP Version](https://img.shields.io/badge/php-8.4-blue.svg)](https://www.php.net)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

---

## Modern Docker image for ChurchCRM

**The free, open-source church management system with automatic updates.**

This image provides a complete, production-ready ChurchCRM installation with all required dependencies pre-installed and configured.

---

## Features

- **PHP 8.4** with Apache web server
- **All required PHP extensions** for ChurchCRM:
  - pdo, pdo_mysql, mysqli, curl, fileinfo, filter, gd, gettext, iconv, mbstring, bcmath, zip, zlib, session, intl
- **Auto-configuration** — no installer wizard needed, `Config.php` is generated automatically from environment variables on first start
- **Automatic updates** via CI/CD pipeline:
  - New ChurchCRM versions (daily check at 2:00 UTC)
  - PHP security patches (from Docker Hub base image)
  - OS security updates
- **Multi-architecture** support (amd64, arm64)
- **Optimized PHP settings** (memory_limit=512M, upload_max_filesize=100M)
- **Persistent volumes** for configuration, images, and backups
- **Mod_rewrite** enabled for clean URLs

---

## Quick Start

### Using Docker Run
```bash
docker run -d \
  --name churchcrm \
  -p 8080:80 \
  -v churchcrm_config:/var/www/html/config \
  -v churchcrm_images:/var/www/html/images \
  -v churchcrm_backup:/var/www/html/backup \
  -e MYSQL_DB_HOST=my-mariadb \
  -e MYSQL_DB_NAME=churchcrm \
  -e MYSQL_DB_USER=churchcrm \
  -e MYSQL_DB_PASSWORD=your_password \
  kolumbus120/churchcrm:latest
```

### Using Docker Compose
```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm:latest
    container_name: churchcrm-app
    restart: unless-stopped
    ports:
      - '8080:80'
    environment:
      - MYSQL_DB_HOST=churchcrm-db
      - MYSQL_DB_NAME=churchcrm
      - MYSQL_DB_USER=churchcrm
      - MYSQL_DB_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - churchcrm_config:/var/www/html/config
      - churchcrm_images:/var/www/html/images
      - churchcrm_backup:/var/www/html/backup
    depends_on:
      churchcrm-db:
        condition: service_healthy

  churchcrm-db:
    image: mariadb:11.4
    container_name: churchcrm-db
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=churchcrm
      - MYSQL_USER=churchcrm
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - churchcrm_db:/var/lib/mysql

volumes:
  churchcrm_config:
  churchcrm_images:
  churchcrm_backup:
  churchcrm_db:
```

Access ChurchCRM at: **http://localhost:8080**

---

## Available Tags

| Tag | Description | Architecture |
|-----|-------------|--------------|
| `latest` | Latest stable version (auto-updates) | amd64, arm64 |
| `7` | Latest 7.x version | amd64, arm64 |
| `7.3.1` | Specific ChurchCRM version | amd64, arm64 |

---

## Automatic Updates

This image is **automatically rebuilt and pushed** in the following cases:

1. New ChurchCRM release - Pipeline checks GitHub releases daily at 2:00 UTC
2. PHP security patches - Base image (php:8.4-apache) auto-updates on Docker Hub
3. OS security patches - Debian Bookworm base receives automatic updates

---

## Comparison with Official ChurchCRM Docker Image

| Feature | churchcrm/crm | kolumbus120/churchcrm |
|---------|---------------|------------------|
| PHP Version | 5.6 (EOL) | **8.4** (Latest) |
| Auto-updates | No | **Yes** (Daily) |
| Security Patches | No | **Yes** |
| Multi-arch | No | **Yes** (amd64, arm64) |
| All PHP Extensions | Missing some | **All required** |
| Last Update | 2020 | **Daily** |
| Maintenance | Abandoned | **Active** |

---

## Configuration

### Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| MYSQL_DB_HOST | churchcrm-db | Yes | Database host |
| MYSQL_DB_NAME | churchcrm | Yes | Database name |
| MYSQL_DB_USER | churchcrm | Yes | Database user |
| MYSQL_DB_PASSWORD | - | Yes | Database password |
| MYSQL_DB_PORT | 3306 | No | Database port |
| MYSQL_ROOT_PASSWORD | - | Yes | MySQL root password |
| CHURCHCRM_URL | - | No | Full URL of your instance, must end with `/` (e.g. `https://crm.example.com/`) |

### Volumes

| Volume Mount | Description | Recommended |
|--------------|-------------|-------------|
| /var/www/html/config | ChurchCRM configuration | **Yes** |
| /var/www/html/images | Uploaded member photos and images | **Yes** |
| /var/www/html/backup | ChurchCRM backups | Yes |
| /var/lib/mysql | MariaDB database data | **Yes** |

Docker creates named volumes automatically on first start. Use bind mounts if you prefer a specific host path:
```yaml
volumes:
  - /your/path/config:/var/www/html/config
  - /your/path/images:/var/www/html/images
  - /your/path/backup:/var/www/html/backup
  - /your/path/db:/var/lib/mysql
```

---

## Security

- Non-root user (www-data) for application
- Proper file permissions (755 for directories, 644 for files)
- PHP memory limits set to 512M
- Upload limits set to 100M

**For production, always:**
- Use HTTPS with a reverse proxy
- Set strong MySQL passwords
- Keep image updated
- Backup your database and volumes

---

## Getting Started

1. Start the containers: `docker-compose up -d`
2. Open your browser to http://your-server:8080
3. Log in with the default credentials:
   - **Username:** `admin`
   - **Password:** `changeme`
4. Change the password immediately after first login

On first start, the entrypoint script automatically generates `Config.php` from your environment variables and saves it to the persistent `config` volume. On every subsequent start (including after image updates), the config is reloaded from the volume — no reconfiguration needed.

---

## License

This project is open source and available under the [MIT License](https://opensource.org/licenses/MIT).

---

## Support

For support, please open an issue on [GitHub](https://github.com/kolumbus120/churchcrm-docker/issues).

---

**Maintained by:** [kolumbus120](https://github.com/kolumbus120)
