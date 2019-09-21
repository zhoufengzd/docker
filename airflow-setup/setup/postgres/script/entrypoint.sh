#!/usr/bin/env bash

cleanup ()
{
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

# /usr/lib/postgresql/${PG_VERSION}/bin/postgres -D /var/lib/postgresql/${PG_VERSION}/main -c config_file=/etc/postgresql/${PG_VERSION}/main/postgresql.conf
/etc/init.d/postgresql start
/init_db.sh

idx=0
while [ 1 ]
do
    clear

    # check service every 60 seconds
    psql_pid=$(ps -ef | grep bin/postgres | grep -v "grep" | awk '{print $2}')
    if [ -z $psql_pid ]; then
        echo "postgresql service crashed!";
        break
    fi

    idx=$((idx+1))
    if [ $idx -gt 1000000 ]; then idx=0; fi
    echo "postgresql is running... counter = $idx"
    sleep 60 &
    wait $!
done
