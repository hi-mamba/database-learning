

# redis集群投票机制（故障检测）

![](../../../images/redis/Redis_cluster_vote.jpg)

Redis集群中每一个节点都会参与投票,如果当半数以上的节点认为一个节点通信超时,则该节点fail。

当集群中任意节点的master(主机)挂掉,且这个节点没有slave(从机),则整个集群进入fail状态。

