#!/usr/bin/env bash

## -- defensive: check env
if [ -z $AIRFLOW_HOME ] || [ ! -d $AIRFLOW_HOME ]; then
    echo "Error! AIRFLOW_HOME is either not defined or does not exist!"
    exit 1
fi

action=$1
if [ -z $action ]; then
    action="start"
fi

cron_env_file="/var/spool/cron/cron_env.sh"
if [ -e $cron_env_file ]; then
    source $cron_env_file
fi

if [ ! -d $AIRFLOW_HOME/dags ]; then
    mkdir -p $AIRFLOW_HOME/dags
    mkdir -p $AIRFLOW_HOME/logs
fi

if [ $action == "start" ]; then
    echo "airflow scheduler"
    airflow scheduler >> /dev/null 2>&1 &
    sleep 3
    echo "airflow webserver"
    airflow webserver &
elif [ $action == "stop" ]; then
    pids=$(ps -ef | grep "airflow scheduler" | grep -v grep | awk '{print $2}')
    if [ ! -z "$pids" ]; then kill $pids; sleep 2; fi
    pids=$(ps -ef | grep airflow | grep master | grep -v grep | awk '{print $2}')
    if [ ! -z "$pids" ]; then kill $pids; sleep 3; fi
    pids=$(ps -ef | grep "airflow run" | grep -v grep | awk '{print $2}')
    if [ ! -z "$pids" ]; then kill $pids; sleep 0; fi
    pids=$(ps -ef | grep airflow | grep webserver | grep -v grep | awk '{print $2}')
    if [ ! -z "$pids" ]; then kill $pids; sleep 0; fi
elif [ $action == "reset" ]; then
    echo "airflow resetdb"
    airflow resetdb -y
    rm -rf $AIRFLOW_HOME/logs/*
fi
