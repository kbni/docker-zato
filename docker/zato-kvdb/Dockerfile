FROM redis
COPY --from=zatobase:latest /opt/zato/env/build_secrets /tmp/build_secrets
RUN grep ZATO_KVDB_PASS /tmp/build_secrets > /etc/redis-secret
RUN rm /tmp/build_secrets
ENTRYPOINT bash -c 'source /etc/redis-secret && redis-server --requirepass $ZATO_KVDB_PASS'
