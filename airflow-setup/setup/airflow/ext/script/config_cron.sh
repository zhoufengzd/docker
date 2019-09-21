#!/usr/bin/env bash
## cron job to sync source and dags

cat $AIRFLOW_HOME/ext/script/git_sync.crontab | \
    sed "s#<<AIRFLOW_HOME>>#$AIRFLOW_HOME#g" > tmp.crontab \
    && crontab tmp.crontab && rm tmp.crontab

### cron environment variables
cron_env_file="/var/spool/cron/cron_env.sh"
echo "#!/usr/bin/env bash"  > $cron_env_file

echo "" >> $cron_env_file
echo "AIRFLOW_HOME=$AIRFLOW_HOME" >> $cron_env_file
if [ ! -z $AIRFLOW__CORE__SQL_ALCHEMY_CONN ]; then
    echo "AIRFLOW__CORE__SQL_ALCHEMY_CONN=$AIRFLOW__CORE__SQL_ALCHEMY_CONN" >> $cron_env_file
fi
if [ ! -z $AIRFLOW__CORE__EXECUTOR ]; then
    echo "AIRFLOW__CORE__EXECUTOR=$AIRFLOW__CORE__EXECUTOR" >> $cron_env_file
fi
if [ ! -z $AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER ]; then
    echo "AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=$AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER" >> $cron_env_file
fi
echo "" >> $cron_env_file
echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> $cron_env_file

# jdk / mvn / google_sdk
echo "" >> $cron_env_file
echo "source \$AIRFLOW_HOME/env/setup_env.sh" >> $cron_env_file
