
## [原文](https://blog.csdn.net/u014203449/article/details/81043196)

# redis 分区 、集群概念

## 分区

是分割数据到多个Redis实例的处理过程，因此每个实例只保存key的一个子集。
分区可以让Redis管理更大的内存，Redis将可以使用所有机器的内存。如果没有分区，你最多只能使用一台机器的内存。
分区使Redis的计算能力通过简单地增加计算机得到成倍提升,Redis的网络带宽也会随着计算机和网卡的增加而成倍增长。

## 分区实现原理：
<https://www.cnblogs.com/hjwublog/p/5681700.html>

## Redis分区实现方案？

1. 客户端分区 就是在客户端就已经决定数据会被存储到哪个redis节点或者从哪个redis节点读取。大多数客户端已经实现了客户端分区。

2. 代理分区 意味着客户端将请求发送给代理，然后代理决定去哪个节点写数据或者读数据。
代理根据分区规则决定请求哪些Redis实例，然后根据Redis的响应结果返回给客户端。redis和memcached的一种代理实现就是Twemproxy

3. 查询路由(Query routing) 的意思是客户端随机地请求任意一个redis实例，然后由Redis将请求转发给正确的Redis节点。
Redis Cluster实现了一种混合形式的查询路由，但并不是直接将请求从一个redis节点转发到另一个redis节点，
而是在客户端的帮助下直接redirected到正确的redis节点。

 
## 集群
redis集群就是分区的一种的实现，
<https://blog.csdn.net/u014203449/article/details/81043137> Redis Cluster实现了一种混合形式的查询路由

cluster-enabled yes以此配置文件启动
```bash
$ redis-cli --cluster  create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 \
127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005

```
只不过练习通常把节点都放在了一台机器上。

如果分区扩张了（集群节点增加了），就得做数据迁移，槽分配，麻烦，所以不如一开始就做分区：


