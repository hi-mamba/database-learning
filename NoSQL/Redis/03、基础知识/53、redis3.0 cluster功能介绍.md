## [原文](http://weizijun.cn/2015/12/30/redis3.0%20cluster%E5%8A%9F%E8%83%BD%E4%BB%8B%E7%BB%8D/)

# redis3.0 cluster功能介绍

redis从3.0开始支持集群功能。redis集群采用无中心节点方式实现，无需proxy代理，客户端直接与redis集群的每个节点连接，
根据同样的hash算法计算出key对应的slot，然后直接在slot对应的redis上执行命令。

在redis看来，响应时间是最苛刻的条件，增加一层带来的开销是redis不原因接受的。因此，redis实现了客户端对节点的直接访问，
为了去中心化，节点之间通过gossip协议交换互相的状态，以及探测新加入的节点信息。redis集群支持动态加入节点，
动态迁移slot，以及自动故障转移。

