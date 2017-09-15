# tidb-playground
Handy shell scripts for launcing tidb cluster(tidb/tikv/pd) in single machine.

## Usage

1. Modify `tikvs` file, specify the addresses of tikv-server.
2. `cluster.sh [start|stop|clean]`

You can change endpoint of tidb-server/pd-server by setting environment variables.
For example:
```
PD_ADDR=127.0.0.1:2380 cluster.sh start
PD_ADDR=127.0.0.1:2380 TIDB_ADDR=127.0.0.1:5000 cluster.sh start
```
