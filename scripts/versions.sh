#!/usr/bin/env bash
# Affiche l'image et le digest de chaque conteneur actif : sert à figer les versions dans .env
set -euo pipefail
docker ps --format '{{.Names}}\t{{.Image}}' | sort | while IFS=$'\t' read -r name image; do
  digest=$(docker image inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$image" 2>/dev/null || true)
  printf '%-18s %-42s %s\n' "$name" "$image" "${digest:-?}"
done
