#!/usr/bin/env bash

cleanup ()
{
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

/usr/sbin/service cron start
$AIRFLOW_HOME/ext/script/config_airflow.sh
$AIRFLOW_HOME/ext/script/run_airflow.sh

idx=0
while [ 1 ]
do
    clear
    idx=$((idx+1))
    if [ $idx -gt 1000000 ]; then idx=0; fi
    echo "airflow service is running... counter = $idx"
    sleep 10 &   # one minute
    wait $!
done
