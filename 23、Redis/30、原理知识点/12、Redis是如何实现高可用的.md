
<https://juejin.cn/post/6997944007812710414>

# Redis是如何实现高可用的？

## Redis 高可用的手段主要有以下四种：

- 数据持久化

- 主从数据同步（主从复制）

- Redis 哨兵模式（Sentinel）

- Redis 集群（Cluster）


##  数据持久化
`持久化`功能是 Redis 和 Memcached 的主要区别之一，因为只有 Redis 提供了此功能。

在 Redis 4.0 之前数据持久化方式有两种：`AOF `方式和 `RDB `方式。

- RDB（Redis DataBase，快照方式）是将`某一个时刻`的`内存数据`，以`二进制`的方式写入磁盘。
- AOF（Append Only File，`文件追加`方式）是指将所有的操作命令，以文本的形式追加到文件中。


### RDB

RDB 默认的保存文件为 `dump.rdb`，优点是以`二进制`存储的，因此占用的`空间更小`、`数据存储更紧凑`，
并且与 AOF 相比，RDB 具备更快的`重启恢复能力`。

### AOF
AOF 默认的保存文件为 appendonly.aof，它的优点是存储频率更高，
因此丢失数据的风险就越低，并且 AOF 并`不是以二进制存储`的，
所以它的存储信息更易懂。缺点是`占用空间大`，重启之后的`数据恢复速度比较慢`。


### 混合持久化
于是在 Redis 4.0 就推出了混合持久化的功能。

混合持久化的功能指的是 Redis 可以使用 `RDB + AOF `两种格式来进行数据持久化，
这样就可以做到扬长避短物尽其用了。
我们可以使用`config get aof-use-rdb-preamble`的命令来查询 Redis 混合持久化的功能是否开启，
执行示例如下：

```shell
127.0.0.1:6379> config get aof-use-rdb-preamble
1) "aof-use-rdb-preamble"
2) "yes"
```
如果执行结果为`“no”`则表示混合持久化功能关闭，不过我们可以使用`config set aof-use-rdb-preamble yes`
的命令打开此功能。

Redis 混合持久化的存储模式是，`开始的数据`以 RDB 的格式进行存储，
因此只会占用少量的空间，并且`之后的命令`会以 AOF 的方式进行数据追加，
这样就可以减低数据丢失的风险，同时可以提高数据恢复的速度。

