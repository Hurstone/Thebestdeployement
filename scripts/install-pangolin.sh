#!/usr/bin/env bash
# Télécharge l'installateur officiel de Pangolin dans stacks/pangolin (interactif : on ne le lance pas à ta place).
set -euo pipefail
cd "$(dirname "$0")/../stacks/pangolin"

if [ -f docker-compose.yml ]; then
  echo "Pangolin est déjà installé ici (docker-compose.yml présent)."
  echo "Mise à jour : cd stacks/pangolin && docker compose pull && docker compose up -d"
  exit 0
fi

echo "==> Téléchargement de l'installateur officiel (static.pangolin.net)"
curl -fsSL https://static.pangolin.net/get-installer.sh | bash

cat <<MSG

Lance maintenant, dans $(pwd) :
    sudo ./installer

 - Réponds Oui à l'installation de CrowdSec.
 - À la fin, vérifie que docker-compose.yml et config/ sont bien dans ce dossier
   (certains guides indiquent /opt/pangolin : déplace-les ici si besoin, avant de les sauvegarder).
 - Crée ton compte admin, active la 2FA, puis crée un site "Docker" : note NEWT_ID / NEWT_SECRET pour .env.
MSG
