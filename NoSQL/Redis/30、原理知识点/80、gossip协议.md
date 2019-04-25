

# gossip协议

- [gossip协议详情](https://github.com/pankui/distributed-learning/blob/master/301%E3%80%81%E5%88%86%E5%B8%83%E5%BC%8F%E5%8E%9F%E7%90%86%E2%80%94%E2%80%94gossip%E5%8D%8F%E8%AE%AE.md)

gossip协议包含多种消息，包括ping，pong，meet，fail等等。 

- meet：某个节点发送meet给新加入的节点，让新节点加入集群中，然后新节点就会开始与其他节点进行通信； 

- ping：每个节点都会频繁给其他节点发送ping，其中包含自己的状态还有自己维护的集如果想及时了解S群元数据，互相通过ping交换元数据； 

- pong: 返回ping和meet，包含自己的状态和其他信息，也可以用于信息广播和更新； 

- fail: 某个节点判断另一个节点fail之后，就发送fail给其他节点，通知其他节点，指定的节点宕机了。

 