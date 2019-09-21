#!/usr/bin/env bash
## download cloudsql proxy
wk_dir=$(pwd)

wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy
