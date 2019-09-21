#!/usr/bin/env bash
##   build airflow image and airflow-postgres image

docker build setup/airflow/base --tag "ubuntu/airflow:base"
#docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/airflow:base"

docker build setup/airflow/ext -t "ubuntu/airflow-gcp:$(date +%Y%m%d)" --build-arg PG_VERSION=9.6
#docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/airflow-gcp:$(date +%Y%m%d)"

docker build setup/postgres/ -t "ubuntu/postgres:base" --build-arg PG_VERSION=9.6
# docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/postgres:base"
