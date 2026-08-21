#!/bin/bash
set -euo pipefail
source /home/container/.plane-service-env

CONF=/home/container/services/redis/redis.conf
cat > "${CONF}" <<EOF
bind 127.0.0.1
protected-mode yes
port 6379
dir /home/container/services/redis
appendonly yes
appendfilename "appendonly.aof"
save 900 1
save 300 10
save 60 10000
requirepass ${REDIS_PASSWORD}
EOF

if command -v redis-server >/dev/null 2>&1; then
    exec redis-server "${CONF}"
elif command -v valkey-server >/dev/null 2>&1; then
    exec valkey-server "${CONF}"
else
    echo "redis-server/valkey-server not found" >&2
    exit 1
fi
