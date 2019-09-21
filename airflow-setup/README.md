# Airflow docker image setup

## set deployment cluster
    gcloud container clusters get-credentials airflow-cluster --zone us-central1-a --project=zerodawn-test

## set the target project, by default, it's the current configuration.
    gcp_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

## Build docker images.
    docker build setup/airflow/base
    docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/airflow:base"

    docker build setup/airflow/ext --build-arg PG_VERSION=9.6
    docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/airflow-gcp:$(date +%Y%m%d)"

    docker build setup/postgres/ --build-arg PG_VERSION=9.6
    docker tag $(docker images | grep "<none>" | awk '{print $3}') "ubuntu/postgres:base"

## Upload / publish image
    docker tag ubuntu/airflow:base gcr.io/$gcp_project/airflow:base
    gcloud docker -- push gcr.io/$gcp_project/airflow:base

    docker tag "ubuntu/airflow-gcp:$(date +%Y%m%d)" gcr.io/$gcp_project/airflow-gcp:$(date +%Y%m%d)
    gcloud docker -- push gcr.io/$gcp_project/airflow-gcp:$(date +%Y%m%d)

    docker tag ubuntu/postgres:base gcr.io/$gcp_project/airflow-postgres
    gcloud docker -- push gcr.io/$gcp_project/airflow-postgres

## Deployment
    gcloud compute addresses create airflow-gcp --region us-east4
    deploy.sh

## Remove deployment
    kubectl delete deployment airflow
    kubectl delete pods <airflow-xxx> --grace-period=0 --force
    kubectl delete service airflow-postgres
    kubectl delete deployment airflow-postgres
    kubectl delete pods <airflow-postgres-xxx> --grace-period=0 --force
