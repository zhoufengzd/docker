#!/usr/bin/env bash
## -- deploy images

### constants

#### -- airflow secrets
AIRFLOW_SECRETS_NAME="airflow-secrets"
SECRETS_TEMPLATE="setup/airflow/ext/airflow-secrets.yaml.template"
DEFAULT_SECRETS_FILE="airflow-secrets.yaml"
DEFAULT_AIRFLOW__ADMIN="admin"
DEFAULT_AIRFLOW__DB_USER="airflow"
DEFAULT_POSTGRES_USER="urlcov"
DEFAULT_AIRFLOW__CORE__EXECUTOR="LocalExecutor"
DEFAULT_AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=""

#### -- deployment template
POSTGRES_DEPLOYMENT_TEMPLATE="setup/postgres/deployment.yaml.template"
AIRFLOW_DEPLOYMENT_TEMPLATE="setup/airflow/ext/deployment.yaml.template"

# environment
wk_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_ifs="$IFS"
GCP_PROJECT=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

# variables
image_names=$1
secrets_file=$2
secrets_file_generated="false"

function __help {
    script_name=$(basename "$0")
    echo "Usage: $script_name <image_names> <secret_file>"
    echo "  image_names: airflow-gcp, airflow-postgres, or both. delimited by \";\". "
    echo "     example: \"airflow-postgres;airflow-gcp\", or \"airflow-postgres\""
    echo "  secret_file: airflow secret file. "
    echo "     optional: use \"?\" to represent default $DEFAULT_SECRETS_FILE or build it from $SECRETS_TEMPLATE if not found. "
}

function __deploy {
    local template_file=$1
    local deployment_file="deployment_"$(date +"%Y%m%d_%H%M%S")".yaml"

    if [ -z $AIRFLOW__CORE__EXECUTOR ]; then
        AIRFLOW__CORE__EXECUTOR=$DEFAULT_AIRFLOW__CORE__EXECUTOR
    fi

    cat $template_file | \
        sed "s#<<GCP_PROJECT>>#$GCP_PROJECT#g" | \
        sed "s#<<AIRFLOW_SECRETS_NAME>>#$AIRFLOW_SECRETS_NAME#g" | \
        sed "s#<<AIRFLOW__CORE__EXECUTOR>>#$AIRFLOW__CORE__EXECUTOR#g" | \
        sed "s#<<AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER>>#$AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER#g" | \
        grep -v "^\s*#" | grep -v "^\s*$" > $deployment_file

    local cmd="kubectl create -f $deployment_file"
    echo $cmd && $cmd
    rm $deployment_file > /dev/null 2>&1
}

function __build_secrets_file {
    local sec_file=$1

    if [ -z $AIRFLOW__ADMIN ]; then
        AIRFLOW__ADMIN=$DEFAULT_AIRFLOW__ADMIN
    fi
    if [ -z $AIRFLOW__ADMIN_PASSWORD ]; then
        echo "Please enter airflow admin password:"
        read AIRFLOW__ADMIN_PASSWORD
    fi

    if [ -z $AIRFLOW__DB_USER ]; then
        AIRFLOW__DB_USER=$DEFAULT_AIRFLOW__DB_USER
    fi
    if [ -z $AIRFLOW__DB_PASSWORD ]; then
        echo "Please enter airflow internal database password:"
        read AIRFLOW__DB_PASSWORD
    fi
    if [ -z $AIRFLOW__DB_PASSWORD ]; then
        echo "Error! Password is not provided. " && exit
    fi
    AIRFLOW__CORE__SQL_ALCHEMY_CONN="postgresql+psycopg2://$AIRFLOW__DB_USER:$AIRFLOW__DB_PASSWORD@airflow-postgres/airflow"

    if [ -z $POSTGRES_HOST ]; then
        echo "Please enter external postgres host ip:"
        read POSTGRES_HOST
    fi
    if [ -z $POSTGRES_USER ]; then
        echo "Please enter external postgres user name:"
        read POSTGRES_USER
        if [ -z $POSTGRES_USER ]; then
            POSTGRES_USER=$DEFAULT_POSTGRES_USER
        fi
    fi
    if [ -z $POSTGRES_PASSWORD ]; then
        echo "Please enter external postgres user password:"
        read POSTGRES_PASSWORD
    fi
    if [ -z $POSTGRES_PASSWORD ]; then
        echo "Error! Password is not provided. " && exit
    fi

    AIRFLOW__ADMIN=$(echo -n $AIRFLOW__ADMIN | base64)
    AIRFLOW__ADMIN_PASSWORD=$(echo -n $AIRFLOW__ADMIN_PASSWORD | base64)
    AIRFLOW__DB_USER=$(echo -n $AIRFLOW__DB_USER | base64)
    AIRFLOW__DB_PASSWORD=$(echo -n $AIRFLOW__DB_PASSWORD | base64)
    AIRFLOW__CORE__SQL_ALCHEMY_CONN=$(echo -n $AIRFLOW__CORE__SQL_ALCHEMY_CONN | base64)
    POSTGRES_HOST=$(echo -n $POSTGRES_HOST | base64)
    POSTGRES_USER=$(echo -n $POSTGRES_USER | base64)
    POSTGRES_PASSWORD=$(echo -n $POSTGRES_PASSWORD | base64)

    cat $script_dir/$SECRETS_TEMPLATE | \
        sed "s#<<AIRFLOW_SECRETS_NAME>>#$AIRFLOW_SECRETS_NAME#g" | \
        sed "s#<<AIRFLOW__ADMIN>>#$AIRFLOW__ADMIN#g" | \
        sed "s#<<AIRFLOW__ADMIN_PASSWORD>>#$AIRFLOW__ADMIN_PASSWORD#g" | \
        sed "s#<<AIRFLOW__DB_USER>>#$AIRFLOW__DB_USER#g" | \
        sed "s#<<AIRFLOW__DB_PASSWORD>>#$AIRFLOW__DB_PASSWORD#g" | \
        sed "s#<<AIRFLOW__CORE__SQL_ALCHEMY_CONN>>#$AIRFLOW__CORE__SQL_ALCHEMY_CONN#g" | \
        sed "s#<<POSTGRES_HOST>>#$POSTGRES_HOST#g" | \
        sed "s#<<POSTGRES_USER>>#$POSTGRES_USER#g" | \
        sed "s#<<POSTGRES_PASSWORD>>#$POSTGRES_PASSWORD#g" | \
        grep -v "^\s*--" | grep -v "^\s*#" | grep -v "^\s*$" > $sec_file

    secrets_file_generated="true"
}

## -- main
if [ -z $image_names ] || [[ $image_names == "-h" ]] || [[ $image_names == "--help" ]]; then
    __help; exit
fi

if [ -z $secrets_file ] || [[ $secrets_file == "?" ]]; then
    secrets_file=$DEFAULT_SECRETS_FILE
fi

if [ ! -e $secrets_file ]; then
    __build_secrets_file $secrets_file
fi

## update secrets
kubectl delete secret $AIRFLOW_SECRETS_NAME > /dev/null 2>&1
kubectl create -f $secrets_file

# deployment
IFS=";"; read -a images <<< "${image_names}"; IFS=$default_ifs
for img in ${images[@]}; do
    if [[ $img == "airflow-postgres" ]]; then
        __deploy "$script_dir/$POSTGRES_DEPLOYMENT_TEMPLATE"
        echo "Initializing database, please wait..." && sleep 60 && echo "$img is deployed"
    elif [[ $img == "airflow-gcp" ]]; then
        __deploy "$script_dir/$AIRFLOW_DEPLOYMENT_TEMPLATE"
        echo "$img is deployed"
    fi
done

# clean up
if [[ $secrets_file_generated == "true" ]]; then
    echo "Remove generated secret file $sec_file [Y|Yes|N|No]?: "
    read remove_request
    if [ -z $remove_request ]; then
        remove_request="Yes"
    fi

    if [[ $remove_request == Y* ]]; then
        rm $secrets_file
    fi
fi
