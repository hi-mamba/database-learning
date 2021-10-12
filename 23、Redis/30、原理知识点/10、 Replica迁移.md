## [原文](https://shift-alt-ctrl.iteye.com/blog/2285470)

#  Replica迁移

> Replica migration：副本迁移

 Redis Cluster实现了一个成为“Replica migration”的概念，用来提升集群的可用性。
 比如集群中每个master都有一个slave，当集群中有一个master或者slave失效时，
 而不是master与它的slave同时失效，集群仍然可以继续提供服务。

 1）master A，有一个slave A1

 2）master A失效，A1被提升为master

 3）一段时间后，A1也失效了，那么此时集群中没有其他的slave可以接管服务，集群将不能继续服务。


 如果masters与slaves之间的映射关系是固定的（fixed），提高集群抗灾能力的唯一方式，
 就是给每个master增加更多的slaves，不过这种方式开支很大，需要更多的redis实例。

 解决这个问题的方案，我们可以将集群非对称，且在运行时可以动态调整master-slaves的布局（而不是固定master-slaves的映射），
 比如集群中有三个master A、B、C，它们对应的slave为A1、B1、C1、C2，即C节点有2个slaves。
 “Replica迁移”可以自动的重新配置slave，将其迁移到某个没有slave的master下。

 1）A失效，A1被提升为master

 2）此时A1没有任何slave，但是C仍然有2个slave，此时C2被迁移到A1下，成为A1的slave

 3）此后某刻，A1失效，那么C2将被提升为master。集群可以继续提供服务。

 
 
 
 