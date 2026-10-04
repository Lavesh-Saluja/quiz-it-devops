#!/bin/bash
set -euo pipefail

PROJECT_ID="project-dea1c03a-e235-4567-997"
IMAGE="__IMAGE__"

# Install Docker and the small set of tools needed by the bootstrap.
apt-get update
apt-get install -y --no-install-recommends \
  docker.io \
  docker-cli \
  curl \
  jq \
  ca-certificates
systemctl enable --now docker

# Get a Google access token using the VM's attached service account.
TOKEN="$(
  curl -sSf \
    -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" |
  jq -r '.access_token'
)"

# Read a secret from Secret Manager.
get_secret() {
  curl -sSf \
    -H "Authorization: Bearer ${TOKEN}" \
    "https://secretmanager.googleapis.com/v1/projects/${PROJECT_ID}/secrets/$1/versions/latest:access" |
  jq -r '.payload.data' |
  base64 -d
}

PG_PASSWORD="$(get_secret quizit-pg-password)"
SECRET_KEY_BASE="$(get_secret quizit-secret-key-base)"

# Runtime environment for Rails.
install -d -m 700 /run/quizit

cat > /run/quizit/quizit.env <<EOF_ENV
RAILS_ENV=production
PG_HOST=10.60.64.3
PG_PORT=5432
PG_USER=quizit
PG_PASSWORD=${PG_PASSWORD}
PG_DATABASE=quiz-it_production
PGSSLMODE=require
SECRET_KEY_BASE=${SECRET_KEY_BASE}
RAILS_LOG_TO_STDOUT=1
RAILS_SERVE_STATIC_FILES=1
EOF_ENV

chmod 600 /run/quizit/quizit.env

# Pull the exact immutable image.
docker pull "${IMAGE}"

# Start QuizIt.
docker rm -f quizit-web 2>/dev/null || true

docker run -d \
  --name quizit-web \
  --restart unless-stopped \
  --env-file /run/quizit/quizit.env \
  -p 3000:3000 \
  "${IMAGE}"
