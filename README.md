# ChurchCRM Docker (Modernized)

Tento projekt poskytuje moderný a bezpečný Docker image pre [ChurchCRM](https://churchcrm.io) verziu 7.3.1, pripravený pre nasadenie na TrueNAS.

## Čo je nové?
- **PHP 8.4 Apache**: Aktuálna verzia PHP vyžadovaná najnovším zdrojovým kódom ChurchCRM.
- **MariaDB 11.4**: Moderná verzia databázy.
- **Debian Bookworm**: Stabilný základ pre moderné knižnice.
- **Optimalizované rozšírenia**: Obsahuje `mysqli`, `intl`, `gd`, `gettext`, `zip`, `bcmath`.
- **Zabezpečenie**: Predkonfigurovaný Apache s povoleným `mod_rewrite`.

## Gitea Registry
Image je dostupný v našej privátnej Gitea registry:
`git.serigrafika.sk/thasko/churchcrm-docker-modern:7.3.1`

## Nasadenie na TrueNAS (Custom App)

1. V TrueNAS UI choďte do **Apps** -> **Discover Apps** -> **Custom App**.
2. Použite YAML konfiguráciu zo súboru `deploy/truenas-custom-app.yaml`.
3. Upravte cesty k volume podľa vášho poolu (napr. `/mnt/pool/apps/churchcrm/db`).

## Build príkazy (lokálne)
```bash
docker build -t git.serigrafika.sk/thasko/churchcrm-docker-modern:7.3.1 .
docker push git.serigrafika.sk/thasko/churchcrm-docker-modern:7.3.1
```
