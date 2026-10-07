#!/bin/bash
set -uo pipefail

PROJECT_ID="project-dea1c03a-e235-4567-997"
IMAGE="__IMAGE__"

STATUS_FILE="/run/quizit/migration-status"

# Install Docker and tools needed by the migration runner.
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
EOF_ENV

chmod 600 /run/quizit/quizit.env

echo "running" > "${STATUS_FILE}"

echo "===== Pulling migration image ====="
docker pull "${IMAGE}"

echo "===== Running Rails database migration ====="

if docker run --rm \
  --env-file /run/quizit/quizit.env \
  "${IMAGE}" \
  bundle exec rails db:migrate
then
  echo "success" > "${STATUS_FILE}"
  echo "===== DATABASE MIGRATION SUCCEEDED ====="
  exit 0
else
  echo "failed" > "${STATUS_FILE}"
  echo "===== DATABASE MIGRATION FAILED ====="
  exit 1
fi