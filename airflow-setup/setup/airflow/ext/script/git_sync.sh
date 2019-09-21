#!/usr/bin/env bash
## airflow service functions
##   sync source / dags / scripts: copy / download source files / dags / script files
##     update scripts and configurations
##   update dags: update / add / remove dags
##   reset / re-initdb: reset airflow database

cron_env_file="/var/spool/cron/cron_env.sh"
if [ -e $cron_env_file ]; then
    source $cron_env_file
fi

### constants
MARK_FILE="update.log"
UPDATE_DRIVER="update.sh"
SOURCECODE_ROOT="workspace/Data"

### global variables
wk_dir=$(pwd)
gcp_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
function __get_source_bucket() {
    local src_bucket=$SOURCE_BUCKET
    if [ -z $src_bucket ]; then
        if [[ $gcp_project == "zerodawn-test" ]]; then
            src_bucket="gs://analytic-staging"
        else
            src_bucket="gs://zd-analytic-staging"
        fi
    fi
    echo $src_bucket
}

function __help {
    script_name=$(basename "$0")
    echo "Usage: $script_name <action>"
    echo "  action: source | dag | script | all "
    echo "    -- all = source + dag + script"
    echo "  note about sync source: "
    echo "    This script expects to sync source files / dags / scripts from  SOURCE_BUCKET or $(__get_source_bucket)"
    echo "    MARK_FILE: expects \"$MARK_FILE\" in source bucket updated when upload source files / jar files or dags.  "
    echo "      The last modified date of \"$MARK_FILE\" will be used to decide any new updates available. "
    echo "      Run:\"echo \$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") > $MARK_FILE && gsutil cp $MARK_FILE gs://<source or dag bucket> "
    echo "      each time after uploading source or dag files. "
    echo "    UPDATE_DRIVER: \"$UPDATE_DRIVER\" will be invoked if it's available in extracted files. "
    echo "  note about sync target: "
    echo "    source:  source code will be synchronized to \"\$AIRFLOW_HOME/$SOURCECODE_ROOT\" "
    echo "    dag: will be synchronized to \"\$AIRFLOW_HOME/dags\" "
    echo "    script: will be synchronized to \"\$AIRFLOW_HOME/ext\" "
}

function __sync() {
    local source_dir=$1
    local target_dir=$2

    if [ -z $gcp_project ]; then
        echo "WARNING: gcloud project was not configured. Not able to sync from gcs."
        return 0
    fi

    local last_synced="2000-01-01T00:00:00Z"
    if [ -e $target_dir/last_sync.log ]; then
        last_synced=$(head -n1 $target_dir/last_sync.log)
    fi
    local last_updated=$(gsutil ls -l $source_dir/$MARK_FILE | grep $MARK_FILE | awk '{print $2}')
    if [ -z $last_updated ]; then
        echo "Warning: \"$MARK_FILE\" was not found. \"$source_dir\" is skipped."
        return
    fi

    if [[ $last_synced < $last_updated ]]; then
        mkdir -p $target_dir  ## defensive for the first time

        local cmd="gsutil cp -r $source_dir/* $target_dir/"
        echo $cmd && $cmd 2>&1 > /dev/null
        cd $target_dir && ls *.tar.gz | xargs -n1 tar -xzf && rm *.tar.gz $MARK_FILE > /dev/null 2>&1 && cd $wk_dir

        echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") > $target_dir/last_sync.log
    fi
}

function sync_source() {
    local source_bucket=$(__get_source_bucket)
    local source_dir="$source_bucket/airflow/$SOURCECODE_ROOT"
    local target_dir="$AIRFLOW_HOME/$SOURCECODE_ROOT"
    __sync $source_dir $target_dir

    local update_driver="$target_dir/$UPDATE_DRIVER"
    if [ -e $update_driver ]; then
        echo "$update_driver"
        $update_driver
    fi
}

function sync_dags() {
    local source_bucket=$(__get_source_bucket)
    local source_dir="$source_bucket/airflow/dags"
    local target_dir="$AIRFLOW_HOME/dags"
    __sync $source_dir $target_dir

    local update_driver="$target_dir/$UPDATE_DRIVER"
    if [ -e $update_driver ]; then
        echo "$update_driver"
        $update_driver
    fi
}

function sync_script() {
    local source_bucket=$(__get_source_bucket)
    local source_dir="$source_bucket/airflow/ext"
    local target_dir="$AIRFLOW_HOME/ext"
    __sync $source_dir $target_dir

    local update_driver="$target_dir/script/$UPDATE_DRIVER"
    if [ -e $update_driver ]; then
        echo "$update_driver"
        $update_driver
    fi
}

### main
action=$1
if [ -z $action ]; then
    __help; exit
fi

if [[ $action == "source" ]] || [[ $action == "all" ]]; then
    sync_source
fi

if [[ $action == "dag" ]] || [[ $action == "all" ]]; then
    sync_dags
fi

if [[ $action == "script" ]] || [[ $action == "all" ]]; then
    sync_script
fi
