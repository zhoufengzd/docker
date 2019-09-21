#!/usr/bin/env bash
## download gcp_sdk and update gcp_sdk home
wk_dir=$(pwd)

## Check latest version at https://cloud.google.com/sdk/downloads
gcp_sdk_package="google-cloud-sdk-197.0.0-linux-x86_64.tar.gz"
dl_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$gcp_sdk_package"
echo wget $dl_url
echo "..."
wget $dl_url && tar -xzf $gcp_sdk_package && rm $gcp_sdk_package

gsdk_home=$(ls -d google-cloud-sdk)
GOOGLE_SDK_HOME="$wk_dir/$gsdk_home"
echo ""  >> setup_env.sh
echo "export GOOGLE_SDK_HOME=\"$GOOGLE_SDK_HOME\"" >> setup_env.sh
echo "export PATH=\"\$GOOGLE_SDK_HOME/bin\":\$PATH" >> setup_env.sh

## update to latest version
$GOOGLE_SDK_HOME/bin/gcloud components update --quiet
