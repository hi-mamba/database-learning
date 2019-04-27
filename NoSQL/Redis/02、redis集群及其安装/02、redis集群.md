## [原文](https://www.cnblogs.com/cjsblog/p/9048545.html)

# Redis集群

## 集群简单概念
Redis集群提供一种方式自动将数据分布在多个Redis节点上。

> redis集群就是分区的一种的实现

> 槽 slot

## 1、Redis集群TCP端口（Redis Cluster TCP ports）
每个Redis集群中的节点都需要打开两个TCP连接。一个连接用于正常的给Client提供服务，比如6379，
还有一个额外的端口（通过在这个端口号上加10000）作为数据端口，比如16379。
第二个端口（本例中就是16379）用于集群总线，这是一个用二进制协议的点对点通信信道。
这个集群总线（Cluster bus）用于节点的失败侦测、配置更新、故障转移授权，等等。

客户端从来都不应该尝试和这些集群总线端口通信，它们只应该和正常的Redis命令端口进行通信。
注意，确保在你的防火墙中开放着两个端口，否则，Redis集群节点之间将无法通信。

命令端口和集群总线端口的偏移量总是10000。

注意，如果想要集群按照你想的那样工作，那么集群中的每个节点应该：

1. 正常的客户端通信端口（通常是6379）用于和所有可到达集群的所有客户端通信
2. 集群总线端口（the client port + 10000）必须对所有的其它节点是可到达的

也就是，要想集群正常工作，集群中的每个节点需要做到以下两点：

1. 正常的客户端通信端口（通常是6379）必须对所有的客户端都开放，换言之，所有的客户端都可以访问
2. 集群总线端口（客户端通信端口 + 10000）必须对集群中的其它节点开放，换言之，其它任意节点都可以访问

如果你没有开放TCP端口，你的集群可能不会像你期望的那样工作。集群总线用一个不同的二进制协议通信，用于节点之间的数据交换

## 2、Redis集群数据分片（Redis Cluster data sharding）
Redis集群不同一致性哈希，它用一种不同的分片形式，在这种形式中，每个key都是一个概念性（hash slot）的一部分。

Redis集群中有16384个hash slots，为了计算给定的key应该在哪个hash slot上，
我们简单地用这个key的CRC16值来对16384取模。（即：key的CRC16  %  16384）

Redis集群中的每个节点负责一部分hash slots，假设你的集群有3个节点，那么：

- Node A contains hash slots from 0 to 5500
- Node B contains hash slots from 5501 to 11000
- Node C contains hash slots from 11001 to 16383

允许添加和删除集群节点。比如，如果你想增加一个新的节点D，那么久需要从A、B、C节点上删除一些hash slot给到D。
同样地，如果你想从集群中删除节点A，那么会将A上面的hash slots移动到B和C，当节点A上是空的时候就可以将其从集群中完全删除。

因为将hash slots从一个节点移动到另一个节点并不需要停止其它的操作，添加、删除节点以及更改节点所维护的hash slots的百分比都不需要任何停机时间。
也就是说，移动hash slots是并行的，移动hash slots不会影响其它操作。

Redis支持多个key操作，只要这些key在一个单个命令中执行（或者一个事务，或者Lua脚本执行），
那么它们就属于相同的hash slot。你也可以用hash tags俩强制多个key都在相同的hash slot中。

## 3、Redis集群主从模式（Redis Cluster master-slave model）

当部分master节点失败了，或者不能够和大多数节点通信的时候，为了保持可用，Redis集群用一个master-slave模式，这样的话每个hash slot就有1到N个副本。

在我们的例子中，集群有A、B、C三个节点，如果节点B失败了，那么5501-11000之间的hash slot将无法提供服务。
然而，当我们给每个master节点添加一个slave节点以后，我们的集群最终会变成由A、B、C三个master节点和A1、B1、C1三个slave节点组成，
这个时候如果B失败了，系统仍然可用。节点B1是B的副本，如果B失败了，集群会将B1提升为新的master，从而继续提供服务。
然而，如果B和B1同时失败了，那么整个集群将不可用。

## 4、Redis集群一致性保证（Redis Cluster consistency guarantees）
 
Redis集群不能保证强一致性。换句话说，Redis集群可能会丢失一些写操作。

Redis集群可能丢失写的第一个原因是因为它用异步复制。

写可能是这样发生的：

- 客户端写到master B
- master B回复客户端OK
- master B将这个写操作广播给它的slaves B1、B2、B3

正如你看到的那样，B没有等到B1、B2、B3确认就回复客户端了，也就是说，B在回复客户端之前没有等待B1、B2、B3的确认，
这对应Redis来说是一个潜在的风险。所以，如果客户端写了一些东西，B也确认了这个写操作，
但是在它将这个写操作发给它的slaves之前它宕机了，随后其中一个slave（没有收到这个写命令）可能被提升为新的master，
于是这个写操作就永远丢失了。

这和大多数配置为每秒刷新一次数据到磁盘的情况是一样的。你可以通过强制数据库在回复客户端以前刷新数据，
但是这样做的结果会导致性能很低，这就相当于同步复制了。

基本上，需要在性能和一致性之间做一个权衡。

如果绝对需要的话，Redis集群也是支持同步写的，这是通过WAIT命令实现的，这使得丢失写的可能性大大降低。
然而，需要注意的是，Redis集群没有实现强一致性，即使用同步复制，因为总是有更复杂的失败场景使得一个没有接受到这个写操作的slave当选为新的master。

另一个值得注意的场景，即Redis集群将会丢失写操作，这发生在一个网络分区中，在这个分区中，客户端与少数实例(包括至少一个主机)隔离。

假设这样一个例子，有一个集群有6个节点，分别由A、B、C、A1、B1、C1组成，三个masters三个slaves，有一个客户端我们叫Z1。
在分区发生以后，可能分区的一边是A、C、A1、B1、C1，另一边有B和Z1。此时，Z1仍然可用写数据到B，如果网络分区的时间很短，
那么集群可能继续正常工作，而如果分区的时间足够长以至于B1在多的那一边被提升为master，那么这个时候Z1写到B上的数据就会丢失。

什么意思呢？简单的来说就是，本来三主三从在一个网络分区中，突然网络分区发生，于是一边是A、C、A1、B1、C1，另一边是B和Z1，
这时候Z1往B中写数据，于此同时另一边（即A、C、A1、B1、C1）认为B已经挂了，于是将B1提升为master，
当分区回复的时候，由于B1变成了master，所以B就成了slave，于是B就要丢弃它自己原有的数据而从B1那里同步数据，
于是乎先去Z1写到B的数据就丢失了。

注意，有一个最大窗口，这是Z1能够向B写的最大数量：如果时间足够的话，分区的多数的那一边已经选举完成，选择一个slave成为master，
此时，所有在少数的那一边的master节点将停止接受写。

也就说说，有一个最大窗口的设置项，它决定了Z1在那种情况下能够向B发送多数写操作：如果分隔的时间足够长，
多数的那边已经选举slave成为新的master，此后少数那边的所有master节点将不再接受写操作。

在Redis集群中，这个时间数量是一个非常重要的配置指令，它被称为node timeout。在超过node timeout以后，一个master节点被认为已经失败了，
并且选择它的一个副本接替master。类似地，如果在过了node timeout时间以后，
没有一个master能够和其它大多数的master通信，那么整个集群都将停止接受写操作。

## 5、Redis集群配置参数（Redis Cluster configuration parameters）
```xml
cluster-enabled <yes/no>: 如果是yes，表示启用集群，否则以单例模式启动

cluster-config-file <filename>: 可选，这不是一个用户可编辑的配置文件，这个文件是Redis集群节点自动持久化每次配置的改变，为了在启动的时候重新读取它。

cluster-node-timeout <milliseconds>: 超时时间，集群节点不可用的最大时间。如果一个master节点不可到达超过了指定时间，则认为它失败了。注意，每一个在指定时间内不能到达大多数master节点的节点将停止接受查询请求。

cluster-slave-validity-factor <factor>: 如果设置为0，则一个slave将总是尝试故障转移一个master。如果设置为一个正数，那么最大失去连接的时间是node timeout乘以这个factor。

cluster-migration-barrier <count>: 一个master和slave保持连接的最小数量（即：最少与多少个slave保持连接），也就是说至少与其它多少slave保持连接的slave才有资格成为master。

cluster-require-full-coverage <yes/no>: 如果设置为yes，这也是默认值，如果key space没有达到百分之多少时停止接受写请求。如果设置为no，将仍然接受查询请求，即使它只是请求部分key。
``` 

## 创建并使用Redis集群（Creating and using a Redis Cluster）

[redis cluster 搭建使用](04、redis%20cluster搭建使用.md)

