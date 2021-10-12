

# redis与memcached有什么区别?为什么选择redis


## 区别

1. 存储容量：memcached超过内存比例会抹掉前面的数据，而redis会存储在磁盘

2. 支持数据类型：memcached只支持string，redis支持更多。如：hash list集合 有序集合

3. 持久化：redis支持两种持久化策略，memcached无

4. 主从：redis支持

5. memcached自带连接池和配合hash， redis3.0的集群
 