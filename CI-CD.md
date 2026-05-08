# CI/CD Pipeline - Návod

Tento dokument popisuje, ako funguje automatický CI/CD pipeline pre ChurchCRM Docker image.

---

## 🎯 **Ciele**

1. **Automatické aktualizácie ChurchCRM** - Ak vyjde nová verzia na GitHub, pipeline ju automaticky zohladní
2. **Automatické bezpečnostné opravy** - Base images (PHP, Apache) sa táhnu z Docker Hub, kde sa automaticky aktualizujú
3. **Multi-platform support** - Images sa buildia pre `linux/amd64` a `linux/arm64`
4. **Dostupnosť pre komunitu** - Images sa pushujú na Gitea Registry a Docker Hub

---

## 🔧 **Ako to funguje**

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTOMATICKÝ PROCES                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Spustí sa každý deň o 2:00 UTC                         │
│      ↓                                                      │
│  2. Skontroluje najnovšiu verziu ChurchCRM na GitHub        │
│      ↓                                                      │
│  3. Rebuildne Docker image s najnovšou verziou             │
│      ↓                                                      │
│  4. Pushne na Gitea Registry a Docker Hub                   │
│      ↓                                                      │
│  5. Užívateľ má k dispozícii nové tags:                     │
│     - :latest (vždy najnovšia verzia)                       │
│     - :7.3.1 (konkrétna verzia ChurchCRM)                   │
│     - :2024-05-15 (dátum buildu)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 **Vytvorené súbory**

```
churchcrm-docker-modern/
├── .gitea/workflows/
│   └── build-and-push.yml      # Gitea Actions workflow
├── .github/workflows/
│   └── build-and-push.yml      # GitHub Actions workflow (fallback)
├── scripts/
│   └── check-updates.sh        # Manuálna kontrola aktualizácií
└── Dockerfile                  # Upravený pre ARG CHURCHCRM_VERSION
```

---

## ⚙️ **Nastavenie Secrets**

### Pre **Gitea Actions**

1. Prejdi do svojho Gitea repozitáru
2. Choď do **Settings → Actions → Secrets**
3. Vytvor nasledujúce secrets:

| Secret | Popis | Príklad |
|--------|-------|---------|
| `GITEA_REGISTRY` | URL Gitea registry | `git.serigrafika.sk` |
| `GITEA_USER` | Tvoje Gitea username | `thasko` |
| `GITEA_TOKEN` | Access token s právami `write:package` | `*****` |
| `DOCKER_HUB_USER` | Tvoje Docker Hub username | `thasko` |
| `DOCKER_HUB_TOKEN` | Docker Hub access token | `*****` |

#### **Ako vygenerovať Gitea Token**
1. Gitea → User Settings → Applications
2. Vytvor nový token
3. Vyber práva: `read:repository`, `write:package`
4. Skopíruj token a ulož ho ako `GITEA_TOKEN`

#### **Ako vygenerovať Docker Hub Token**
1. Docker Hub → Account Settings → Security
2. New Access Token
3. Vyber práva: Read/Write
4. Skopíruj token a ulož ho ako `DOCKER_HUB_TOKEN`

---

## 🚀 **Spustenie Pipeline**

### **Automaticky**
- Pipeline sa spustí **každý deň o 2:00 UTC**
- Spustí sa tiež pri **push do main branch** (ak sa zmení Dockerfile)

### **Manuálne**
1. Gitea/GitHub → **Actions**
2. Vyber workflow **Build and Push Docker Image**
3. Klikni na **Run workflow**
4. Potvrď spustenie

---

## 📦 **Dostupné Docker Tags**

Po úspešnom builde sú dostupné nasledujúce tags:

### **Gitea Registry**
```
git.serigrafika.sk/thasko/churchcrm-docker-modern:latest
git.serigrafika.sk/thasko/churchcrm-docker-modern:7.3.1    # Verzia ChurchCRM
git.serigrafika.sk/thasko/churchcrm-docker-modern:2024-05-15 # Dátum buildu
```

### **Docker Hub** (pre komunitu)
```
thasko/churchcrm:latest
thasko/churchcrm:7.3.1
thasko/churchcrm:2024-05-15
```

---

## 🔄 **Ako sa aktualizujú komponenty**

| Komponent | Zdroj | Aktualizácia |
|-----------|-------|--------------|
| **ChurchCRM** | GitHub Releases | ⚡ Automicky (pipeline získa najnovšiu verziu) |
| **PHP 8.4 + Apache** | Docker Hub | ⚡ Automicky (base image sa aktualizuje na Docker Hub) |
| **MariaDB 11.4** | Docker Hub | ⚡ Automicky (v docker-compose.yml) |
| **OS (Debian)** | Docker Hub | ⚡ Automicky (v base image) |

---

## 💡 **Ako používať aktuálne verzie**

### **Pre užívateľov (TrueNAS, docker-compose)**

#### **Stabilná verzia (odporúčané)**
```yaml
services:
  churchcrm:
    image: thasko/churchcrm:7.3.1  # Konkrétna verzia
```

#### **Automatické aktualizácie (pre testovanie)**
```yaml
services:
  churchcrm:
    image: thasko/churchcrm:latest  # Vždy najnovšia
```

#### **Denne aktualizácie (s Watchtower)**
```yaml
services:
  churchcrm:
    image: thasko/churchcrm:latest
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_POLL_INTERVAL=86400
```

---

## ⚠️ **Dôležité poznámky**

### **1. Base Images (PHP, MariaDB)**
- Oficiálne Docker Hub images sa **automaticky rebuildnú** pri bezpečnostných opravách
- Tvoj pipeline **každý deň rebuildne** tvoj image, čím získa nové base images
- Užívateľ dostane novú verziu pri `docker pull`

### **2. ChurchCRM Updates**
- Pipeline **automaticky detekuje** novú verziu z GitHub
- Ak vyjde ChurchCRM 7.3.2, pipeline rebuildne image s touto verziou
- Užívateľ må **manuálne pullnúť** novú verziu (alebo použiť `:latest`)

### **3. Rollback**
Ak nová verzia spôsobí problémy:
```bash
# Späť na starú verziu
docker pull thasko/churchcrm:7.3.1
docker-compose up -d
```

---

## 📊 **Monitorovanie**

### **Skontrolovať dostupné verzie**
```bash
# Zobraziť všetky tags na Docker Hub
docker search thasko/churchcrm --filter is-official=true

# Zobraziť históriu buildov
curl -s https://hub.docker.com/v2/repositories/thasko/churchcrm/tags/?page_size=25 | jq '.results[].name'
```

### **Manuálna kontrola aktualizácií**
```bash
# Spustiť skript
chmod +x scripts/check-updates.sh
./scripts/check-updates.sh
```

---

## 🎓 **Best Practices pre komunitu**

1. **Vždy používaj konkrétne tags** (nie `:latest`) pre produkciu
2. **Testuj nove verzie** na staging serveri pred deployom do produkcie
3. **Monitoruj CVE** - Pipeline neoznamuje bezpečnostné problémy, len rebuildne
4. **Zálohuj databázu** pred aktualizáciou ChurchCRM
5. **Dokumentuj breaking changes** - Ak sa zmení major verzia (7.x → 8.x), upovedom užívateľov

---

## 🔗 **Použité technológie**

- **Gitea Actions** - CI/CD platforma
- **Docker Buildx** - Multi-platform builds
- **GitHub API** - Pre získanie najnovšej verzie ChurchCRM
- **Docker Hub** - Registry pre komunitu
- **Gitea Registry** - Privátna registry

---

## 📞 **Podpora**

Ak máš problémy:
1. Skontroluj logs v Gitea/GitHub Actions
2. Skontroluj, či sú secrets správne nastavené
3. Spusti pipeline manuálne a sleduj chyby
4. Použi `docker build --no-cache .` pre testovanie lokálne
