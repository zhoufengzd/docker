#!/usr/bin/env bash
## update deployed scripts / configurations

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"/setup/airflow/ext/script && pwd)"
target_dir="$AIRFLOW_HOME/ext/script"

if [ -d $target_dir ]; then
    cp $script_dir/* $target_dir/
    chmod +x $target_dir/*.sh > /dev/null 2>&1
    chmod +x $target_dir/*.py > /dev/null 2>&1
fi
