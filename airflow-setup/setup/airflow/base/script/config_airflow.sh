#!/usr/bin/env bash

config_template=$AIRFLOW_HOME/ext/config/airflow.cfg.template
cat $config_template | \
    sed "s#{{ AIRFLOW_HOME }}#$AIRFLOW_HOME#g" > $AIRFLOW_HOME/airflow.cfg

airflow initdb && airflow resetdb -y
$AIRFLOW_HOME/ext/script/set_airflow_pwd.py
