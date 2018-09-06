FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https curl git libcurl4-openssl-dev \
    python-software-properties software-properties-common
RUN apt-get install -y \
    sudo supervisor

# Install Zato and download the latest version
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add - && \
    apt-add-repository https://zato.io/repo/stable/3.0/ubuntu && apt-get update && apt-get install -y zato
WORKDIR /opt/zato/current
USER zato
RUN git pull && ./bin/pip install -e ./zato-cy

ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL
USER root
RUN apt-get install -y postgresql postgresql-contrib

# Copy our certificates over
RUN mkdir -p /opt/zato/env/{web_admin,load_balancer,server{01..08}}/{run,certs}
COPY ./secrets/certs/zato.ca.cert.pem /opt/zato/env/zato.ca.cert.pem 
COPY ./secrets/certs/zato.server01.key.pub.pem /opt/zato/env/server01/zato.server01.key.pub.pem
COPY ./secrets/certs/zato.server01.key.pem /opt/zato/env/server01/zato.server01.key.pem
COPY ./secrets/certs/zato.server01.cert.pem /opt/zato/env/server01/zato.server01.cert.pem 
COPY ./secrets/certs/zato.server02.key.pub.pem /opt/zato/env/server02/zato.server02.key.pub.pem
COPY ./secrets/certs/zato.server02.key.pem /opt/zato/env/server02/zato.server02.key.pem
COPY ./secrets/certs/zato.server02.cert.pem /opt/zato/env/server02/zato.server02.cert.pem 
COPY ./secrets/certs/zato.server03.key.pub.pem /opt/zato/env/server03/zato.server03.key.pub.pem
COPY ./secrets/certs/zato.server03.key.pem /opt/zato/env/server03/zato.server03.key.pem
COPY ./secrets/certs/zato.server03.cert.pem /opt/zato/env/server03/zato.server03.cert.pem 
COPY ./secrets/certs/zato.server04.key.pub.pem /opt/zato/env/server04/zato.server04.key.pub.pem
COPY ./secrets/certs/zato.server04.key.pem /opt/zato/env/server04/zato.server04.key.pem
COPY ./secrets/certs/zato.server04.cert.pem /opt/zato/env/server04/zato.server04.cert.pem 
COPY ./secrets/certs/zato.server05.key.pub.pem /opt/zato/env/server05/zato.server05.key.pub.pem
COPY ./secrets/certs/zato.server05.key.pem /opt/zato/env/server05/zato.server05.key.pem
COPY ./secrets/certs/zato.server05.cert.pem /opt/zato/env/server05/zato.server05.cert.pem 
COPY ./secrets/certs/zato.server06.key.pub.pem /opt/zato/env/server06/zato.server06.key.pub.pem
COPY ./secrets/certs/zato.server06.key.pem /opt/zato/env/server06/zato.server06.key.pem
COPY ./secrets/certs/zato.server06.cert.pem /opt/zato/env/server06/zato.server06.cert.pem 
COPY ./secrets/certs/zato.server07.key.pub.pem /opt/zato/env/server07/zato.server07.key.pub.pem
COPY ./secrets/certs/zato.server07.key.pem /opt/zato/env/server07/zato.server07.key.pem
COPY ./secrets/certs/zato.server07.cert.pem /opt/zato/env/server07/zato.server07.cert.pem 
COPY ./secrets/certs/zato.server08.key.pub.pem /opt/zato/env/server08/zato.server08.key.pub.pem
COPY ./secrets/certs/zato.server08.key.pem /opt/zato/env/server08/zato.server08.key.pem
COPY ./secrets/certs/zato.server08.cert.pem /opt/zato/env/server08/zato.server08.cert.pem 
COPY ./secrets/certs/zato.load_balancer.key.pub.pem /opt/zato/env/load_balancer/zato.load_balancer.key.pub.pem
COPY ./secrets/certs/zato.load_balancer.key.pem /opt/zato/env/load_balancer/zato.load_balancer.key.pem
COPY ./secrets/certs/zato.load_balancer.cert.pem /opt/zato/env/load_balancer/zato.load_balancer.cert.pem 
COPY ./secrets/certs/zato.web_admin.key.pub.pem /opt/zato/env/web_admin/zato.web_admin.key.pub.pem
COPY ./secrets/certs/zato.web_admin.key.pem /opt/zato/env/web_admin/zato.web_admin.key.pem
COPY ./secrets/certs/zato.web_admin.cert.pem /opt/zato/env/web_admin/zato.web_admin.cert.pem
COPY ./secrets/certs/zato.scheduler.key.pub.pem /opt/zato/env/scheduler/zato.scheduler.key.pub.pem
COPY ./secrets/certs/zato.scheduler.key.pem /opt/zato/env/scheduler/zato.scheduler.key.pem
COPY ./secrets/certs/zato.scheduler.cert.pem /opt/zato/env/scheduler/zato.scheduler.cert.pem

# Copy our build files
COPY ./secrets/env_file /opt/zato/env/build_secrets
COPY ./docker/zato-component/build-zato-image.sh /opt/zato/env/build-zato-image.sh
RUN chown -R zato:zato /opt/zato/env

# Build our Zato components
RUN bash /opt/zato/env/build-zato-image.sh build-zato-components
CMD bash /opt/zato/env/build-zato-image.sh run-base-warning
