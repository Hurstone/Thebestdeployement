# Alertes Grafana → Discord

Le point de contact `discord-alerts` et la politique de notification sont provisionnés
(`stacks/observability/grafana/provisioning/alerting/`). Il reste à créer les règles :
Grafana › Alerting › Alert rules › New › source de données **Loki**, requête de type métrique,
condition « supérieur à 0 », évaluation toutes les 1 min, « pending » 0 à 2 min.

Ces requêtes sont des points de départ ; adapte les seuils après observation du bruit réel.

## Suricata : alertes de sévérité 1 (haute)
```
sum(count_over_time({job="suricata", event_type="alert"} | json | alert_severity="1" [5m]))
```

## Modification d'une crontab ou d'un timer/service systemd (auditd)
```
sum(count_over_time({job="auditd"} |= `key="cron"` [5m]))
sum(count_over_time({job="auditd"} |= `key="systemd_units"` [5m]))
```

## SSH
Échecs répétés (seuil à ajuster, ici > 20 en 5 min) :
```
sum(count_over_time({job="systemd-journal", unit="ssh.service"} |= "Failed password" [5m]))
```
Chaque connexion réussie (utile pour être prévenu de tout accès) :
```
sum(count_over_time({job="systemd-journal", unit="ssh.service"} |= "Accepted" [5m]))
```

## Modification de sshd_config, clés root, sudoers
```
sum(count_over_time({job="auditd"} |~ `key="(sshd_config|ssh_keys|sudoers)"` [5m]))
```

## Conteneur qui redémarre en boucle (via logs)
```
sum by (container) (count_over_time({job="docker"} |~ "(?i)panic|fatal" [5m]))
```

## Notes
- Les scans SSH et bannissements sont déjà notifiés par CrowdSec hôte (profil `host/crowdsec/profiles.yaml`).
- Diun envoie ses alertes de mise à jour dans le second webhook (`DISCORD_WEBHOOK_UPDATES`).
- La surveillance des processus/charge n'est pas dans Loki : ajoute Netdata ou node_exporter si besoin.
