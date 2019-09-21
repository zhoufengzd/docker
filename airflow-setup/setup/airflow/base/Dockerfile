# ubuntu 16.04+
FROM ubuntu:latest

# do not prompt for choices on installation/configuration of packages
ENV TERM linux
ENV AIRFLOW_HOME /usr/local/airflow
ENV EDITOR vi

# install airflow and required tools
RUN export DEBIAN_FRONTEND=noninteractive \
    && export BUILDDEPS="build-essential python-dev libffi-dev libpq-dev libssl-dev" \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        apt-utils locales \
        net-tools netcat curl wget unzip vim.tiny nano cron \
        gosu ca-certificates \
        $BUILDDEPS \
        python python-pip libpq5 \
    && pip install --upgrade pip \
    && pip install setuptools \
    && pip install cryptography \
    && pip install flask_bcrypt \
    && pip install apache-airflow[crypto,celery,postgres,jdbc,gcp_api] \
    && apt-get remove --purge -yqq $BUILDDEPS \
    && apt-get upgrade -y && apt-get clean && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base \
    && useradd -ms /bin/bash -d $AIRFLOW_HOME airflow \
    && mkdir -p $AIRFLOW_HOME/ext/script

# copy set up scripts and set entrypoint
COPY script/* $AIRFLOW_HOME/ext/script/
COPY config/* $AIRFLOW_HOME/ext/config/

RUN  chown airflow:airflow $AIRFLOW_HOME \
    && chmod +x $AIRFLOW_HOME/ext/script/*.sh \
    && chmod +x $AIRFLOW_HOME/ext/script/*.py \
    && ln -s $AIRFLOW_HOME/ext/script/entrypoint.sh /entrypoint.sh

EXPOSE 8080 5555 8793

ENV HOME $AIRFLOW_HOME
ENTRYPOINT ["/entrypoint.sh"]
