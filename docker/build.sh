#!/usr/bin/env bash
export PROJECT_DIR="$( cd "$(dirname "$0")" ; cd .. ; pwd -P )"
cd "$PROJECT_DIR"
exec docker build -f ./docker/Dockerfile . --tag zatobase:latest
