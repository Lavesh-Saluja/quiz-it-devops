#!/bin/bash
set -euo pipefail

PROJECT_ID="project-dea1c03a-e235-4567-997"
IMAGE="__IMAGE__"

REDIS_HOST="10.60.67.155"
REDIS_PORT="6379"

apt-get update
apt-get install -y --no-install-recommends \
  docker.io \
  docker-cli \
  curl \
  jq \
  ca-certificates

systemctl enable --now docker

TOKEN="$(
  curl -sSf \
    -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" |
  jq -r '.access_token'
)"

get_secret() {
  curl -sSf \
    -H "Authorization: Bearer ${TOKEN}" \
    "https://secretmanager.googleapis.com/v1/projects/${PROJECT_ID}/secrets/$1/versions/latest:access" |
  jq -r '.payload.data' |
  base64 -d
}

PG_PASSWORD="$(get_secret quizit-pg-password)"
SECRET_KEY_BASE="$(get_secret quizit-secret-key-base)"
REDIS_PASSWORD="$(get_secret quizit-redis-password)"

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

REDIS_URL=redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/1

RAILS_LOG_TO_STDOUT=1
EOF_ENV

chmod 600 /run/quizit/quizit.env

echo "===== Pulling worker image ====="
docker pull "${IMAGE}"

docker rm -f quizit-worker 2>/dev/null || true

echo "===== Starting Sidekiq worker ====="

docker run -d \
  --name quizit-worker \
  --restart unless-stopped \
  --env-file /run/quizit/quizit.env \
  "${IMAGE}" \
  bundle exec sidekiq

echo "===== SIDEKIQ WORKER STARTED ====="
