
##### [如何保证 Redis中数据都是热点数据](https://blog.csdn.net/u013308490/article/details/87737810)

# 如何保证 Redis中数据都是热点数据

### 场景：

数据库中有1000w的数据，而redis中只有50w数据，如何保证redis中10w数据都是热点数据？

### 方案：

`限定 Redis 占用的内存`，Redis 会根据自身`数据淘汰策略`，`留下热数据到内存`。
所以，计算一下 50W 数据大约占用的内存，然后设置一下 Redis 内存限制即可，并将淘汰策略为`volatile-lru`或者`allkeys-lru`。  


[Redis内存淘汰机制](../30、原理知识点/53、Redis内存淘汰机制.md)
