# ChurchCRM on FrankenPHP (EXPERIMENTAL)

Community-maintained variant of the `kolumbus120/churchcrm` image (published separately as `kolumbus120/churchcrm-frankenphp`) that runs on
[FrankenPHP](https://frankenphp.dev) (Caddy + PHP 8.4 in a single binary) instead of
Apache. **It has only been tested by the maintainer in a short local smoke test, not in
production.** The stable image is `kolumbus120/churchcrm:latest` (Apache).

Image: `kolumbus120/churchcrm-frankenphp` (tags `latest` and `<version>`, amd64 + arm64)  
Docker Hub: https://hub.docker.com/r/kolumbus120/churchcrm-frankenphp

## Quick start

```bash
# .env
MYSQL_USER=churchcrm
MYSQL_PASSWORD=change-me
MYSQL_ROOT_PASSWORD=change-me-too
CHURCHCRM_URL=http://localhost:8080/
```

```bash
docker compose -f docker-compose.frankenphp.yml up -d
```

Open `http://localhost:8080/` and log in as `admin` / `changeme` (you are forced to change
the password). The database schema is created automatically on first start.

## What you must set

| Setting | Why |
|---|---|
| `CHURCHCRM_URL` (env) | The public URL, e.g. `https://crm.example.com/`. If empty, ChurchCRM redirects every page to `config-error.php?error=Invalid+URL`. |
| `MYSQL_DB_HOST/NAME/USER/PASSWORD` (env) | Database connection. `Config.php` is generated from these only on first start. |
| Volumes `config` (`/var/www/html/config`) and `Images` (`/var/www/html/Images`, **capital I**) | Persist `Config.php` and uploaded photos. ChurchCRM writes photos to `Images/`; a lowercase `images` mount does not persist them. |
| TLS reverse proxy | The container speaks plain HTTP on **8080** (Caddy `auto_https` is off). Your proxy must send `X-Forwarded-Proto: https`; the image maps it to PHP's `HTTPS=on`. |

`CHURCHCRM_URL` is read from `.env` by the compose file (already wired in).

## Security model

- The image runs as **`www-data` (UID/GID 33) from the first process**: `USER www-data` in the
  Dockerfile, no root entrypoint, no `chown`/`setpriv` at start. It therefore works with
  `--user`, Kubernetes `runAsNonRoot`, `--cap-drop ALL` and `no-new-privileges`.
- Caddy listens on **8080**, so no `NET_BIND_SERVICE` or sysctl is needed. The file capability
  the base image puts on the `frankenphp` binary is removed at build time, otherwise the binary
  cannot start under `--cap-drop ALL`.
- Named volumes inherit the image's ownership. **Bind mounts must be writable by UID/GID 33**:
  `chown -R 33:33 /path/to/config /path/to/Images`.
- `Config.php` is generated with proper escaping, and the container exits with a clear error if
  `MYSQL_DB_PASSWORD` or `CHURCHCRM_URL` is empty.

## Differences from the Apache image

- Listens on **8080**, not 80.
- `.htaccess` is ignored by Caddy. All routing and deny rules (`/Include`, `/logs`,
  `/tmp_attach`, dotfiles, PHP in `plugins/` and `Images/`) live in `frankenphp/Caddyfile`
  and must be kept in sync with upstream security fixes by hand.
- Each ChurchCRM sub-app (`session`, `api`, `v2`, `admin`, `finance`, `kiosk`, `plugins`,
  `external`, `setup`) is routed explicitly. Without that you get a redirect loop
  (see ChurchCRM/CRM#8405).
- Subdirectory installs (`/churchcrm`) are NOT supported in this Caddyfile. See the
  upstream example `docker/examples/frankenphp/Caddyfile` in ChurchCRM/CRM.

## Tested / not tested

Tested locally: first start, login, logout + re-login, redirect-loop check, deny rules,
`/api/public/echo`, `X-Forwarded-Proto` handling, non-root process (`USER www-data`, also with `--cap-drop ALL` and `no-new-privileges`), persistence of `Config.php` across container recreation.

NOT tested: anything after the forced password change (people, families, finance, plugins,
kiosk), photo upload, backup/restore, upgrades, arm64, running behind a real proxy,
subdirectory installs.

Please report problems at https://github.com/kolumbus120/churchcrm-docker/issues
