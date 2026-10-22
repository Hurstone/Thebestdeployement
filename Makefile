.RECIPEPREFIX := >
SHELL   := /bin/bash
COMPOSE := docker compose --env-file $(CURDIR)/.env

# Ordre de déploiement (Pangolin est installé à part : make pangolin)
STACKS := newt portainer observability ntopng suricata diun backup

.PHONY: help init pangolin up down pull ps config versions suricata-init suricata-rules

help: ## Affiche cette aide
> @grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*## "}{printf "  %-16s %s\n", $$1, $$2}'
> @echo "  up-<stack>       Démarre une stack (ex: make up-observability)"
> @echo "  down-<stack>     Arrête une stack"

init: ## Prépare l'hôte : dossiers, réseau edge, auditd, journald (sudo)
> sudo -E ./scripts/bootstrap-host.sh

pangolin: ## Télécharge l'installateur officiel de Pangolin
> ./scripts/install-pangolin.sh

config: ## Valide la syntaxe de toutes les stacks
> @for s in $(STACKS); do echo "== $$s"; $(COMPOSE) -f stacks/$$s/compose.yaml config -q || exit 1; done

up: $(addprefix up-,$(STACKS)) ## Démarre toutes les stacks (hors Pangolin) dans l'ordre

down: ## Arrête toutes les stacks (ordre inverse)
> @for s in $$(echo $(STACKS) | tr ' ' '\n' | tac); do $(COMPOSE) -f stacks/$$s/compose.yaml down; done

pull: ## Télécharge les images de toutes les stacks
> @for s in $(STACKS); do $(COMPOSE) -f stacks/$$s/compose.yaml pull; done

ps: ## Liste les conteneurs
> @docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

versions: ## Affiche images + digests en cours d'exécution (pour figer les versions)
> @./scripts/versions.sh

suricata-init: ## Initialise la config Suricata dans DATA_ROOT (première fois)
> @./scripts/suricata-init.sh

suricata-rules: ## Met à jour les règles Suricata et les recharge
> docker exec suricata suricata-update
> docker exec suricata suricatasc -c reload-rules

up-suricata: suricata-init

up-%:
> $(COMPOSE) -f stacks/$*/compose.yaml up -d

down-%:
> $(COMPOSE) -f stacks/$*/compose.yaml down
