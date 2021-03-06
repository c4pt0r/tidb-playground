#!/bin/bash

PD_ADDR=${PD_ADDR:-"127.0.0.1:2379"}
#TIDB_ADDR=${TIDB_ADDR:-"127.0.0.1:4000"}

# defualt settings
LOG_LEVEL=info

BIN_DIR=`pwd`/bin
CONF_DIR=`pwd`/etc
LOG_DIR=`pwd`/log
DATA_DIR=`pwd`/data
PID_DIR=`pwd`/pid

# TODO linux only, should download correct binaries according to system
download_binaries() {
    mkdir .download
    cd .download
        wget http://download.pingcap.org/tidb-latest-linux-amd64.tar.gz
        tar -xzf tidb-latest-linux-amd64.tar.gz
        cp tidb-latest-linux-amd64/bin/* $BIN_DIR/
    cd -
}

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


launch_multi_tidb() {
    pd=$2
    echo $1 | sed -e "s/:/ /g" | while read ip port status_port
    do
        echo $ip $port $status_port
        $BIN_DIR/tidb-server -host $ip \
            -advertise-address $ip \
            -P $port \
            -status $status_port \
            -store tikv \
            --path=$pd \
            -log-file $LOG_DIR/tidb.log \
            >/dev/null & 
        echo $! >> $PID_DIR/pids
    done
}

launch_pd() {
    $BIN_DIR/pd-server \
        -client-urls http://$PD_ADDR \
        -data-dir $DATA_DIR/pd \
        -log-file $LOG_DIR/pd.log \
        > /dev/null &
    echo $! >> $PID_DIR/pids
}

launch_tikv() {
    addr=$1
    id=$2
    pd=$3
    $BIN_DIR/tikv-server -C $CONF_DIR/tikv.toml \
        --addr $addr \
        -L $LOG_LEVEL \
        -s $DATA_DIR/tikv$id \
        -f $LOG_DIR/tikv.log.$id \
        --pd-endpoints $pd >/dev/null &

    echo $! >> $PID_DIR/pids
}

start() {
    stop_all
    init

    echo "Lauching PD server...$PD_ADDR"
    launch_pd
    # check if pd is alive
    alive=0
    for i in `seq 1 5`
    do
        echo "checking pd status..."
        sleep 1
        $BIN_DIR/pd-ctl -d ping --pd http://$PD_ADDR > /dev/null
        if [ $? -eq 0 ]
        then
            echo "OK"
            alive=1
            break
        fi
    done

    if [ $alive -eq 0 ]
    then
        echo "Launching PD server failed..."
        exit 1
    fi

    id=0
    while read kv; do
        id=$((id+1))
        echo "Lauching TiKV server $id...$kv"
        launch_tikv $kv $id $PD_ADDR
    done < tikvs
    sleep 3

    
    if [ "$1" == "all" ]; then
        echo "Lauching TiDB server..."

        while read tidb; do
            launch_multi_tidb $tidb $PD_ADDR
        done < tidbs

        sleep 3

        echo "Start local cluster successfully...Enjoy it!"
        echo
        echo "use MySQL client to connect:"

        while read tidb; do
            echo $tidb | sed -e "s/:/ /g" | while read ip port status_port
            do
                echo "mysql --host $ip -P $port -u root test"
            done
        done < tidbs

        echo
        echo "tail logs:"
        echo "tail -f $LOG_DIR/tidb.log $LOG_DIR/pd.log $LOG_DIR/tikv.log.*"
    else
        echo "tail logs:"
        echo "tail -f $LOG_DIR/pd.log $LOG_DIR/tikv.log.*"
    fi
}


# check binaries
if [ -f $BIN_DIR/tikv-server -a -f $BIN_DIR/tidb-server -a -f \
    $BIN_DIR/pd-server ]; then
    :
else
    download_binaries
fi

case $1 in
    start) start all ;;
    start-kv) start kv;;
    stop) stop_all ;;
    clean) clean_all ;;
    *) echo "$0 [start|start-kv|stop|clean]" ;;
esac

