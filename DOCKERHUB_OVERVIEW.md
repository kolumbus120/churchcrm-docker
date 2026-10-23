# ChurchCRM Docker Hub Repository Overview

---

[![Docker Pulls](https://img.shields.io/docker/pulls/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm) [![Docker Stars](https://img.shields.io/docker/stars/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm) [![Image Size](https://img.shields.io/docker/image-size/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm) [![Latest Version](https://img.shields.io/docker/v/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm) [![PHP Version](https://img.shields.io/badge/php-8.4-blue.svg)](https://www.php.net) [![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

---

> **⚠️ Port change since 7.7.1:** the container listens on **8080** (not 80). Change your mapping from `host:80` to `host:8080`. See *Upgrading* below.

## ChurchCRM Docker image with environment-based configuration

**Community image for [ChurchCRM](https://github.com/ChurchCRM/CRM), the free, open-source church management system.** Not affiliated with the ChurchCRM project.

### Relationship to the official image

Since ChurchCRM 7.8.0 the project publishes its own image, [`churchcrm/crm`](https://hub.docker.com/r/churchcrm/crm). **The `<version>-official` tags here (e.g. `7.8.1-official`) are that official image plus a thin layer** ([source](https://github.com/kolumbus120/churchcrm-docker/blob/main/Dockerfile.upstream)). The ChurchCRM code, PHP build and Apache setup are unchanged and come from upstream. The layer adds only:

| Added on top of `churchcrm/crm` | Why |
|---|---|
| `Config.php` generated from environment variables (`MYSQL_DB_*`, `CHURCHCRM_URL`) | no setup wizard and no bind-mounted config file; without `MYSQL_DB_PASSWORD` it behaves like upstream and shows the wizard |
| `upload_max_filesize` / `post_max_size` 100M, `memory_limit` 512M, `max_execution_time` 300, timezone Europe/Bratislava | upstream ships 2M upload, 256M memory, UTC |
| Whole `Images/` can be a volume (defaults are copied in on start) | upstream asks you to mount only `Images/Person` and `Images/Family` |
| `X-Forwarded-Proto` → HTTPS and `mod_remoteip` (real client IP from `X-Forwarded-For`, trusted proxies via `CRM_TRUSTED_PROXY`) | running behind a reverse proxy |
| Healthcheck inside the image | upstream defines it only in its compose file |

If you do not need any of that, use `churchcrm/crm` directly.

The older plain tags (`latest`, `7`, `7.x.y`) are a separate, self-built image of the same ChurchCRM release (PHP 8.4 + Apache, built from the release zip). It has the same additions as above (they were the reason for this image before an official one existed), but it is built by us from the release zip rather than on top of the official image. New deployments should prefer `-official`.

---

## Features

- **PHP 8.4** with Apache web server
- **All required PHP extensions** for ChurchCRM:
  - pdo, pdo_mysql, mysqli, curl, fileinfo, filter, gd, gettext, iconv, mbstring, bcmath, zip, zlib, session, intl
- **Auto-configuration** — no installer wizard needed, `Config.php` is generated automatically from environment variables on first start
- **Automatic updates** via CI/CD pipeline, checked every Tuesday and Friday at 11:00 UTC:
  - New ChurchCRM versions
  - PHP and OS security patches (rebuilt when the php:8.4-apache base image changes)
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
  -p 8080:8080 \
  -v churchcrm_config:/var/www/html/config \
  -v churchcrm_images:/var/www/html/Images \
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
      - '8080:8080'
    environment:
      - MYSQL_DB_HOST=churchcrm-db
      - MYSQL_DB_NAME=churchcrm
      - MYSQL_DB_USER=churchcrm
      - MYSQL_DB_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - churchcrm_config:/var/www/html/config
      - churchcrm_images:/var/www/html/Images
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
| `7.8.1` | Specific ChurchCRM version | amd64, arm64 |
| `7.8.1-official` | Same image as `7.8.1`: the official `churchcrm/crm:7.8.1-php8-apache` + thin layer (see above). Published together with every plain version tag | amd64, arm64 |

Since 7.8.1 the plain tags (`latest`, `7`, `7.x.y`) are built on the official image as well. Earlier versions were built from the release zip.

### Old tags will be removed

**Tags older than 7.6.0 (`7.3.1` to `7.5.1`) will be deleted from Docker Hub on 1 January 2027.** Releases move quickly and almost everyone should be on a recent version; running the latest one gives you the security fixes. Tags from `7.6.0` onwards stay for now.

- If you pin one of the old tags, change it to a current one (`7.8.1`, or `latest` / `7`) before that date. After removal `docker pull` of the old tag fails.
- You can jump over several versions: the database schema is upgraded automatically on first start (checked going from 7.7.1 to 7.8.1). **Back up the database and the `config`, `Images` and `backup` volumes first**, and read the ChurchCRM release notes if you skip many versions.
- Pre-release tags such as `7.7.1-rc2` and `7.7.1-rc3` are test builds and will be removed earlier, without notice.

-----|-------------|--------------|
| `latest` | Latest stable version (auto-updates) | amd64, arm64 |
| `7` | Latest 7.x version | amd64, arm64 |
| `7.7.0` | Specific ChurchCRM version | amd64, arm64 |
| `<version>-official` | **Recommended.** Official `churchcrm/crm:<version>-php8-apache` + thin layer (see above), e.g. `7.8.1-official`. Published manually, never moves `latest` | amd64, arm64 |

---

## Automatic Updates

Every Tuesday and Friday at 11:00 UTC the pipeline checks two things and rebuilds if either changed:

1. New ChurchCRM release - a new version on GitHub that is not yet on Docker Hub
2. PHP and OS security patches - a new digest of the php:8.4-apache base image, which carries both PHP and Debian Bookworm updates

If neither changed, nothing is pushed and the digest of `latest` stays the same, so watchtower-style updaters will not restart your container for nothing. The base image digest each build was made from is recorded in the `org.opencontainers.image.base.digest` label.

---

## Comparison with the Official ChurchCRM Docker Image

Since ChurchCRM 7.8.0 there is an official image, [`churchcrm/crm`](https://hub.docker.com/r/churchcrm/crm) (`<version>-php8-apache`). It is also non-root, listens on 8080 and has the release code baked in.

| Feature | `churchcrm/crm` (official) | `kolumbus120/churchcrm` (this repo) |
|---------|---------------|------------------|
| Base | PHP 8.4, Apache, multi-stage, digest-pinned | PHP 8.4, Apache; `<version>-official` tags are built on the official image |
| User / port | `www-data`, 8080 | `www-data`, 8080 |
| `Config.php` | Setup wizard, then bind-mount the file to keep it | **Generated from environment variables** (wizard still available when no password is set) |
| `upload_max_filesize` | 2M | **100M** (memory 512M, timezone Europe/Bratislava) |
| `Images/` as a volume | Mount only `Images/Person` and `Images/Family` | **Whole `Images/` can be a volume**, defaults are seeded on start |
| Reverse proxy | None | `X-Forwarded-Proto` and `mod_remoteip` |
| Healthcheck | Defined in compose only | Built into the image |
| Releases | Each ChurchCRM release | Same; plain tags (`latest`, `7`, `7.x.y`) are built separately from the release zip, `-official` tags on demand |

If you do not need the extras above, the official image is a fine choice. Back up the database before switching between images; the database schema is upgraded automatically on first start.

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
| CHURCHCRM_URL | - | Yes (first start) | Full URL of your instance, must end with `/` (e.g. `https://crm.example.com/`) |
| CHURCHCRM_ROOT_PATH | - | No | Subdirectory install path, e.g. `/churchcrm` |
| CRM_TRUSTED_PROXY | 172.16.0.0/12 | No | Reverse proxy IP/CIDR trusted for `X-Forwarded-For` (real client IP in logs) |
| CRM_SERVER_NAME | localhost | No | Apache `ServerName` |

### Volumes

| Volume Mount | Description | Recommended |
|--------------|-------------|-------------|
| /var/www/html/config | ChurchCRM configuration | **Yes** |
| /var/www/html/Images | Uploaded member photos and images (**capital I**, a lowercase `images` mount does not persist them). Seeded with the default assets on first start | **Yes** |
| /var/www/html/backup | ChurchCRM backups | Yes |
| /var/lib/mysql | MariaDB database data | **Yes** |

Docker creates named volumes automatically on first start. Use bind mounts if you prefer a specific host path:
```yaml
volumes:
  - /your/path/config:/var/www/html/config
  - /your/path/images:/var/www/html/Images
  - /your/path/backup:/var/www/html/backup
  - /your/path/db:/var/lib/mysql
```

---

## Upgrading to 7.7.1 and newer (port change)

**Important: the container now listens on 8080 instead of 80** and runs as non-root (`www-data`). If your compose file or `docker run` maps `host:80`, change it to `host:8080`, e.g. `-p 8080:8080` or `'8080:8080'`. The host port stays whatever you want; your reverse proxy keeps pointing at the same host port.

- Pin a version tag (e.g. `7.7.1`) in production, avoid unattended auto-updates, back up the database and `config`/`Images`/`backup` first.
- Roll back with `:7.7.0` (it listens on port 80, so switch the port back as well).
- Bind-mounted `config`, `Images` and `backup` directories must be writable by UID/GID 33 (`chown -R 33:33 ...`).
- Mount photos at `/var/www/html/Images` (**capital I**).
- Works with `security_opt: [no-new-privileges:true]` and `cap_drop: [ALL]`; no sysctl needed.
- Pre-release tags (e.g. `7.7.1-rc3`) are published only on request, never as `latest`, `7` or the plain version.

---

## Security

- Runs as non-root (`www-data`) on the unprivileged port 8080, no capabilities or sysctl needed
- No compiler or `-dev` packages in the final filesystem
- `Config.php` is generated with proper escaping (passwords with quotes, backslashes or `$` are safe)
- Fails fast with a clear message if `MYSQL_DB_PASSWORD` or `CHURCHCRM_URL` is empty
- Real client IP in ChurchCRM audit logs behind a reverse proxy (`mod_remoteip`, trusted only from `CRM_TRUSTED_PROXY`, default `172.16.0.0/12`)
- `X-Forwarded-Proto: https` is mapped to `HTTPS=on`
- Built from the official release zip, base image pinned by digest

Credit: escaping, fail-fast checks and trusted-proxy handling were inspired by [Dvalin21/churchcrm-docker](https://github.com/Dvalin21/churchcrm-docker) ([Docker Hub](https://hub.docker.com/r/dvalin21/churchcrm)).

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
