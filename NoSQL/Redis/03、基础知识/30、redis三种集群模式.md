
## [原文1](https://phachon.com/redis/redis-1.html)

## [原文2](http://kwin.xyz/passages/Tools/Redis/Redis-Sentinel/)

# redis三种集群模式

我们常用sharding技术来对此进行管理，其集群模式主要有以下几种方式：

- 主从复制
- 哨兵模式
- Redis官方 Cluster集群模式（服务端sharding）

- Jedis sharding集群（客户端sharding）
- 利用中间件代理

主要看这三种集群模式， 主从复制 、哨兵机制 、cluster   


## 1. 主从复制

### 什么是主从同步 
简单来说，主从同步 就是指以一个主节点作为基准节点，将数据同步给从节点，使得主从节点的数据保持一致。
这里的主节点一般也称为 Master 节点，从节点一般也叫做 Slave 节点。一个 Master 节点可以

拥有多个 Slave 节点。这种架构就叫做 一主多从 的主从架构。如果每一个 Slave 节点也作为基准节点，
同时也拥有多个 Slave 节点，那么这中架构就叫做 级联结构的主从架构。本篇文章仅研究 一主多从主从架构。

### Redis 主从同步 架构
![](../../../images/redis/cluster/redis_master_slave_01.png)
一主多从&级联结构图

通过redis的复制功能可以很好的实现数据库的读写分离，提高服务器的负载能力。
主数据库主要进行写操作，而从数据库负责读操作。

![](../../../images/redis/cluster/redis_master_slave_02.png)

> 我们不难看出Redis在主从模式下，必须保证主节点不会宕机——一旦主节点宕机，
其它节点不会竞争称为主节点，此时，Redis将丧失写的能力。这点在生产环境中，是致命的

一旦主节点宕机，从节点晋升成主节点，同时需要修改应用方的主节点地址，还需要命令所有从节点去复制新的主节点，
`整个过程需要人工干预`。

### 主从复制问题
- 手动故障转移
- 写能力和存储能力受限

### Redis 主从同步的优缺点
优点
- 同一个 Master 可以部署多个 Slave
- Slave 还可以接受其他的 Slave 的连接和同步，即所谓的 级联结构。有效的减轻 Master 的压力
- 主从同步期间，主从节点均是非阻塞。不影响服务的查询和写入
- 可以很好的实现读写分离的架构，系统的伸缩性得到提高

缺点
- 主机的宕机会非常严重，导致整个数据不一致的问题。
- 全量的复制的过程中，必须保证主节点必须有足够的内存。若快照的文件过大，还会对集群的服务能力产生影响。

## 2. 哨兵机制

sentinel是一个独立于redis之外的进程，不对外提供key/value服务，
在redis的安装目录下名称叫redis-sentinel。主要用来`监控redis-server`进程，进行`master/slave管理`

> 当采用 Master-Slave 的高可用方案时候，如果 Master 宕机之后，`想自动切换`，可以`考虑使用哨兵模式`。
哨兵模式其实是在主从模式的基础上工作的。

###  什么是哨兵模式(Redis Sentinel)

Redis Sentinel是一个分布式架构，包含若干个Sentinel节点和Redis数据节点，
每个Sentinel节点会对数据节点和其余Sentinel节点进行监控，当发现节点不可达时，会对节点做下线标识。

如果被标识的是主节点，他还会选择和其他Sentinel节点进行“协商”，当大多数的Sentinel节点都认为主节点不可达时，
他们会选举出一个Sentinel节点来完成自动故障转移工作，同时将这个变化通知给Redis应用方。
哨兵（Sentinel）模式下会启动多个哨兵进程。

### Redis Sentinel架构
![](../../../images/redis/cluster/redis_sentinel_01.png)

客户端访问
![](../../../images/redis/cluster/redis_sentinel_03.png)
 
### 哨兵进程的作用如下：
 
- 监控：能持续的监控 Redis 集群中主从节点的工作状态
- 通知：当被监控的节点出现问题之后，能通过 API 来通知系统管理员或其他程序
- 自动故障迁移(Automatic failover)：如果`发现主节点无法正常工作`，`哨兵进程将启动故障恢复机制把一个从节点提升为主节点`，
其他的从节点将会重新配置到新的主节点，并且应用程序会得到一个更换新地址的通知

### 哨兵机制简介

1）Sentinel(哨兵) 进程是用于监控 Redis 集群中 Master 主服务器工作的状态

2）在 Master 主服务器发生故障的时候，可以实现 Master 和 Slave 服务器的切换，保证系统的高可用（High Availability）

3）哨兵机制被集成在 Redis2.6+ 的版本中，到了2.8版本后就稳定下来了。

## 3. cluster
 
