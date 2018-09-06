#!/usr/bin/env bash

ZATO_BIN="/opt/zato/current/bin/zato"
ZATO_CA_PATH="/opt/zato/env"
ZATO_ENV_PATH="/opt/zato/env"

set -e
set -x

function insert_line() {
    ins_file="$1"; shift
    ins_line="$1"; shift
    sed -i "${ins_line}i$(echo $@)" "${ins_file}"
}

source /opt/zato/env/build_secrets

function apply_post_hotfix() {
    if [ -f "/opt/zato/env/load_balancer/run/config/repo/zato.config" ]; then
        # Fix the bloody haproxy configuration (why would this listen on 127.0.0.1??)
        haproxy_config="/opt/zato/env/load_balancer/run/config/repo/zato.config"
        agent_config="/opt/zato/env/load_balancer/run/config/repo/lb-agent.conf"
        sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' "$haproxy_config"
        sed -i 's/timeout connect 15000/timeout connect 60000/' "$haproxy_config"
        sed -i 's/timeout client 15000/timeout client 60000/' "$haproxy_config"
        sed -i 's/timeout server 15000/timeout server 60000/' "$haproxy_config"
        sed -i 's/localhost/0.0.0.0/' "$agent_config"
        lineno="$(grep -n 'ZATO begin backend bck_http_plain' "$haproxy_config" | cut -f1 -d:)"
        for server_id in {06..01}; do
            grep --silent "${ZATO_NETWORK_START}1${server_id}" "$haproxy_config" || insert_line "$haproxy_config" "$((lineno+1))" \
                "server http_plain--server${server_id} ${ZATO_NETWORK_START}1${server_id}:17010 check inter 2s" \
                "rise 2 fall 2 # ZATO backend bck_http_plain:server--${server_id}"
        done
    fi

    for config_file in /opt/zato/env/server??/run/config/repo/server.conf; do
        if [ -f "$config_file" ]; then
            sed -i 's/127.0.0.1:/0.0.0.0:/' "$config_file"
        fi
    done
}

if [[ "$1" == "apply-hotfixes" ]]; then
    apply_post_hotfix
    exit 0
fi

function apply_pre_hotfix() {
    # https://github.com/zatosource/zato/issues/856
    sed -i 's/port=args.get/port=args.__dict__.get/' '/opt/zato/3.0/code/zato-cli/src/zato/cli/create_server.py'
}

function create_zato_db() {
    sudo -u postgres psql -c "CREATE USER $ZATO_POSTGRES_USER WITH PASSWORD '$ZATO_POSTGRES_PASS';"
    sudo -u postgres psql -c "CREATE DATABASE $ZATO_POSTGRES_NAME;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $ZATO_POSTGRES_NAME TO $ZATO_POSTGRES_USER;"
}

function make_zato_load_balancer() {
    sudo -u zato mkdir -p "${ZATO_ENV_PATH}/load_balancer/run"
    sudo -u zato $ZATO_BIN create load_balancer \
        "${ZATO_ENV_PATH}/load_balancer/run" \
        "${ZATO_CA_PATH}/load_balancer/zato.load_balancer.key.pub.pem" \
        "${ZATO_CA_PATH}/load_balancer/zato.load_balancer.key.pem" \
        "${ZATO_CA_PATH}/load_balancer/zato.load_balancer.cert.pem" \
        "${ZATO_CA_PATH}/zato.ca.cert.pem"
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' '/opt/zato/env/load_balancer/run/config/repo/zato.config'
}

function make_zato_web_admin() {
    sudo -u zato mkdir -p "${ZATO_ENV_PATH}/web_admin/run"
    sudo -u zato $ZATO_BIN create web_admin "${ZATO_ENV_PATH}/web_admin/run" \
        --odb_host "$ZATO_POSTGRES_HOST" \
        --odb_port "$ZATO_POSTGRES_PORT" \
        --odb_user "$ZATO_POSTGRES_USER" \
        --odb_db_name "$ZATO_POSTGRES_NAME" \
        --odb_password "$ZATO_POSTGRES_PASS" \
        --tech_account_password "$ZATO_TECH_PASSWORD" \
        --verbose \
        postgresql \
        "${ZATO_CA_PATH}/web_admin/zato.web_admin.key.pub.pem" \
        "${ZATO_CA_PATH}/web_admin/zato.web_admin.key.pem" \
        "${ZATO_CA_PATH}/web_admin/zato.web_admin.cert.pem" \
        "${ZATO_CA_PATH}/zato.ca.cert.pem" \
        "$ZATO_TECH_USERNAME"
    
    sudo -u zato $ZATO_BIN update password "${ZATO_ENV_PATH}/web_admin/run" admin --password "$ZATO_ADMIN_PASSWORD"
}

function make_zato_odb() {
    sudo -u zato $ZATO_BIN create odb \
        --odb_host "$ZATO_POSTGRES_HOST" \
        --odb_port "$ZATO_POSTGRES_PORT" \
        --odb_user "$ZATO_POSTGRES_USER" \
        --odb_db_name "$ZATO_POSTGRES_NAME" \
        --odb_password "$ZATO_POSTGRES_PASS" \
        --verbose \
        postgresql 
}

function make_zato_scheduler() {
    sudo -u zato mkdir -p "${ZATO_ENV_PATH}/scheduler/run"
    sudo -u zato $ZATO_BIN create scheduler "${ZATO_ENV_PATH}/scheduler/run" \
        --odb_host "$ZATO_POSTGRES_HOST" \
        --odb_port "$ZATO_POSTGRES_PORT" \
        --odb_user "$ZATO_POSTGRES_USER" \
        --odb_db_name "$ZATO_POSTGRES_NAME" \
        --odb_password "$ZATO_POSTGRES_PASS" \
        --kvdb_password "$ZATO_KVDB_PASS" \
        --secret_key "$ZATO_SECRET_KEY" \
        --cluster_id 1 \
        --verbose \
        postgresql "$ZATO_KVDB_HOST" "$ZATO_KVDB_PORT" \
        "${ZATO_CA_PATH}/scheduler/zato.scheduler.key.pub.pem" \
        "${ZATO_CA_PATH}/scheduler/zato.scheduler.key.pem" \
        "${ZATO_CA_PATH}/scheduler/zato.scheduler.cert.pem" \
        "${ZATO_CA_PATH}/zato.ca.cert.pem" \
        "${ZATO_CLUSTER_NAME}"
}

function make_zato_cluster() {
    sudo -u zato $ZATO_BIN create cluster \
        --tech_account_password "$ZATO_TECH_PASSWORD" \
        --odb_host $ZATO_POSTGRES_HOST --odb_password $ZATO_POSTGRES_PASS --odb_port $ZATO_POSTGRES_PORT \
        --odb_user $ZATO_POSTGRES_USER --odb_db_name $ZATO_POSTGRES_NAME postgresql \
        $ZATO_LB_HOST $ZATO_LB_PORT $ZATO_LB_AGENT_PORT $ZATO_KVDB_HOST $ZATO_KVDB_PORT \
        $ZATO_CLUSTER_NAME $ZATO_TECH_USERNAME
}

function make_zato_servers() {
    for server_id in "$@"; do
        sudo -u zato mkdir -p "${ZATO_ENV_PATH}/${server_id}/run"
        sudo -u zato $ZATO_BIN create server \
            --verbose \
            --odb_host "$ZATO_POSTGRES_HOST" \
            --odb_port "$ZATO_POSTGRES_PORT" \
            --odb_user "$ZATO_POSTGRES_USER" \
            --odb_db_name "$ZATO_POSTGRES_NAME" \
            --odb_password "$ZATO_POSTGRES_PASS" \
            --kvdb_password "$ZATO_KVDB_PASS" \
            --secret_key "$ZATO_SECRET_KEY" \
            --jwt_secret "$ZATO_JWT_SECRET" \
            "${ZATO_ENV_PATH}/${server_id}/run" \
            postgresql "$ZATO_KVDB_HOST" "$ZATO_KVDB_PORT" \
            "${ZATO_CA_PATH}/${server_id}/zato.${server_id}.key.pub.pem" \
            "${ZATO_CA_PATH}/${server_id}/zato.${server_id}.key.pem" \
            "${ZATO_CA_PATH}/${server_id}/zato.${server_id}.cert.pem" \
            "${ZATO_CA_PATH}/zato.ca.cert.pem" \
            "$ZATO_CLUSTER_NAME" "${server_id}"
    done
}

if [[ "$1" == "build-zato-components" ]]; then
    set -x
    /etc/init.d/postgresql start
    cp /etc/hosts /etc/hosts2
    echo "127.0.0.1 ${ZATO_POSTGRES_HOST} $(hostname -s) # zatobase_buildonly" >> /etc/hosts
    create_zato_db
    apply_pre_hotfix
    make_zato_odb
    make_zato_cluster
    make_zato_scheduler
    make_zato_web_admin
    make_zato_load_balancer
    make_zato_servers server{01..08}
    exit 0
fi

if [[ "$1" == "run-base-warning" ]]; then
    echo "You really shouldn't be running this image directly" > /dev/stderr
    exit 1
fi

if [[ "$1" == "clean" ]]; then

    exit 0
fi