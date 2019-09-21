#!/usr/bin/env bash
## -- deploy images

airflow_gcp_version=$1
if [ -z $airflow_gcp_version ]; then
    airflow_gcp_version=$(date +%Y%m%d)
fi

gcp_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

docker tag ubuntu/airflow:base gcr.io/$gcp_project/airflow:base
gcloud docker -- push gcr.io/$gcp_project/airflow:base

docker tag "ubuntu/airflow-gcp:$airflow_gcp_version" gcr.io/$gcp_project/airflow-gcp:$(date +%Y%m%d)
gcloud docker -- push gcr.io/$gcp_project/airflow-gcp:$(date +%Y%m%d)

docker tag ubuntu/postgres:base gcr.io/$gcp_project/airflow-postgres
gcloud docker -- push gcr.io/$gcp_project/airflow-postgres
