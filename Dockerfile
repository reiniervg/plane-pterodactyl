ARG PLANE_VERSION=v1.4.0

FROM makeplane/plane-aio-community:${PLANE_VERSION} AS upstream

# Re-create upstream filesystem without inheriting problematic VOLUME declarations.
FROM scratch
COPY --from=upstream / /

SHELL ["/bin/bash", "-c"]

ENV USER=container \
    HOME=/home/container \
    XDG_CONFIG_HOME=/home/container/.config \
    XDG_DATA_HOME=/home/container/.local/share \
    PYTHONDONTWRITEBYTECODE=1 \
    TMPDIR=/tmp

WORKDIR /home/container

RUN cp /app/plane.env /app/plane.env.template \
    && rm -f /app/plane.env \
    && ln -s /home/container/plane.env /app/plane.env \
    && rm -rf /app/logs /app/data \
    && ln -s /home/container/logs /app/logs \
    && ln -s /home/container/data /app/data \
    && if [ -d /app/backend/plane ]; then \
         rm -rf /app/backend/plane/logs && \
         ln -s /home/container/logs/backend /app/backend/plane/logs; \
       fi \
    # Strip Caddy's cap_net_bind_service file capability by recreating its inode.
    # Wings uses no-new-privileges; Plane listens on a high Pterodactyl allocation.
    && CADDY_PATH="$(command -v caddy)" \
    && cat "${CADDY_PATH}" > /tmp/caddy.pterodactyl \
    && chmod 0755 /tmp/caddy.pterodactyl \
    && rm -f "${CADDY_PATH}" \
    && mv /tmp/caddy.pterodactyl "${CADDY_PATH}" \
    && sed -i '/^[[:space:]]*user=root[[:space:]]*$/d' /etc/supervisor/conf.d/supervisor.conf \
    && sed -i '/^\[supervisord\]$/a pidfile=/home/container/supervisord.pid\nchildlogdir=/home/container/logs' /etc/supervisor/conf.d/supervisor.conf

COPY ptero-entrypoint.sh /ptero-entrypoint.sh
RUN chmod 0755 /ptero-entrypoint.sh

CMD ["/bin/bash", "/ptero-entrypoint.sh"]
