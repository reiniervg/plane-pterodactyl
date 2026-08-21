#!/bin/bash
set -euo pipefail
PG_BINDIR="$(cat /home/container/services/postgres/bindir)"
exec "${PG_BINDIR}/postgres" \
    -D /home/container/services/postgres/data \
    -c listen_addresses=127.0.0.1 \
    -c port=5432 \
    -c max_connections=1000 \
    -c unix_socket_directories=/home/container/services/postgres/run
