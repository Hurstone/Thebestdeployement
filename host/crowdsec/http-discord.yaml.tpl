# Plugin de notification "http" vers un webhook Discord. @DISCORD_WEBHOOK_URL@ est remplacé par le script d'installation.
type: http
name: http_discord
log_level: info
format: |
  {"content": "{{range . -}}{{range .Decisions -}}CrowdSec : **{{.Value}}** banni {{.Duration}} ({{.Scenario}}){{end}}{{end}}"}
url: @DISCORD_WEBHOOK_URL@
method: POST
headers:
  Content-Type: application/json
