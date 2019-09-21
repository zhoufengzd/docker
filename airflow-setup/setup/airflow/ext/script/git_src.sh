#!/usr/bin/env bash

source $HOME/bin/utils.sh
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function __help {
    script_name=$(basename "$0")
    echo "Usage: $script_name <action> [optional_flag]"
    echo "  action: "
    echo "    pack : pack into single tar file and upload to gcs"
    echo "    build: build local projects"
    echo "    pull: pull from git."
    echo "    register_dags: set up dags folder. "
    echo "    un_register_dags: remove dags folder. "
    echo "  optional_flag: "
    echo "    pack options:"
    echo "      -a|--all: by default, copy all source files and jars. "
    echo "      -s|--source: all source project files in git_src.config under [projects] section"
    echo "      -j|--jar: all jar files in git_src.config under [distribute_targets] section"
}

### global constants
CONFIG_FILE="$script_dir/git_src.config"

CLEAN_SCRIPT="clean_source_code.sh"
UPDATE_DAGS_SCRIPT="update_dags.sh"
MARK_FILE="update.log"
GIT_ROOT="workspace/Data"  ## git source directory
DISTRIBUTE_DIR="_distributed"

# default

## source & build jars will be updated to gcs source directory
gcs_source_dir="airflow/$GIT_ROOT"
git_tar_file="git_src.tar.gz"
build_tar_file="git_build.tar.gz"

## airflow scripts and configurations will be uploaded to airflow script directory
airflow_script_dir="airflow/ext"
airflow_script_tar_file="airflow_ext.tar.gz"

source_root_dir="$(cd $script_dir/../../../../../ && pwd)"
default_roots=($AIRFLOW_HOME/$GIT_ROOT $HOME/$GIT_ROOT $source_root_dir)
mvn_log_file=$wk_dir"/build_"$(date '+%Y%m%d_%H%M%S').log
line_separator="-------------------------------------------------------------------------------"

gcp_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
if [[ $gcp_project == "zerodawn-test" ]]; then
    gcs_buckets=("analytic-staging")
else
    gcs_buckets=("zd-analytic-staging")
fi

# global variables
declare -A projects
src_root=""
declare -A distribute_targets

function __check_source_root {
    for rt_dir in ${default_roots[@]}; do
        if [ -d $rt_dir/zd-gcp-jobscheduling ]; then
            src_root=$rt_dir
            break
        fi
    done
    if [ -z $src_root ]; then
        echo "Please set source root [none]:"
        read src_root
        if [ -z $src_root ] || [ ! -d $src_root/zd-gcp-jobscheduling ]; then
            exit
        fi
    fi
    mkdir -p $src_root/$DISTRIBUTE_DIR
}

function __load_project_list() {
    local in_file=$1
    if [ ! -e $in_file ]; then
        echo "Error! Can't locate project config file $in_file. "
        exit
    fi

    local proj_idx=0
    local dist_idx=0
    default_ifs="$IFS"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line = \#* ]] || [ -z $line ]; then  # skip comments and empty lines
            continue
        fi

        if [[ $line = "[projects]"* ]]; then
            proj_idx=1
            dist_idx=0
            continue
        elif [[ $line = "[distribute_targets]"* ]]; then
            proj_idx=0
            dist_idx=1
            continue
        elif [[ $line = "["* ]]; then  ## unknown section
            echo "Warning: Unknown section $line ignored. "
            proj_idx=0
            dist_idx=0
            continue
        fi

        if [ $proj_idx -gt 0 ]; then
            projects[$proj_idx]=$line
            proj_idx=$((proj_idx+1))
        elif [ $dist_idx -gt 0 ]; then
            distribute_targets[$dist_idx]=$line
            dist_idx=$((dist_idx+1))
        fi
    done < "$in_file"
    IFS=$default_ifs
}

function __clean {
    local proj_dir=$1

    cd $src_root/$proj_dir
    if [ -e pom.xml ]; then
        echo "cd $proj_dir && mvn clean"
        mvn clean > /dev/null 2>&1
    fi

    if [ -e $CLEAN_SCRIPT ]; then  ## allow customized cleaning before package the source
        echo "cd $proj_dir && $CLEAN_SCRIPT"
        ./$CLEAN_SCRIPT #> /dev/null 2>&1
    fi

    cd $wk_dir
}

function __mvn_build {
    local proj_dir=$1

    cd $src_root/$proj_dir
    if [ -e pom.xml ]; then
        echo $default_line_separator >> $mvn_log_file
        echo "cd $proj_dir && mvn clean install ..."
        mvn clean install -Dmaven.test.skip=true >> $mvn_log_file
        echo $default_line_separator >> $mvn_log_file
    fi

    cd $wk_dir
}

function __mvn_package {
    local proj_dir=$1
    local target_dir=$2

    cd $src_root/$proj_dir
    if [ -e pom.xml ]; then
        echo $default_line_separator >> $mvn_log_file
        echo "cd $proj_dir && mvn package ..."
        mvn package -Dmaven.test.skip=true >> $mvn_log_file
        echo $default_line_separator >> $mvn_log_file

        if [ ! -z $target_dir ] && [ -d $target_dir ]; then
            local target="$(basename $(pwd))"
            target=${target//"zd-gcp-analytic-"/}
            target=${target//"zd-gcp-"/}
            target_jar=$target".jar"

            # copy jar file
            local source_jar=$(ls target/*.jar | grep -v original)
            cp $source_jar $target_dir/$target_jar  ## make the distributed jar version independent
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $source_jar ==> $target_jar " >> $target_dir/package.log

            # copy configurations
            cp *.yaml $target_dir/
        fi
    fi

    ls $target_dir/
    cd $wk_dir
}

function __upload {
    local jar_file=$1

    echo "-- upload to gcs..."
    for bucket in ${gcs_buckets[@]}; do
        cmd="gsutil cp $jar_file gs://$bucket/$gcs_source_dir/"
        echo $cmd && sh -c "$cmd" > /dev/null 2>&1

        echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") > $MARK_FILE \
            && gsutil cp $MARK_FILE gs://$bucket/$gcs_source_dir/ > /dev/null 2>&1 && rm $MARK_FILE

        ## provide download hint
        echo "-- to download: gsutil cp gs://$bucket/$gcs_source_dir/$jar_file ./ "
        echo ""
    done
}

# pack into tar.gz
function __pack {
    local target=$1

    if [ -z $target ]; then
        target="all"
    fi

    if [[ $target == "j"* ]] || [[ $target == "all" ]]; then
        echo "-- build distributed jars..."
        for proj in ${distribute_targets[@]}; do
            __mvn_package $proj $src_root/$DISTRIBUTE_DIR
        done
        rm -f $mvn_log_file
        echo ""

        echo "-- pack jar files..."
        cd $src_root
        cmd="tar -czf $HOME/$build_tar_file $DISTRIBUTE_DIR"
        echo $cmd && sh -c "$cmd" && echo ""

        cd $HOME && __upload $build_tar_file && rm $build_tar_file && cd $wk_dir
    fi

    if [[ $target == "s"* ]] || [[ $target == "all" ]]; then
        echo "-- clean project source..."
        local target_list=""
        for proj in ${projects[@]}; do
            target_list+=" "$proj
            __clean $proj
        done

        echo ""
        echo "-- pack project source files..."
        cd $src_root
        cmd="tar -czf $HOME/$git_tar_file $target_list"
        echo $cmd && sh -c "$cmd" && echo ""

        cd $HOME && __upload $git_tar_file && rm $git_tar_file && cd $wk_dir
    fi
}

function __build {
    echo ""
    echo "-- mvn build ..."
    for proj in ${projects[@]}; do
        __mvn_build $proj
    done
    rm -f $mvn_log_file
}

function __pull {
    echo "-- git pull origin master ..."
    echo ""

    cd $src_root
    local git_projects=($(ls | grep -v RemoteSystemsTempFiles | grep -v _distributed))
    local branch=""
    for proj in ${git_projects[@]}; do
        echo "-- cd $proj " && cd $src_root/$proj

        branch=$(git branch | grep master)
        if [ ! -z "$branch" ]; then
            echo "git pull origin master ..."
            git pull origin master
        fi

        branch=$(git branch | grep development)
        if [ ! -z "$branch" ]; then
            echo "git pull origin development ..."
            git pull origin development
        fi

        branch=$(git branch | grep -v development | grep develop)
        if [ ! -z "$branch" ]; then
            echo "git pull origin develop ..."
            git pull origin develop
        fi
    done
    cd $wk_dir
}

function __update_dags {
    local action=$1
    echo ""
    echo "-- update dags ..."
    for proj in ${projects[@]}; do
        cd $src_root/$proj
        if [ -e $UPDATE_DAGS_SCRIPT ]; then  ## allow customized cleaning before package the source
            echo "-- cd $src_root/$proj..."
            ./$UPDATE_DAGS_SCRIPT $action
        fi
        cd $wk_dir
    done
}

## main
action=$1
optional_flag=${2//"-"/}

if [ -z $action ]; then
    __help; exit
fi

__check_source_root
__load_project_list "$CONFIG_FILE"

start_time=$(date +%Y-%m-%dT%H:%M:%S)

if [[ $action == "pack" ]]; then
    __pack $optional_flag
elif [[ $action == "build" ]]; then
    __build
elif [[ $action == "pull" ]]; then
    __pull
elif [[ $action == "register_dags" ]]; then
    __update_dags "install"
elif [[ $action == "un_register_dags" ]]; then
    __update_dags "uninstall"
fi

end_time=$(date +%Y-%m-%dT%H:%M:%S)
echo "-- started at: $start_time and completed at: $end_time"
echo ""
