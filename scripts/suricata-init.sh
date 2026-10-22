#!/usr/bin/env bash
# Copie la configuration Suricata par défaut de l'image vers ${DATA_ROOT}/suricata/etc (une seule fois).
# Ne l'écrase jamais si suricata.yaml existe déjà (le test se fait dans le conteneur : DATA_ROOT est en 0750 root).
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
: "${DATA_ROOT:?}"

docker run --rm --entrypoint /bin/sh \
  -v "${DATA_ROOT}/suricata/etc:/out" \
  "jasonish/suricata:${SURICATA_TAG:-latest}" -c '
    if [ -f /out/suricata.yaml ]; then echo "Config Suricata déjà présente : rien à faire."; exit 0; fi
    src=/etc/suricata; [ -d /etc/suricata.dist ] && src=/etc/suricata.dist
    cp -a "$src"/. /out/ && echo "Config Suricata initialisée dans /out."'
