# Rotation des logs Suricata (dossier monté dans le conteneur). @DATA_ROOT@ est remplacé par bootstrap-host.sh
@DATA_ROOT@/suricata/logs/*.log @DATA_ROOT@/suricata/logs/eve.json {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
