# Infra : Pangolin + supervision

Dépôt « source de vérité » pour (re)déployer toute la stack sur un serveur Debian 12.

| Rôle | Outil | Accès |
|---|---|---|
| Reverse proxy + accès par identité (webgui) | **Pangolin** (Traefik + Gerbil, + CrowdSec bouncer) | 80/443 + WireGuard |
| Connecteur local | **Newt** | réseau `edge` |
| Gestion des conteneurs | **Portainer** | via Pangolin |
| Logs + alertes | **Loki + Alloy + Grafana** | Grafana via Pangolin |
| Analyse de trafic | **ntopng** (mode host) | via Pangolin (passerelle `edge`) |
| IDS | **Suricata** (mode host, IDS) | logs → Loki |
| Brute-force / scans SSH | **CrowdSec** (hôte) | alertes Discord |
| Mises à jour d'images | **Diun** | alertes Discord |
| Sauvegardes | **Backrest** (restic) | via Pangolin |

## Arborescence
```
infra/
├── .env.example            # variables (copie en .env, jamais committé)
├── Makefile                # make init / pangolin / up / down / config / versions ...
├── scripts/                # bootstrap hôte, install Pangolin, CrowdSec hôte, utilitaires
├── host/                   # fichiers installés sur l'hôte (auditd, logrotate, CrowdSec)
├── docs/                   # redeploy.md, alerting.md
└── stacks/
    ├── pangolin/           # généré par l'installateur officiel (README seulement dans Git)
    ├── newt/compose.yaml
    ├── portainer/compose.yaml
    ├── observability/      # compose.yaml + loki/ alloy/ grafana/provisioning/
    ├── ntopng/compose.yaml
    ├── suricata/compose.yaml
    ├── diun/compose.yaml
    └── backup/compose.yaml
```

## Ordre d'installation
1. **Socle** : Debian à jour, SSH durci (ton port), pare-feu (ouvrir 80/tcp, 443/tcp, 51820/udp, 21820/udp + ton port SSH), Docker + Compose, DNS (`pangolin.<domaine>` + wildcard `*.<domaine>` vers le serveur).
2. `git clone <ton dépôt> /opt/infra && cd /opt/infra && cp .env.example .env && chmod 600 .env` puis remplis `.env` (webhooks Discord, mot de passe Grafana, domaines…).
3. `make init` : dossiers de données, réseau `edge`, journald persistant, auditd, logrotate.
4. `make pangolin` puis `sudo ./installer` (dans `stacks/pangolin`, **Oui à CrowdSec**). Compte admin + 2FA. Crée un **site Docker** → copie `NEWT_ID` / `NEWT_SECRET` dans `.env`.
5. `make up-newt up-portainer`, puis crée les ressources Pangolin (tableau ci-dessous). Portainer est alors joignable avec authentification.
6. `make up-observability` (Loki, Alloy, Grafana → alertes Discord prêtes).
7. `sudo ./scripts/install-crowdsec-host.sh` (SSH : scans, brute-force, bannissements).
8. `make up-ntopng`, puis `make up-suricata` (initialise la config ; règle `HOME_NET`, voir plus bas).
9. `make up-diun`.
10. `make up-backup` : configure le dépôt **hors serveur** et les plans. Fais **un test de restauration**.

`make up` enchaîne 5→10 (hors CrowdSec hôte) une fois `.env` complet.

## Ressources à créer dans Pangolin
Site : le site Docker (Newt). Type HTTP, authentification Pangolin activée sur chacune.

| Service | Cible (depuis Newt) |
|---|---|
| Portainer | `http://portainer:9000` |
| Grafana | `http://grafana:3000` |
| Backrest | `http://backrest:9898` |
| ntopng | `http://172.30.0.1:3000` (= `EDGE_GATEWAY`, ntopng est en mode host) |

Loki, Alloy, Suricata, Diun ne sont **jamais** exposés.

## Réglages après le premier démarrage
- **ntopng** : login `admin`/`admin` → change le mot de passe. Pour une 2e interface (ex. interface VPN) : ajoute `-i <iface>` dans `command`.
- **Suricata** : dans `${DATA_ROOT}/suricata/etc/suricata.yaml`, mets `HOME_NET` à l'IP publique du serveur ; dans `outputs → eve-log → types`, garde `alert` (et `anomaly`) pour limiter le volume. Puis `make suricata-rules`. Prévois une phase de tri des faux positifs.
- **Grafana** : crée les règles d'alerte (requêtes dans `docs/alerting.md`) ; le point de contact Discord est déjà provisionné.
- **Versions** : après validation, `make versions` et fige les tags/digests dans `.env`. Diun te prévient ensuite des nouveautés.

## Points d'attention
- **Fichier non testé sur serveur** : syntaxe validée, comportement réel à vérifier au premier déploiement (voir « À vérifier » ci-dessous).
- **CrowdSec ×2** : celui de Pangolin (HTTP/Traefik) et celui de l'hôte (SSH) sont indépendants. Vérifie qu'ils ne se disputent pas le port 8080 de l'hôte (`ss -tlnp | grep 8080`) ; si besoin, change `listen_uri` du CrowdSec hôte (`/etc/crowdsec/config.yaml`, `local_api_credentials.yaml` et la config du bouncer).
- **Bannissements et Docker** : le bouncer pare-feu de l'hôte protège l'hôte (SSH). Les ports publiés par Docker (80/443…) contournent ces règles : c'est le bouncer Traefik de Pangolin qui les protège.
- **Socket Docker** : Portainer, Alloy et Diun montent `docker.sock` (`:ro` n'empêche pas les abus). Pour durcir plus tard : un proxy de socket en lecture seule pour Alloy et Diun.
- **Boucle de dépendance** : n'héberge pas ton futur fournisseur d'identité (Authentik/Pocket ID) derrière Pangolin lui-même.
- **Reste à couvrir** : surveillance des processus/charge (Netdata ou node_exporter), non incluse ici.

## À vérifier au premier déploiement
- Suricata : `${DATA_ROOT}/suricata/etc/suricata.yaml` existe et `eve.json` se remplit.
- Alloy : `docker logs alloy` sans erreur ; dans Grafana › Explore, `{job="docker"}` renvoie des lignes.
- Alerte de test Discord depuis Grafana (Contact points › Test).
- CrowdSec hôte : message de test avec `cscli notifications test http_discord`.
- Où l'installateur Pangolin a écrit `docker-compose.yml` et `config/`.
