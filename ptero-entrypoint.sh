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

if [ ! -f plane.env ]; then
  cp /app/plane.env.template ./plane.env
fi

MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")

echo ":/home/container$ ${MODIFIED_STARTUP}"

exec /bin/bash -lc "${MODIFIED_STARTUP}"
