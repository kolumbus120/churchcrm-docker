# ChurchCRM 7.3.1 Docker (Modern)

Tento projekt poskytuje moderný a bezpečný Docker image pre [ChurchCRM](https://churchcrm.io) verziu 7.3.1.

## Čo je nové?
- **PHP 8.4 Apache**: Aktuálna verzia PHP vyžadovaná verziou 7.x.
- **Debian Bookworm**: Stabilný základ pre moderné knižnice.
- **Optimalizované rozšírenia**: Obsahuje `mysqli`, `intl`, `gd`, `gettext`, `zip`, `bcmath`.
- **Zabezpečenie**: Predkonfigurovaný Apache s povoleným `mod_rewrite`.

## Použitie s Docker Compose

```yaml
services:
  churchcrm:
    image: git.serigrafika.sk/thasko/churchcrm:7.3.1
    ports:
      - "8080:80"
    volumes:
      - ./data:/var/www/html
    environment:
      - MYSQL_DB_HOST=db
      - MYSQL_DB_NAME=churchcrm
      - MYSQL_DB_USER=churchcrm
      - MYSQL_DB_PASSWORD=your_pass
    depends_on:
      - db

  db:
    image: mariadb:11.4
    environment:
      - MYSQL_DATABASE=churchcrm
      - MYSQL_USER=churchcrm
      - MYSQL_PASSWORD=your_pass
      - MYSQL_ROOT_PASSWORD=root_pass
    volumes:
      - ./db:/var/lib/mysql
```

## Build príkazy
```bash
docker build -t git.serigrafika.sk/thasko/churchcrm:7.3.1 .
```
