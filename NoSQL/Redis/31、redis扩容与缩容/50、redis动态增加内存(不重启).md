## [原文](https://www.jianshu.com/p/eec60672a4da)

# redis动态增加内存(不重启)

在redis的使用过程中，有时候需要修改redis的配置，如在业务运行的情况下，内存不够怎么办，这时要么赶紧删除无用的内存，要么扩展内存。
如果有无用的内容可删除那么所有问题都已经解决。如果内容都是重要的，那只能选择扩展内存。

说到扩展内存，redis为我们提供了一个动态调整的命令。

CONFIG SET （官网<https://redis.io/commands/config-set>）
```bash
CONFIG SET parameter value

```
CONFIG SET 命令可以动态地调整 Redis 服务器的配置(configuration)而无须重启。
你可以使用它修改配置参数，或者改变 Redis 的持久化(Persistence)方式。
CONFIG SET 可以修改的配置参数可以使用命令 CONFIG GET * 来列出，所有被 CONFIG SET 修改的配置参数都会立即生效。
关于 CONFIG SET 命令的更多消息，请参见命令 CONFIG GET 的说明。

关于如何使用 CONFIG SET 命令修改 Redis 持久化方式，请参见 Redis Persistence 。

可用版本：
\>= 2.0.0
时间复杂度：
不明确
返回值：
当设置成功时返回 OK ，否则返回一个错误。

例：动态添加内存 3G到10G

## 1、获取当前值

```bash
redis 127.0.0.1:6379> config get maxmemory

"maxmemory"
"3221225472"
```
## 2、设置新数值
```bash
redis 127.0.0.1:6379> config set maxmemory 10737418240
OK
```
### 3、查看修改后的值
```bash
redis 127.0.0.1:6379> CONFIG GET maxmemory

"maxmemory"
"10737418240"

```
我们看看那些参数 redis可以动态设置

```bash
127.0.0.1:6379> CONFIG GET *

"dbfilename"
"dump.rdb"
"requirepass"
"123456"
"masterauth"
""
"unixsocket"
""
"logfile"
"/diskc/redis-2.8.19/log/6379_slave.log"
"pidfile"
"/var/run/redis.pid"
"maxmemory"
"10737418240"
"maxmemory-samples"
"3"
"timeout"
"0"
"tcp-keepalive"
"0"
"auto-aof-rewrite-percentage"
"100"
"auto-aof-rewrite-min-size"
"67108864"
"hash-max-ziplist-entries"
"512"
"hash-max-ziplist-value"
"64"
"list-max-ziplist-entries"
"512"
"list-max-ziplist-value"
"64"
"set-max-intset-entries"
"512"
"zset-max-ziplist-entries"
"128"
"zset-max-ziplist-value"
"64"
"hll-sparse-max-bytes"
"3000"
"lua-time-limit"
"5000"
"slowlog-log-slower-than"
"100000"
"latency-monitor-threshold"
"0"
"slowlog-max-len"
"128"
"port"
"6379"
"tcp-backlog"
"511"
"databases"
"16"
"repl-ping-slave-period"
"10"
"repl-timeout"
"60"
"repl-backlog-size"
"1048576"
"repl-backlog-ttl"
"3600"
"maxclients"
"15000"
"watchdog-period"
"200"
"slave-priority"
"100"
"min-slaves-to-write"
"0"
"min-slaves-max-lag"
"10"
"hz"
"10"
"repl-diskless-sync-delay"
"5"
"no-appendfsync-on-rewrite"
"no"
"slave-serve-stale-data"
"yes"
"slave-read-only"
"yes"
"stop-writes-on-bgsave-error"
"yes"
"daemonize"
"yes"
"rdbcompression"
"yes"
"rdbchecksum"
"yes"
"activerehashing"
"yes"
"repl-disable-tcp-nodelay"
"no"
"repl-diskless-sync"
"no"
"aof-rewrite-incremental-fsync"
"yes"
"aof-load-truncated"
"yes"
"appendonly"
"no"
"dir"
"/diskc/redis-2.8.19"
"maxmemory-policy"
"volatile-lru"
"appendfsync"
"everysec"
"save"
"900 1 300 10 60 10000"
"loglevel"
"notice"
"client-output-buffer-limit"
"normal 0 0 0 slave 268435456 67108864 60 pubsub 33554432 8388608 60"
"unixsocketperm"
"0"
"slaveof"
""
"notify-keyspace-events"
""
"bind"
""
```