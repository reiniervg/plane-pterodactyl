#!/bin/bash
set -euo pipefail

cd /home/container

mkdir -p \
  logs/access \
  logs/error \
  logs/backend \
  data \
  .config \
  .local/share

if [ ! -f /home/container/plane.env ]; then
    cp /app/plane.env.template /home/container/plane.env
fi

PORT="${SERVER_PORT:?SERVER_PORT is not set by Pterodactyl}"

set_env_file() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" /home/container/plane.env; then
        sed -i "s|^${key}=.*|${key}=${value}|" /home/container/plane.env
    else
        printf '%s=%s\n' "${key}" "${value}" >> /home/container/plane.env
    fi
}

# Pterodactyl maps host allocation N -> container port N.
# Make Plane's internal Caddy listen on the same port.
set_env_file "SITE_ADDRESS" ":${PORT}"

# Public HTTPS is terminated by the host reverse proxy.
set_env_file "APP_PROTOCOL" "${APP_PROTOCOL:-https}"

echo "Plane Pterodactyl runtime:"
echo "  SERVER_PORT=${PORT}"
echo "  SITE_ADDRESS=:${PORT}"
echo "  APP_PROTOCOL=${APP_PROTOCOL:-https}"

export SITE_ADDRESS=":${PORT}"
export APP_PROTOCOL="${APP_PROTOCOL:-https}"

exec /app/start.sh
