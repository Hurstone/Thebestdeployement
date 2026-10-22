# Stack Pangolin (générée par l'installateur officiel)

Cette stack n'est volontairement **pas** écrite à la main : l'installateur officiel produit un
`docker-compose.yml` + `config/` (Pangolin, Gerbil, Traefik et, en option, CrowdSec) cohérents avec la version installée.

## Installation (première fois)
```bash
make pangolin            # télécharge l'installateur dans ce dossier
sudo ./installer         # réponds Oui à CrowdSec
```
Pendant l'installation, ouvre : 80/tcp, 443/tcp, 51820/udp et 21820/udp.

## Ce qui est versionné dans Git
- `docker-compose.yml` : oui (après relecture).
- `config/` : **non** (secrets : clé serveur Pangolin, clé API du bouncer CrowdSec, clés WireGuard). Ignoré par `.gitignore`,
  sauvegardé par Backrest.

## Redéploiement
Voir `docs/redeploy.md` : on restaure `config/` depuis la sauvegarde puis `docker compose up -d`
(on ne relance PAS l'installateur, sinon il régénère des secrets).

## Mise à jour
```bash
cd stacks/pangolin && docker compose pull && docker compose up -d
```
