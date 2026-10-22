# Redéployer toute la stack

## Ce qui doit être sauvegardé (hors serveur)
| Quoi | Où | Pourquoi |
|---|---|---|
| `.env` | `${INFRA_DIR}/.env` | secrets (webhooks, Newt, mot de passe Grafana) ; garde aussi une copie dans un gestionnaire de mots de passe |
| `stacks/pangolin/config/` | `${INFRA_DIR}` | secrets Pangolin, clé CrowdSec, base SQLite (utilisateurs, ressources, politiques) |
| `${DATA_ROOT}` | hôte | Grafana, Portainer, Backrest, Diun, config Suricata (exclure `loki/` : reconstructible) |
| Identifiants du dépôt restic | gestionnaire de mots de passe | sans eux, impossible de restaurer |

Le dépôt Git, lui, contient tout le reste (compose, configs, scripts).

## Base SQLite de Pangolin (cohérence)
Copier une base SQLite en cours d'écriture peut donner une copie incohérente. Avant chaque sauvegarde,
fais une copie propre depuis l'hôte (installe `sqlite3`), p. ex. via un cron quelques minutes avant le plan Backrest :
```bash
sqlite3 /opt/infra/stacks/pangolin/config/db/db.sqlite ".backup '/opt/infra/stacks/pangolin/config/db/db.backup.sqlite'"
```
(Le chemin exact du fichier est à vérifier dans `stacks/pangolin/config/`.)

## Nouveau serveur : procédure
1. Socle : Debian, Docker, SSH, pare-feu (80, 443, 51820/udp, 21820/udp), **DNS** : fais pointer `pangolin.<domaine>` et `*.<domaine>` vers la nouvelle IP.
2. `git clone <dépôt> /opt/infra` et remets `.env` en place (`chmod 600`).
3. **Restaure les données en root, avant `make init`** (les propriétaires sont conservés) :
   ```bash
   sudo apt install restic
   export RESTIC_REPOSITORY=...   # ton dépôt distant
   export RESTIC_PASSWORD=...
   restic restore latest --target /tmp/restore
   sudo rsync -a /tmp/restore/userdata/data/  /srv/infra-data/
   sudo rsync -a /tmp/restore/userdata/infra/stacks/pangolin/config/ /opt/infra/stacks/pangolin/config/
   ```
   (les chemins `userdata/...` viennent des montages du conteneur Backrest.)
4. `make init`
5. Pangolin : **n'exécute pas l'installateur**. Récupère `docker-compose.yml` (déjà dans Git) et lance :
   ```bash
   cd stacks/pangolin && docker compose up -d
   ```
6. `make up` (Newt se reconnecte avec les identifiants de `.env`), puis `sudo ./scripts/install-crowdsec-host.sh`.
7. Contrôles : `make ps`, Grafana › Explore, test Discord, accès aux ressources Pangolin.

## Si tu n'as pas de sauvegarde de `stacks/pangolin/config/`
Il faut réinstaller Pangolin (`make pangolin` + installateur) et recréer utilisateurs, site Newt (nouveaux `NEWT_ID`/`NEWT_SECRET`) et ressources.
D'où l'importance du test de restauration.

## Mise à jour d'une stack
```bash
make pull && make up         # toutes les stacks
make up-observability        # une seule
cd stacks/pangolin && docker compose pull && docker compose up -d
```
