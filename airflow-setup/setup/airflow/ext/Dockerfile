FROM ubuntu/airflow:base

ARG PG_VERSION
ENV PG_VERSION ${PG_VERSION}

# copy set up scripts
COPY script/* $AIRFLOW_HOME/ext/script/

# install gcp sdk, jdk, mvn, psql client, etc.
RUN export DEBIAN_FRONTEND=noninteractive \
    && chown -R root:root $AIRFLOW_HOME \
    && pip install requests google-auth requests_toolbelt \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y acl postgresql-client-${PG_VERSION} \
    && apt-get upgrade -y && apt-get clean && apt autoremove -y \
    && chown -R airflow:airflow $AIRFLOW_HOME \
    && chmod +x $AIRFLOW_HOME/ext/script/*.sh \
    && chmod +x $AIRFLOW_HOME/ext/script/*.py \
    && $AIRFLOW_HOME/ext/script/setup.sh
