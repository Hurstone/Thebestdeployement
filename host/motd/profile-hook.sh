# Installé dans /etc/profile.d/99-infra-motd.sh : affiche infra-status à l'ouverture d'une session SSH interactive.
# Désactiver pour un utilisateur : touch ~/.no-infra-motd
[ -n "${SSH_TTY:-}" ] || return 0
[ -z "${INFRA_STATUS_SHOWN:-}" ] || return 0
[ ! -e "${HOME:-/nonexistent}/.no-infra-motd" ] || return 0
[ -x /usr/local/bin/infra-status ] || return 0
export INFRA_STATUS_SHOWN=1
/usr/local/bin/infra-status
