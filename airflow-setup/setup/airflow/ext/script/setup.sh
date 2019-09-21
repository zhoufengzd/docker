#!/usr/bin/env bash
## download required jdk, mvn, gcp_sdk, cloud_sql libraries

mkdir -p $AIRFLOW_HOME/env
cd $AIRFLOW_HOME/env

chmod +x $AIRFLOW_HOME/ext/script/*.sh
echo "#!/usr/bin/env bash"  > setup_env.sh
echo "export PATH=\"\$AIRFLOW_HOME/env\":\$PATH" >> setup_env.sh
$AIRFLOW_HOME/ext/script/download_gcp_sdk.sh
$AIRFLOW_HOME/ext/script/download_cloudsql_proxy.sh
$AIRFLOW_HOME/ext/script/download_jdk.sh
$AIRFLOW_HOME/ext/script/download_mvn.sh
rm $AIRFLOW_HOME/ext/script/download_*.sh

echo "source \$AIRFLOW_HOME/env/setup_env.sh" >> $AIRFLOW_HOME/.bashrc
echo "if [ \"\$BASH\" ]; then source \$AIRFLOW_HOME/ext/script/_bash_profile; fi" >> $AIRFLOW_HOME/.profile
ln -s $AIRFLOW_HOME/ext/script/_bash_profile $AIRFLOW_HOME/.bash_profile

cd $AIRFLOW_HOME
