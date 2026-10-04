# ChurchCRM on FrankenPHP (EXPERIMENTAL)

Community-maintained variant of the `kolumbus120/churchcrm` image that runs on
[FrankenPHP](https://frankenphp.dev) (Caddy + PHP 8.4 in a single binary) instead of
Apache. **It has only been tested by the maintainer in a short local smoke test, not in
production.** The stable image is `kolumbus120/churchcrm:latest` (Apache).

Image: `kolumbus120/churchcrm:frankenphp` (amd64 only for now)

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
| Volumes `config`, `images`, `backup` | Persist `Config.php`, uploaded photos and backups. |
| TLS reverse proxy | The container speaks plain HTTP on **8080** (Caddy `auto_https` is off). Your proxy must send `X-Forwarded-Proto: https`; the image maps it to PHP's `HTTPS=on`. |

`CHURCHCRM_URL` is read from `.env` by the compose file (already wired in).

## Differences from the Apache image

- Listens on **8080** (runs as `www-data`, no `NET_BIND_SERVICE` needed), not 80.
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
`/api/public/echo`, `X-Forwarded-Proto` handling, non-root process.

NOT tested: anything after the forced password change (people, families, finance, plugins,
kiosk), photo upload, backup/restore, upgrades, arm64, running behind a real proxy,
subdirectory installs.

Please report problems at https://github.com/kolumbus120/churchcrm-docker/issues
