#!/usr/bin/env bash

cleanup ()
{
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

$AIRFLOW_HOME/ext/script/config_cron.sh
/usr/sbin/service cron start

$AIRFLOW_HOME/ext/script/config_gcloud.sh
gcp_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
if [ ! -z $gcp_project ]; then
    $AIRFLOW_HOME/ext/script/git_sync.sh source
    $AIRFLOW_HOME/ext/script/git_sync.sh dag
    $AIRFLOW_HOME/ext/script/git_sync.sh script
    $AIRFLOW_HOME/ext/script/git_src.sh register_dags
fi

$AIRFLOW_HOME/ext/script/config_airflow.sh
$AIRFLOW_HOME/ext/script/run_airflow.sh

idx=0
while [ 1 ]
do
    clear
    idx=$((idx+1))
    if [ $idx -gt 1000000 ]; then idx=0; fi
    echo "airflow service is running... counter = $idx"
    sleep 10 &   # ten seconds
    wait $!
done
