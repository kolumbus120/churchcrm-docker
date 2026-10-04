# ChurchCRM on FrankenPHP (EXPERIMENTAL)

[![Docker Pulls](https://img.shields.io/docker/pulls/kolumbus120/churchcrm-frankenphp.svg)](https://hub.docker.com/r/kolumbus120/churchcrm-frankenphp) [![Docker Stars](https://img.shields.io/docker/stars/kolumbus120/churchcrm-frankenphp.svg)](https://hub.docker.com/r/kolumbus120/churchcrm-frankenphp) [![Image Size](https://img.shields.io/docker/image-size/kolumbus120/churchcrm-frankenphp/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm-frankenphp) [![Latest Version](https://img.shields.io/docker/v/kolumbus120/churchcrm-frankenphp/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm-frankenphp) [![PHP Version](https://img.shields.io/badge/php-8.4-blue.svg)](https://www.php.net) [![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

> ⚠️ **Experimental, community-maintained, not used in production.** It has only been
> smoke-tested locally. For a stable setup use
> [`kolumbus120/churchcrm`](https://hub.docker.com/r/kolumbus120/churchcrm) (Apache).
> Unofficial: not affiliated with the ChurchCRM project.

[ChurchCRM](https://github.com/ChurchCRM/CRM) on [FrankenPHP](https://frankenphp.dev)
(Caddy + PHP 8.4 in a single binary) instead of Apache. Built from the official release
zip, multi-architecture (`amd64`, `arm64`).

Source, Dockerfile and issues: https://github.com/kolumbus120/churchcrm-docker
(branch `feature/frankenphp`, docs in `FRANKENPHP.md`)

## Tags

| Tag | Meaning |
|---|---|
| `latest` | newest build, follows the latest ChurchCRM release |
| `<version>` (e.g. `7.7.1`) | pinned ChurchCRM version, **use this in production** |

## Quick start

`.env`:

```bash
MYSQL_USER=churchcrm
MYSQL_PASSWORD=change-me
MYSQL_ROOT_PASSWORD=change-me-too
CHURCHCRM_URL=http://localhost:8080/
```

`docker-compose.yml`:

```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm-frankenphp:latest
    restart: unless-stopped
    ports:
      - '8080:8080'
    environment:
      - MYSQL_DB_HOST=churchcrm-db
      - MYSQL_DB_NAME=churchcrm
      - MYSQL_DB_USER=${MYSQL_USER}
      - MYSQL_DB_PASSWORD=${MYSQL_PASSWORD}
      - CHURCHCRM_URL=${CHURCHCRM_URL}
    volumes:
      - churchcrm_config:/var/www/html/config
      - churchcrm_images:/var/www/html/images
      - churchcrm_backup:/var/www/html/backup
    depends_on:
      churchcrm-db:
        condition: service_healthy

  churchcrm-db:
    image: mariadb:11.4
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=churchcrm
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      retries: 5
    volumes:
      - churchcrm_db:/var/lib/mysql

volumes:
  churchcrm_config:
  churchcrm_images:
  churchcrm_backup:
  churchcrm_db:
```

```bash
docker compose up -d
```

Open `http://localhost:8080/` and sign in as `admin` / `changeme`. You are forced to change
the password on first login. The database schema is created automatically.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `MYSQL_DB_HOST` | `localhost` | Database host |
| `MYSQL_DB_PORT` | `3306` | Database port |
| `MYSQL_DB_NAME` | `churchcrm` | Database name |
| `MYSQL_DB_USER` | `root` | Database user |
| `MYSQL_DB_PASSWORD` | - | **Required** on first start |
| `CHURCHCRM_URL` | - | **Required** on first start. Public URL ending with `/`, e.g. `https://crm.example.com/`. Without it ChurchCRM redirects every page to "Invalid URL". |
| `CHURCHCRM_ROOT_PATH` | empty | Subdirectory path. Subdirectory installs are not supported by the bundled Caddyfile. |

`Config.php` is generated from these variables only on first start and then kept in the
`config` volume. If a required variable is empty, the container exits with a clear error.
Values with quotes, backslashes or `$` are escaped correctly.

## Volumes

| Path | Content |
|---|---|
| `/var/www/html/config` | generated `Config.php` |
| `/var/www/html/images` | uploaded photos |
| `/var/www/html/backup` | backups |

## Reverse proxy and HTTPS

The container speaks plain HTTP on **8080** and runs as a non-root user. Put a TLS reverse
proxy in front of it and send `X-Forwarded-Proto: https`; the image maps it to PHP's
`HTTPS=on`. Caddy's automatic HTTPS is disabled.

## Differences from the Apache image

- Port **8080** instead of 80.
- Caddy ignores `.htaccess`. Routing and all deny rules (`/Include`, `/logs`, `/tmp_attach`,
  dotfiles, PHP in `plugins/` and `Images/`) are in the bundled Caddyfile and must be kept
  in sync with upstream security fixes by hand.
- Every ChurchCRM sub-app (`session`, `api`, `v2`, `admin`, `finance`, `kiosk`, `plugins`,
  `external`, `setup`) is routed explicitly, otherwise login ends in a redirect loop.

## Tested / not tested

Tested: first start, login, logout and re-login, redirect loop check, deny rules, public
API, `X-Forwarded-Proto`, non-root process, passwords with special characters.

**Not tested:** anything after the forced password change (people, families, finance,
plugins, kiosk), photo upload, backup/restore, upgrades, behind a real reverse proxy,
subdirectory installs. Please report problems on GitHub.

## License

ChurchCRM is MIT licensed, Copyright (c) 2023 ChurchCRM. This image only packages the
unmodified release.
