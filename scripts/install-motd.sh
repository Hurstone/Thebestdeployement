#!/usr/bin/env bash
# Installe le tableau de bord infra-status et son affichage à la connexion SSH. Idempotent.
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$(id -u)" -eq 0 ] || { echo "Lance ce script avec sudo."; exit 1; }
repo="$(pwd)"

install -m 0755 host/motd/infra-status /usr/local/bin/infra-status
# Si le dépôt n'est pas dans /opt/infra, la copie installée pointe vers le bon chemin
sed -i "s#:-/opt/infra}#:-${repo}}#" /usr/local/bin/infra-status
install -m 0644 host/motd/profile-hook.sh /etc/profile.d/99-infra-motd.sh

echo "Installé. Teste avec : infra-status"
echo "Il s'affichera à la prochaine connexion SSH (désactivation : touch ~/.no-infra-motd)."
