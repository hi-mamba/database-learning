## [原文](https://www.jianshu.com/p/eec60672a4da)

# redis怎么动态添加内存，动态配置，无需重启


在redis的使用过程中，有时候需要修改redis的配置，如在业务运行的情况下，内存不够怎么办，这时要么赶紧删除无用的内存，要么扩展内存。
如果有无用的内容可删除那么所有问题都已经解决。如果内容都是重要的，那只能选择扩展内存。
说到扩展内存，redis为我们提供了一个动态调整的命令。
```bash
CONFIG SET （官网https://redis.io/commands/config-set）
CONFIG SET parameter value

```
CONFIG SET 命令可以动态地调整 Redis 服务器的配置(configuration)而无须重启。

你可以使用它修改配置参数，或者改变 Redis 的持久化(Persistence)方式。

CONFIG SET 可以修改的配置参数可以使用命令 CONFIG GET * 来列出，所有被 CONFIG SET 修改的配置参数都会立即生效。

关于 CONFIG SET 命令的更多消息，请参见命令 CONFIG GET 的说明。

关于如何使用 CONFIG SET 命令修改 Redis 持久化方式，请参见 Redis Persistence 。

可用版本：
```
>= 2.0.0
时间复杂度：
不明确
返回值：
当设置成功时返回 OK ，否则返回一个错误。

```
我们看看那些参数 redis可以动态设置
```bash
127.0.0.1:6379> CONFIG GET *

```

```bash
# 当配置中需要配置内存大小时，可以使用 1k, 5GB, 4M 等类似的格式，其转换方式如下(不区分大小写)
#
# 1k => 1000 bytes
# 1kb => 1024 bytes
# 1m => 1000000 bytes
# 1mb => 1024*1024 bytes
# 1g => 1000000000 bytes
# 1gb => 1024*1024*1024 bytes
#
# 内存配置大小写是一样的.比如 1gb 1Gb 1GB 1gB

所以如果要改为9g，则换算后为：9*1024*1024*1024=9635364864


```

## 例子

获取当前值

```bash
redis 127.0.0.1:6381> config get maxmemory

1) "maxmemory"

2) "7516192768" 

```

设置新数值 
> 设置 20Mb , 1024 * 1024 * 20

> 1024kb * 1024kb * 10 = 10485760 kb

```bash
172.23.3.19:7002> config set maxmemory 20971520
OK
```

或者这样设置
```bash
172.23.3.19:7002> config set maxmemory 100MB
OK

```
```bash
172.23.3.19:7005> CONFIG GET maxmemory
1) "maxmemory"
2) "31457280"
```

## [how to allocate maximum memory for the Redis ](https://www.techrunnr.com/how-to-allocate-maximum-memory-for-the-redis-server/)

修改配置文件,这里需要重启
```bash
vi /etc/redis/redis.conf

maxmemory 100MB
```