#!/bin/sh

PD_ADDR=${PD_ADDR:-"127.0.0.1:2379"}
TIDB_ADDR=${TIDB_ADDR:-"127.0.0.1:4000"}

# defualt settings
LOG_LEVEL=info

BIN_DIR=`pwd`/bin
CONF_DIR=`pwd`/etc
LOG_DIR=`pwd`/log
DATA_DIR=`pwd`/data
PID_DIR=`pwd`/pid


init() {
    mkdir -p $DATA_DIR
    mkdir -p $LOG_DIR
    mkdir -p $PID_DIR
}

stop_all() {
    # kill processes
    if [ -f $PID_DIR/pids ]
    then
        while read p; do
            kill -9 $p
        done < $PID_DIR/pids
        # remove pid file
        rm -rf $PID_DIR/pids
    fi
}

clean_all() {
    stop_all
    rm -rf $PID_DIR $LOG_DIR $DATA_DIR
}

launch_tidb() {
    echo $TIDB_ADDR | sed -e "s/:/ /" | while read ip port
    do
        nohup $BIN_DIR/tidb-server -host $ip \
            -P $port \
            -store tikv://$PD_ADDR/pd \
            -log-file $LOG_DIR/tidb.log \
            >/dev/null & 
        echo $! >> $PID_DIR/pids
    done
}

launch_pd() {
    nohup $BIN_DIR/pd-server \
        -client-urls http://$PD_ADDR \
        -data-dir $DATA_DIR/pd \
        -log-file $LOG_DIR/pd.log \
        &> /dev/null &
    echo $! >> $PID_DIR/pids
}

launch_tikv() {
    addr=$1
    id=$2
    pd=$3
    nohup $BIN_DIR/tikv-server -C $CONF_DIR/tikv.toml \
        --addr $addr \
        -L $LOG_LEVEL \
        -s $DATA_DIR/tikv$id \
        -f $LOG_DIR/tikv.log.$id \
        --pd-endpoints $pd >/dev/null &

    echo $! >> $PID_DIR/pids
}

start_all() {
    stop_all
    init

    echo 'Lauching PD server...'
        launch_pd
    sleep 3

    echo 'Lauching TiKV servers...'
    id=0
    while read kv; do
        id=$((id+1))
        launch_tikv $kv $id $PD_ADDR
    done < tikvs
    sleep 3

    echo 'Lauching TiDB server...'
        launch_tidb
    sleep 3

    echo 'Start local cluster successfully...Enjoy it!'
    sleep 3

    echo "tail -f $LOG_DIR/tidb.log $LOG_DIR/pd.log $LOG_DIR/tikv.log.*"
}

case $1 in
    start) start_all ;;
    stop) stop_all ;;
    clean) clean_all ;;
    *) echo "$0 [start|stop|clean]" ;;
esac
