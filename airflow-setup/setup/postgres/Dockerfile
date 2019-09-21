# ubuntu 16.04+
FROM ubuntu:latest

# do not prompt for choices on installation/configuration of packages
ENV TERM linux
ENV EDITOR vi

ARG PG_VERSION
ENV PG_VERSION ${PG_VERSION}

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        apt-utils locales \
        net-tools netcat curl wget unzip vim.tiny nano \
        ca-certificates \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y acl \
        postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} \
    && apt-get upgrade -y && apt-get clean && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base \
    && echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/${PG_VERSION}/main/pg_hba.conf \
    && echo "listen_addresses='*'" >> /etc/postgresql/${PG_VERSION}/main/postgresql.conf

COPY script/* /

USER postgres
EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
