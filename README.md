# ChurchCRM Docker

[![Docker Hub](https://img.shields.io/docker/pulls/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Docker Hub Stars](https://img.shields.io/docker/stars/kolumbus120/churchcrm.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Image Size](https://img.shields.io/docker/image-size/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Latest Version](https://img.shields.io/docker/v/kolumbus120/churchcrm/latest.svg)](https://hub.docker.com/r/kolumbus120/churchcrm)
[![Build Status](https://github.com/kolumbus120/churchcrm-docker/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/kolumbus120/churchcrm-docker/actions)

**Modern Docker image for [ChurchCRM](https://churchcrm.io) with automatic updates.**

This Docker image provides a fully functional ChurchCRM installation with:
- **PHP 8.4** + Apache with all required extensions
- **MariaDB 11.4** support (via docker-compose)
- **Auto-configuration** — no installer wizard needed, `Config.php` is generated automatically from environment variables
- **Automatic updates** when new ChurchCRM versions are released
- **Security patches** automatically applied from Docker Hub base images
- **Multi-architecture** support (amd64, arm64)

---

## 🚀 Quick Start

### Using Docker Run
```bash
docker run -d \
  --name churchcrm \
  -p 8080:80 \
  -e MYSQL_DB_HOST=mysql \
  -e MYSQL_DB_NAME=churchcrm \
  -e MYSQL_DB_USER=churchcrm \
  -e MYSQL_DB_PASSWORD=your_password \
  kolumbus120/churchcrm:latest
```

### Using Docker Compose
See [docker-compose.yml](docker-compose.yml) for a complete setup with MariaDB.

```bash
# Clone this repository
git clone https://github.com/kolumbus120/churchcrm-docker.git
cd churchcrm-docker

# Create .env file (copy from .env.example)
cp .env.example .env

# Edit .env with your credentials
nano .env

# Start containers
docker-compose up -d
```

Access ChurchCRM at: **http://localhost:8080**

---

## 📦 Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable version (auto-updates) |
| `7` | Latest 7.x version |
| `7.7.0` | Specific ChurchCRM version |

For all available tags, see: [Docker Hub Tags](https://hub.docker.com/r/kolumbus120/churchcrm/tags)

---

## 🔄 Automatic Updates

Every Tuesday and Friday at 11:00 UTC the pipeline checks two things and rebuilds if either changed:

1. **New ChurchCRM release** - a new version on GitHub that is not yet on Docker Hub
2. **PHP and OS security patches** - a new digest of the `php:8.4-apache` base image, which carries both PHP and Debian updates

If neither changed, no image is pushed — the digest of `:latest` stays the same, so Watchtower and friends will not restart your container for nothing.

### How to Get Updates

#### Option 1: Use `:latest` tag (recommended for testing)
```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm:latest
```

#### Option 2: Manual update (recommended for production)
```bash
# Pull new image
docker-compose pull churchcrm

# Recreate container with new image
docker-compose up -d --force-recreate
```

#### Option 3: Use Watchtower for automatic updates
```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm:latest
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_POLL_INTERVAL=86400 # Check every 24 hours
```

---

## 📊 Comparison with Official ChurchCRM Docker Image

| Feature | [churchcrm/crm](https://hub.docker.com/r/churchcrm/crm) | kolumbus120/churchcrm |
|---------|--------------------------------------------------------|------------------|
| PHP Version | 5.6 | **8.4** |
| Auto-updates | ❌ No | **✅ Yes** |
| Security Patches | ❌ No | **✅ Yes** |
| Multi-arch | ❌ No | **✅ Yes** (amd64, arm64) |
| Last Update | 2020 | **Twice weekly** |
| Maintenance | ❌ Abandoned | **✅ Active** |

---

## 📂 Project Structure

```
churchcrm-docker/
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Full setup with MariaDB
├── .env.example            # Environment variables template
├── README.md               # Project documentation
└── .github/workflows/
    └── build-and-push.yml  # GitHub Actions workflow
```

---

## 🛠️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_DB_HOST` | `churchcrm-db` | MySQL/MariaDB host |
| `MYSQL_DB_NAME` | `churchcrm` | Database name |
| `MYSQL_DB_USER` | `churchcrm` | Database user |
| `MYSQL_DB_PASSWORD` | - | Database password (required) |
| `MYSQL_DB_PORT` | `3306` | Database port |
| `MYSQL_ROOT_PASSWORD` | - | MySQL root password (required) |
| `CHURCHCRM_URL` | `` | **Required on first start.** Full URL of your ChurchCRM instance, must end with `/` (e.g. `https://crm.example.com/`) |
| `CHURCHCRM_ROOT_PATH` | `` | Subdirectory install path, e.g. `/churchcrm` (empty for a root install) |
| `CRM_TRUSTED_PROXY` | `172.16.0.0/12` | Reverse proxy IP/CIDR trusted for `X-Forwarded-For`, so audit logs show the real client IP |
| `CRM_SERVER_NAME` | `localhost` | Apache `ServerName` (silences the AH00558 warning) |

> **Security notes:** the container runs as non-root (`www-data`) and Apache still listens on port 80 (works because Docker defaults `net.ipv4.ip_unprivileged_port_start` to 0). Database passwords with quotes, backslashes or `$` are escaped correctly when `Config.php` is generated. If `MYSQL_DB_PASSWORD` or `CHURCHCRM_URL` is empty on first start the container exits with a clear error.

### Volumes (for persistent data)

For production use, you should mount volumes for persistent data:

```yaml
services:
  churchcrm:
    volumes:
      - ./data/config:/var/www/html/config
      - ./data/Images:/var/www/html/Images
      - ./data/backup:/var/www/html/backup
  churchcrm-db:
    volumes:
      - ./data/mysql:/var/lib/mysql
```

| Volume | Description | Recommended |
|--------|-------------|-------------|
| `/var/www/html/config/` | ChurchCRM configuration | ✅ Yes |
| `/var/www/html/Images/` | Uploaded photos (**capital `I`**, see note below) | ✅ Yes |
| `/var/www/html/backup/` | Backups | ⚠️ Optional |
| `/var/lib/mysql/` | MySQL/MariaDB data | ✅ Yes |

> **Important: the photo directory is `Images` with a capital `I`.** ChurchCRM writes member and family photos to `/var/www/html/Images`. Older versions of this README and the example compose files mounted `/var/www/html/images` (lowercase), which is a different directory on Linux, so uploaded photos lived only in the container and were lost when it was recreated (for example on every image update).
>
> **If you use the lowercase mount:** change it to `/var/www/html/Images`. On first start the image fills an empty `Images` mount with the default assets (logos, login photo, `Person/`, `Family/`) and never overwrites existing files. Photos uploaded earlier live inside the old container: before recreating it, copy them out with `docker cp <container>:/var/www/html/Images/. /path/to/Images/` (and `chown -R 33:33 /path/to/Images`).

---

## 📝 First Time Setup

### 1. Auto-configuration
The container **automatically generates** `Config.php` from environment variables on first start — no installation wizard needed.

1. Start the containers: `docker-compose up -d`
2. Open your browser at `http://localhost:8080`
3. Log in with the default credentials:
   - **Username:** `admin`
   - **Password:** `changeme`
4. Change the password immediately after first login

> ⚠️ The default credentials are set by ChurchCRM itself. Change them immediately after first login.

`Config.php` is saved to the persistent `config` volume, so it survives container restarts and image updates.

### 2. How it works
On every container start the entrypoint script:
1. Checks if `Config.php` exists in the `config` volume
2. If not → generates it from environment variables (`MYSQL_DB_HOST`, `MYSQL_DB_NAME`, etc.)
3. Copies it to the location ChurchCRM expects (`Include/Config.php`)
4. Starts Apache

---

## 🔧 Advanced Configuration

### Custom PHP Settings
You can override PHP settings by mounting a custom `php.ini` file:

```yaml
services:
  churchcrm:
    volumes:
      - ./custom-php.ini:/usr/local/etc/php/conf.d/custom.ini
```

### Custom Apache Configuration
To add custom Apache configuration:

```yaml
services:
  churchcrm:
    volumes:
      - ./custom-apache.conf:/etc/apache2/conf-available/custom.conf
```

Then enable it in your Dockerfile or entrypoint script.

---

### 🧪 Pre-release: `7.7.1-rc2` (non-root, port 8080)

`kolumbus120/churchcrm:7.7.1-rc2` is the hardened image with Apache listening on **8080** inside the container. It runs as non-root without any sysctl or capability, so it also works with `--cap-drop ALL`, `no-new-privileges`, Kubernetes and older Docker. This is the same approach as upstream ChurchCRM's own Dockerfile.

**Breaking change compared with `:latest`:** map your host port to container port **8080** instead of 80.

```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm:7.7.1-rc2
    ports:
      - '8080:8080'   # host:container, was '8080:80'
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

Pre-release tags are published only on request, never as `:latest`, `:7` or `:7.7.1`. Please report problems before this becomes the default.

## 🛡️ Security Hardening

The image has the following built-in protections:

| Protection | What it does |
|---|---|
| **Non-root** | The container runs as `www-data` (not root) and still listens on port 80. This works because Docker defaults `net.ipv4.ip_unprivileged_port_start` to 0 inside containers. |
| **No build toolchain** | Compiler and `-dev` packages are purged after the PHP extensions are built, so the final filesystem carries no gcc/make/headers. (Layers below still contain them, so the image does not get smaller.) |
| **Safe `Config.php` generation** | Database values are escaped with `var_export()`. A password containing quotes, backslashes or `$` cannot break the generated PHP file or inject code. |
| **Fail fast** | If `MYSQL_DB_PASSWORD` or `CHURCHCRM_URL` is empty on first start, the container exits with a clear error instead of failing later with a confusing "Invalid URL" page. |
| **Real client IP behind a proxy** | `mod_remoteip` takes the client IP from `X-Forwarded-For`, but only from proxies listed in `CRM_TRUSTED_PROXY`, so ChurchCRM audit logs record the member's IP and not the proxy's. A client cannot forge its IP by sending the header itself. |
| **HTTPS behind a proxy** | `X-Forwarded-Proto: https` is mapped to `HTTPS=on`. |
| **Verified release** | Built from the official ChurchCRM release zip, with the base image pinned by digest in CI. |

`CRM_TRUSTED_PROXY` defaults to `172.16.0.0/12` (Docker's default networks). Set it to your reverse proxy's IP or CIDR if it lives elsewhere, otherwise the logs keep showing the proxy address.

> **Credit:** several of these improvements (escaping the generated `Config.php`, failing fast on missing settings and trusting `X-Forwarded-For` only from known proxies) were inspired by [Dvalin21/churchcrm-docker](https://github.com/Dvalin21/churchcrm-docker) ([Docker Hub](https://hub.docker.com/r/dvalin21/churchcrm)), an independent community packaging of ChurchCRM. Thanks for the careful analysis. The non-root user and toolchain purge follow the approach in upstream ChurchCRM's own `docker/Dockerfile.churchcrm-apache-php8`.

---

### ⚠️ Upgrading to the non-root image (7.7.1 and newer)

Since the hardening release the container runs as `www-data` and Apache still listens on port 80. Please read this before pulling `:latest` on a production system:

- **Pin a version tag** (e.g. `kolumbus120/churchcrm:7.7.1`) instead of `:latest`, and do not let Watchtower auto-update a production instance without testing first. The previous image stays available as `kolumbus120/churchcrm:7.7.0` if you need to roll back.
- **Back up the database** (`mariadb-dump`) and the `config`, `images` and `backup` directories before upgrading.
- **Port 80 without root** relies on Docker setting `net.ipv4.ip_unprivileged_port_start=0` inside containers (the default since Docker 20.10). On older Docker, some NAS systems, Kubernetes or Podman setups Apache may fail with `AH00072: make_sock: could not bind to address 0.0.0.0:80`. Fix it by adding the sysctl:
  ```yaml
  services:
    churchcrm:
      sysctls:
        - net.ipv4.ip_unprivileged_port_start=0
  ```
  (or `docker run --sysctl net.ipv4.ip_unprivileged_port_start=0 ...`), or use the `7.7.1-rc2` variant above, which listens on 8080 and needs neither sysctl nor capabilities.
- **Bind-mounted directories** (`config`, `Images`, `backup`) must be writable by UID/GID 33 (`www-data`). If uploads fail after the upgrade, fix it on the host: `chown -R 33:33 /path/to/config /path/to/Images /path/to/backup`.
- **Language menu:** the Slovak entry now comes from the upstream release, so the menu shows "Slovak" instead of "Slovenčina - Slovak".

## 🛡️ Security Best Practices

1. **Always use specific tags** in production (not `:latest`)
2. **Backup your database** before upgrading
3. **Use strong passwords** for MySQL
4. **Keep your image updated** to receive security patches
5. **Use HTTPS** in production with a reverse proxy

### Example with Nginx Reverse Proxy
```yaml
services:
  churchcrm:
    image: kolumbus120/churchcrm:latest
    # ... other config
  
  nginx:
    image: nginx
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - /path/to/ssl/cert.pem:/etc/nginx/ssl/cert.pem
      - /path/to/ssl/key.pem:/etc/nginx/ssl/key.pem
    depends_on:
      - churchcrm
```

---

## 🐛 Troubleshooting

### Common Issues

#### White page / 500 error
```bash
# Check Apache logs
docker logs churchcrm-app

# Check PHP error log
docker exec churchcrm-app cat /var/log/apache2/error.log
```

#### Database connection failed
- Verify database container is running: `docker ps`
- Check database credentials in .env file
- Test connection: `docker exec churchcrm-app ping churchcrm-db`

#### Image not updating
```bash
# Force pull new image
docker-compose pull churchcrm

# Recreate container
docker-compose up -d --force-recreate
```

#### Permission issues
```bash
# Fix permissions (if using volumes)
docker exec churchcrm-app chown -R www-data:www-data /var/www/html
```

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/kolumbus120/churchcrm-docker).

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [ChurchCRM](https://churchcrm.io) - The original project
- [Dvalin21/churchcrm-docker](https://github.com/Dvalin21/churchcrm-docker) ([Docker Hub](https://hub.docker.com/r/dvalin21/churchcrm)) - ideas for safer config generation, fail-fast checks and trusted-proxy handling
- [Docker](https://docker.com) - Container platform
- [GitHub](https://github.com) - Git service
- [MariaDB](https://mariadb.org) - Database server
- [PHP](https://php.net) - Programming language

---

## 📞 Support

For support, please open an issue on [GitHub](https://github.com/kolumbus120/churchcrm-docker/issues).

---

**Maintained by:** [kolumbus120](https://github.com/kolumbus120)

*Last updated: 2026-10-04*
