FROM zatobase:latest
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

ENTRYPOINT sudo -u postgres \
    /usr/lib/postgresql/9.5/bin/postgres \
    -D /var/lib/postgresql/9.5/main \
    -c config_file=/etc/postgresql/9.5/main/postgresql.conf