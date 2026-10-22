#!/usr/bin/env bash
# Prépare l'hôte Debian 12 pour la stack. À lancer avec sudo (make init). Idempotent.
#  - dossiers de données avec les bons propriétaires
#  - réseau Docker partagé "edge" (sous-réseau fixe)
#  - journald persistant, auditd + règles, logrotate Suricata, règle ufw pour ntopng
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$(id -u)" -eq 0 ] || { echo "Lance ce script avec sudo (make init)."; exit 1; }
[ -f .env ] || { echo "Crée d'abord .env : cp .env.example .env && chmod 600 .env"; exit 1; }
set -a; . ./.env; set +a
: "${DATA_ROOT:?}" "${EDGE_SUBNET:?}" "${EDGE_GATEWAY:?}"

echo "==> Docker"
command -v docker >/dev/null || { echo "Docker absent : https://docs.docker.com/engine/install/debian/"; exit 1; }
docker compose version >/dev/null

echo "==> Dossiers de données dans ${DATA_ROOT}"
mk() { install -d -m "$4" -o "$2" -g "$3" "${DATA_ROOT}/$1"; }
mk .       0     0 0755
mk loki    10001 10001 0750   # utilisateur de l'image Loki
mk grafana 472   0 0750       # utilisateur de l'image Grafana
for d in alloy portainer diun suricata suricata/etc suricata/lib suricata/logs \
         backrest backrest/data backrest/config backrest/cache; do
  mk "$d" 0 0 0750
done

echo "==> Réseau Docker edge (${EDGE_SUBNET}, passerelle ${EDGE_GATEWAY})"
docker network inspect edge >/dev/null 2>&1 || \
  docker network create --driver bridge --subnet "${EDGE_SUBNET}" --gateway "${EDGE_GATEWAY}" edge

echo "==> journald persistant (pour que les logs SSH survivent aux redémarrages)"
install -d -m 2755 /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal || true
systemctl restart systemd-journald

echo "==> auditd + règles (crontab, systemd, sshd, sudoers)"
if ! command -v auditctl >/dev/null; then
  apt-get update -qq && apt-get install -y auditd
fi
install -m 0640 host/audit/50-infra.rules /etc/audit/rules.d/50-infra.rules
augenrules --load || echo "!! augenrules a signalé une erreur (règles immuables ? voir /etc/audit/rules.d)"

echo "==> logrotate Suricata"
sed "s#@DATA_ROOT@#${DATA_ROOT}#g" host/logrotate/suricata.tpl > /etc/logrotate.d/suricata-docker

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  echo "==> ufw : autorise Newt (réseau edge) -> ntopng sur la passerelle"
  ufw allow from "${EDGE_SUBNET}" to "${EDGE_GATEWAY}" port 3000 proto tcp comment 'edge -> ntopng'
fi

echo "OK. Étape suivante : make pangolin"
