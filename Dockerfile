ARG PLANE_VERSION=v1.4.0

FROM minio/minio:latest AS minio

FROM makeplane/plane-aio-community:${PLANE_VERSION} AS upstream

# Flatten Plane's upstream image so its VOLUME declarations are not inherited.
FROM scratch
COPY --from=upstream / /
COPY --from=minio /usr/bin/minio /usr/local/bin/minio

SHELL ["/bin/bash", "-c"]

ENV USER=container \
    HOME=/home/container \
    XDG_CONFIG_HOME=/home/container/.config \
    XDG_DATA_HOME=/home/container/.local/share \
    PYTHONDONTWRITEBYTECODE=1 \
    TMPDIR=/tmp

WORKDIR /home/container

# Install PostgreSQL, Redis and RabbitMQ into the same image.
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
        export DEBIAN_FRONTEND=noninteractive; \
        printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; \
        chmod +x /usr/sbin/policy-rc.d; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            postgresql postgresql-client redis-server rabbitmq-server ca-certificates; \
        rm -f /usr/sbin/policy-rc.d; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache postgresql postgresql-client redis rabbitmq-server ca-certificates; \
    else \
        echo "Unsupported Plane AIO base image: neither apt-get nor apk is available." >&2; \
        exit 1; \
    fi; \
    cp /app/plane.env /app/plane.env.template; \
    rm -f /app/plane.env; \
    ln -s /home/container/plane.env /app/plane.env; \
    rm -rf /app/logs /app/data; \
    ln -s /home/container/logs /app/logs; \
    ln -s /home/container/data /app/data; \
    if [ -d /app/backend/plane ]; then \
        rm -rf /app/backend/plane/logs; \
        ln -s /home/container/logs/backend /app/backend/plane/logs; \
    fi; \
    CADDY_PATH="$(command -v caddy)"; \
    cat "${CADDY_PATH}" > /tmp/caddy.pterodactyl; \
    chmod 0755 /tmp/caddy.pterodactyl; \
    rm -f "${CADDY_PATH}"; \
    mv /tmp/caddy.pterodactyl "${CADDY_PATH}"; \
    sed -i '/^[[:space:]]*user=root[[:space:]]*$/d' /etc/supervisor/conf.d/supervisor.conf; \
    sed -i '/^\[supervisord\]$/a pidfile=/home/container/supervisord.pid\nchildlogdir=/home/container/logs' /etc/supervisor/conf.d/supervisor.conf

COPY ptero-entrypoint.sh /ptero-entrypoint.sh
COPY service-postgres.sh /usr/local/bin/plane-service-postgres
COPY service-redis.sh /usr/local/bin/plane-service-redis
COPY service-rabbitmq.sh /usr/local/bin/plane-service-rabbitmq
COPY service-minio.sh /usr/local/bin/plane-service-minio
COPY embedded-services.conf /tmp/embedded-services.conf

# Plane invokes this exact Supervisor file, so append the embedded services to it directly.
RUN cat /tmp/embedded-services.conf >> /etc/supervisor/conf.d/supervisor.conf \
    && rm -f /tmp/embedded-services.conf \
    && chmod 0755 \
        /ptero-entrypoint.sh \
        /usr/local/bin/plane-service-postgres \
        /usr/local/bin/plane-service-redis \
        /usr/local/bin/plane-service-rabbitmq \
        /usr/local/bin/plane-service-minio

CMD ["/bin/bash", "/ptero-entrypoint.sh"]
