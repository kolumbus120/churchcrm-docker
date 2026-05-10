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
| `7.3.1` | Specific ChurchCRM version |

For all available tags, see: [Docker Hub Tags](https://hub.docker.com/r/kolumbus120/churchcrm/tags)

---

## 🔄 Automatic Updates

This image is **automatically updated** in the following cases:

1. **New ChurchCRM release** - Pipeline checks GitHub releases daily and rebuilds with the latest version
2. **PHP security patches** - Base image (php:8.4-apache) is automatically updated on Docker Hub
3. **OS security patches** - Debian base image receives automatic security updates

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
| Last Update | 2020 | **Daily** |
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

### Volumes (for persistent data)

For production use, you should mount volumes for persistent data:

```yaml
services:
  churchcrm:
    volumes:
      - ./data/config:/var/www/html/config
      - ./data/images:/var/www/html/images
      - ./data/backup:/var/www/html/backup
  churchcrm-db:
    volumes:
      - ./data/mysql:/var/lib/mysql
```

| Volume | Description | Recommended |
|--------|-------------|-------------|
| `/var/www/html/config/` | ChurchCRM configuration | ✅ Yes |
| `/var/www/html/images/` | Uploaded images | ✅ Yes |
| `/var/www/html/backup/` | Backups | ⚠️ Optional |
| `/var/lib/mysql/` | MySQL/MariaDB data | ✅ Yes |

---

## 📝 First Time Setup

### 1. Auto-configuration
The container **automatically generates** `Config.php` from environment variables on first start — no installation wizard needed.

1. Start the containers: `docker-compose up -d`
2. Open your browser at `http://localhost:8080`
3. ChurchCRM is ready to use

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
- [Docker](https://docker.com) - Container platform
- [GitHub](https://github.com) - Git service
- [MariaDB](https://mariadb.org) - Database server
- [PHP](https://php.net) - Programming language

---

## 📞 Support

For support, please open an issue on [GitHub](https://github.com/kolumbus120/churchcrm-docker/issues).

---

**Maintained by:** [kolumbus120](https://github.com/kolumbus120)

*Last updated: 2026-05-10*
