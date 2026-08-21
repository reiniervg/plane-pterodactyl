#!/bin/bash
set -euo pipefail
source /home/container/.plane-service-env

export HOME=/home/container/services/rabbitmq/home
export RABBITMQ_MNESIA_BASE=/home/container/services/rabbitmq/data
export RABBITMQ_LOG_BASE=/home/container/services/rabbitmq/log
export RABBITMQ_PLUGINS_EXPAND_DIR=/home/container/services/rabbitmq/plugins
export RABBITMQ_NODE_IP_ADDRESS=127.0.0.1
export RABBITMQ_NODE_PORT=5672
export RABBITMQ_NODENAME=rabbit@localhost
export RABBITMQ_USE_LONGNAME=false
export RABBITMQ_DEFAULT_USER=plane
export RABBITMQ_DEFAULT_PASS="${RABBITMQ_PASSWORD}"
export RABBITMQ_DEFAULT_VHOST=plane

exec rabbitmq-server
