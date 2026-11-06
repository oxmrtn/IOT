#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONUS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFESTS_DIR="${BONUS_DIR}/manifests"
CONFS_DIR="${BONUS_DIR}/confs"

GITLAB_PORT="8082"
GITLAB_CONTAINER="gitlab"
PROJECT_NAME="wil-playground"
GITLAB_URL="http://localhost:${GITLAB_PORT}"
TOKEN="glpat-bonus-token-iot-42"

if [ ! -d "${MANIFESTS_DIR}" ] || [ ! -f "${CONFS_DIR}/application.yaml" ]; then
    exit 1
fi

mkdir -p "$HOME/gitlab/config" "$HOME/gitlab/logs" "$HOME/gitlab/data"

if ! docker ps -a --format '{{.Names}}' | grep -q "^${GITLAB_CONTAINER}$"; then
    docker run --detach \
      --name "$GITLAB_CONTAINER" \
      --hostname gitlab.local \
      --network k3d-iot-cluster \
      --publish "${GITLAB_PORT}:80" \
      --publish 2222:22 \
      --restart always \
      --volume "$HOME/gitlab/config:/etc/gitlab" \
      --volume "$HOME/gitlab/logs:/var/log/gitlab" \
      --volume "$HOME/gitlab/data:/var/opt/gitlab" \
      --shm-size 256m \
      gitlab/gitlab-ce:latest
fi

until docker exec "$GITLAB_CONTAINER" grep -q "Password:" /etc/gitlab/initial_root_password 2>/dev/null; do
    echo "..."
    sleep 5
done

until curl -s -o /dev/null -w "%{http_code}" "${GITLAB_URL}/users/sign_in" | grep -q "200"; do
    echo "..."
    sleep 5
done

ROOT_PASSWORD=$(docker exec "$GITLAB_CONTAINER" grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')

docker exec -i "$GITLAB_CONTAINER" bash << 'EOF'
cat << 'RUBY' > /tmp/create_token.rb
user = User.find_by_username('root')
old_token = user.personal_access_tokens.find_by(name: 'bonus-token')
old_token.destroy if old_token

token = user.personal_access_tokens.create(
  name: 'bonus-token',
  scopes: ['api', 'read_repository', 'write_repository'],
  expires_at: 365.days.from_now
)
token.set_token('glpat-bonus-token-iot-42')
token.save!
RUBY
gitlab-rails runner /tmp/create_token.rb
rm -f /tmp/create_token.rb
EOF

curl --silent --header "PRIVATE-TOKEN: ${TOKEN}" \
     --data "name=${PROJECT_NAME}&visibility=public" \
     "${GITLAB_URL}/api/v4/projects" >/dev/null || true

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
git init -b main
git config user.name "root"
git config user.email "root@gitlab.local"

mkdir -p manifests
cp "${MANIFESTS_DIR}"/*.yaml manifests/

git add .
git commit -m "initial commit: deploy wil-playground v1"
git push --force "http://oauth2:${TOKEN}@localhost:${GITLAB_PORT}/root/${PROJECT_NAME}.git" main
rm -rf "$TMP_DIR"

kubectl apply -f "${CONFS_DIR}/application.yaml"

echo "url: ${GITLAB_URL}"
echo "mdp: ${ROOT_PASSWORD}"
