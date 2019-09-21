#!/usr/bin/env bash
## -- create airflow user / database

if [ -z $AIRFLOW__DB_USER ]; then
    AIRFLOW__DB_USER="airflow"
fi
if [ -z $AIRFLOW__DB_PASSWORD ]; then
    AIRFLOW__DB_PASSWORD="airflow"
fi

psql --command "CREATE USER $AIRFLOW__DB_USER WITH SUPERUSER PASSWORD '$AIRFLOW__DB_PASSWORD';"
psql --command "CREATE DATABASE airflow OWNER $AIRFLOW__DB_USER;"
