#!/usr/bin/env bash
## gcloud config

if [ ! -z $GCP_PROJECT ]; then
    gcloud config set project $GCP_PROJECT --quiet
fi
