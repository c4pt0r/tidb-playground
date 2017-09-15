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


```
dongxu:tidb-cluster/ (master) $ ./cluster.sh start
Lauching PD server...
Lauching TiKV servers...
Lauching TiDB server...
Start local cluster successfully...Enjoy it!

dongxu:tidb-cluster/ (master) $ echo store | ./bin/pd-ctl  | jq ".stores[].store"
{
  "id": 2,
  "address": "127.0.0.1:20161",
  "state": 0,
  "state_name": "Up"
}
{
  "id": 3,
  "address": "127.0.0.1:20162",
  "state": 0,
  "state_name": "Up"
}
{
  "id": 1,
  "address": "127.0.0.1:20160",
  "state": 0,
  "state_name": "Up"
}
```
