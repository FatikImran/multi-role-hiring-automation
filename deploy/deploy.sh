#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: ./deploy.sh <your.domain.com> <email-for-lets-encrypt>"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"

echo "Preparing deployment for ${DOMAIN} (email: ${EMAIL})"

# Ensure Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin not found; continuing if 'docker compose' works with your Docker." 
fi

# Prepare .env
if [ ! -f .env ]; then
  cp .env.example .env
fi
sed -i "s/your.domain.com/${DOMAIN}/g" .env || true
sed -i "s/you@example.com/${EMAIL}/g" .env || true

# Render Caddyfile
sed "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g; s/EMAIL_PLACEHOLDER/${EMAIL}/g" Caddyfile.template > Caddyfile

echo "Setting up firewall (ufw) to allow SSH, HTTP, HTTPS..."
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow OpenSSH
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw enable || true
fi

echo "Starting services with docker compose..."
docker compose up -d --remove-orphans

echo "Deployment finished. Visit: https://${DOMAIN}"
echo "First-time TLS issuance by Caddy may take a moment."
