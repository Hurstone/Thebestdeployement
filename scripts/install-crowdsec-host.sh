#!/usr/bin/env bash
# CrowdSec côté HÔTE : détecte les scans / brute-force SSH (journald), bannit via nftables, alerte sur Discord.
# (Le CrowdSec de Pangolin, lui, protège le trafic HTTP passant par Traefik.)
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$(id -u)" -eq 0 ] || { echo "Lance ce script avec sudo."; exit 1; }
[ -f .env ] || { echo "Crée d'abord .env"; exit 1; }
set -a; . ./.env; set +a
: "${DISCORD_WEBHOOK_ALERTS:?Renseigne DISCORD_WEBHOOK_ALERTS dans .env}"

echo "==> Dépôt officiel CrowdSec + paquets (agent + bouncer pare-feu nftables)"
curl -fsSL https://install.crowdsec.net | sh
apt-get install -y crowdsec crowdsec-firewall-bouncer-nftables

echo "==> Collections et acquisition SSH (journald)"
cscli collections install crowdsecurity/sshd crowdsecurity/linux
install -D -m 0644 host/crowdsec/acquis-ssh.yaml /etc/crowdsec/acquis.d/ssh.yaml

echo "==> Notification Discord"
install -d -m 0755 /etc/crowdsec/notifications
sed "s#@DISCORD_WEBHOOK_URL@#${DISCORD_WEBHOOK_ALERTS}#" host/crowdsec/http-discord.yaml.tpl \
  > /etc/crowdsec/notifications/http.yaml
chown root:root /etc/crowdsec/notifications/http.yaml
chmod 0600 /etc/crowdsec/notifications/http.yaml
[ -f /etc/crowdsec/profiles.yaml.orig ] || cp /etc/crowdsec/profiles.yaml /etc/crowdsec/profiles.yaml.orig
install -m 0644 host/crowdsec/profiles.yaml /etc/crowdsec/profiles.yaml

systemctl restart crowdsec
echo "==> Vérifications : cscli metrics ; cscli bouncers list ; ss -tlnp | grep 8080"
echo "    (si le CrowdSec de Pangolin publie aussi le port 8080 sur l'hôte, change l'un des deux : voir README)"
