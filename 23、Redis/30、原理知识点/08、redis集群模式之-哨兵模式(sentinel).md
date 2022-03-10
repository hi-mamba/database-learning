
## [原文2](https://phachon.com/redis/redis-2.html)

## [原文1](https://minichou.github.io/2016/03/25/Redis%20Sentinel%E5%8E%9F%E7%90%86/)

## [原文3](https://juejin.im/post/5d0f7da66fb9a07ef44410db)

# redis集群模式之-哨兵模式(sentinel)


## 简介
哨兵模式是一种特殊的模式，哨兵是一个独立的进程，通过发送命令，
等待Redis服务器响应，从而监控多个Redis实例

在Redis高可用架构中，Sentinel往往不是只有一个，而是有3个或者以上。
目的是为了让其更加可靠，我们可以使用`多个哨兵`进行监控。
`各个哨兵之间还会进行监控`，这样就形成了多哨兵模式


哨兵可以有多个，一般为了便于决策选举，使用奇数个哨兵。
哨兵可以和 redis 机器部署在一起，也可以部署在其他的机器上。
多个哨兵构成一个哨兵集群，哨兵直接也会相互通信，检查哨兵是否正常运行，
同时发现 `master 宕机`哨兵之间会进行决策选举新的 master
![image](https://user-images.githubusercontent.com/7867225/157563408-7c64b954-0df6-49b0-90e4-20721299b09e.png)



[redis三种集群模式](../03、基础知识/30、redis三种集群模式.md)

## 实现原理

## 选举过程

### 主观下线和客观下线

#### 1、主观下线
Sentinel集群的每一个Sentinel节点会定时对redis集群的所有节点发`心跳包`检测节点是否正常。
如果一个节点在down-after-milliseconds时间内没有回复Sentinel节点的心跳包，
则该redis节点被`该Sentinel节点`主观下线。

#### 2、客观下线
当节点被一个Sentinel节点记为主观下线时，并不意味着该节点肯定故障了，
还需要Sentinel集群的其他Sentinel节点`共同判断`为主观下线才行。  

该Sentinel节点会询问其他Sentinel节点，如果Sentinel集群中`超过quorum数量`的Sentinel节点认为该redis节点主观下线，
则该redis客观下线。

如果客观下线的redis节点是从节点或者是Sentinel节点，则操作到此为止，没有后续的操作了；
如果客观下线的redis节点为`主节点`，则`开始故障转移`，从从节点中选举一个节点升级为主节点

 
### 领头哨兵的选举(Sentinel集群选举Leader(master))
为什么要选领导者？因为只能有一个sentinel节点去完成`故障转移`

> Sentinel 自动故障迁移`使用 Raft 算法`来选举领头（leader） Sentinel ，
从而确保在一个给定的纪元（epoch）里， 只有一个领头产生。

如果一个 Redis 节点被标记为`客观下线`，那么所有监控改服务的哨兵进程会进行协商，选举出一个`领头的哨兵`，
对 Redis 服务进行`转移故障`操作。领头哨兵的选举大概遵循以下原则：

sentinel is-master-down-by-addr 这个命令有两个作用，一是确认下线判定，二是进行领导者选举。

1. 每个`做主观下线`的sentinel节点向其他sentinel节点发送上面那条命令，要求将它设置为领导者。

2. 收到命令的sentinel节点如果还没有同意过其他的sentinel发送的命令（还未投过票），那么就会同意，否则拒绝。

3. 如果该sentinel节点发现自己的票数已经过半且达到了`quorum的值`，就会成为领导者

4. 如果这个过程`出现多个sentinel成为领导者`，则会`等待一段时间`重新选举。

### redis sentinel模式下，如何选举新的master

Sentinel 使用以下规则来选择新的主服务器：

- 删除列表中所有处于下线或者短线状态的Slave。
- 删除列表中所有最近5s内没有回复过领头Sentinel的INFO命令的Slave。
- 删除所有与下线Master连接断开超过down-after-milliseconds * 10毫秒的Slave。
- 领头Sentinel将根据`Slave优先级`，对列表中剩余的Slave进行排序，并`选出其中优先级最高的Slave`。
如果有多个具有相同优先级的Slave，那么领头Sentinel将按照Slave复制偏移量，`选出其中偏移量最大的Slave`。
如果有多个优先级最高，偏移量最大的Slave，那么`根据运行ID最小原则选出新的Master`。

确定新的Master之后，领头Sentinel会以每秒一次的频率向新的Master发送SLAVEOF no one命令，
当得到确切的回复role由slave变为master之后，当前服务器顺利升级为Master服务器。

当选出新的Master服务器后，领头Sentinel会让之前下线Master的Slave发送SLAVEOF命令，让它们复制新的Master。

### 为什么Sentinel集群至少3节点

一个Sentinel节选举成为Leader的最低票数为quorum和`Sentinel节点数/2+1的最大值`，
如果Sentinel集群只有2个Sentinel节点，则
```
Sentinel节点数/2 + 1
= 2/2 + 1
= 2
```
即Leader最低票数至少为2，当该Sentinel集群中由一个Sentinel节点故障后，
仅剩的一个Sentinel节点是永远无法成为Leader。   
也可以由此公式可以推导出，`Sentinel集群允许1个Sentinel节点故障则需要3个节点的集群`；允许2个节点故障则需要5个节点集群。
 
## 故障转移

哨兵模式最大的优点即可以进行故障转移，提高了服务的高可用。故障转移分为三个步骤：

- 从下线的主节点所有的从节点中挑选一个从节点，将其转成主节点
选举出来的`领头哨兵`从列表中选择优先级最高的，如果优先级都一样，则选择偏移量大的（偏移量大说明数据比较新），如果偏移量一样，则选择`运行ID`比较小的

- 将已下线的主节点的所有从节点改为向新的主节点进行复制
挑选出来了新的主节点服务之后，`领头哨兵`会向原主节点的所有从节点发送` slaveof `新主节点的命令，复制新的 Master

- 当已下线的原主节点恢复服务时，复制新的主节点，变成新主节点的从节点
当已下线的服务重新上线时，sentinel会向其发送 slaveof 命令，让其成为新主节点的从节点

## Sentinel与redis实例之间的通信

PING ：返回 PONG

<https://minichou.github.io/2016/03/25/Redis%20Sentinel%E5%8E%9F%E7%90%86/>

## 同步原理（复制原理）

## 哨兵模式缺点
具有主从模式的缺点，每台机器上的数据是一样的，内存的可用性较低。

Redis 较难支持在线扩容，在集群容量达到上限时在线扩容会变得很复杂。

## 哨兵模式优点

哨兵模式是基于主从模式的，所有主从的优点，哨兵模式都具有。

主从可以自动切换，系统更健壮，可用性更高。

##




