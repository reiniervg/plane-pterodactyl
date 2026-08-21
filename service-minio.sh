#!/bin/bash
set -euo pipefail
source /home/container/.plane-service-env

export MINIO_ROOT_USER="${MINIO_ACCESS_KEY}"
export MINIO_ROOT_PASSWORD="${MINIO_SECRET_KEY}"
export MINIO_BROWSER=off

mkdir -p /home/container/services/minio/data/uploads

exec /usr/local/bin/minio server \
    /home/container/services/minio/data \
    --address 127.0.0.1:9000 \
    --console-address 127.0.0.1:9090
