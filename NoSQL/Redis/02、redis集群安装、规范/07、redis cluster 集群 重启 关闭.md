## [原文](http://blog.51yip.com/nosql/1735.html)

# redis cluster 集群 重启 关闭

找遍了redis cluster官方文档，没发现有关集群重启和关闭的方法。为啥会没有呢，
猜测redis cluster至少要三个节点才能运行，三台同时挂掉的可能性比较小,只要不同时挂掉，
挂掉的机器修复后在加入集群，集群都能良好的运作，万一同时挂掉，数据又没有备份的话，就有大麻烦了。

redis cluster集群中的节点基本上都对等的，没有管理节点。如果要让所有节点都关闭，
只能关闭进程了# pkill -9 redis


把所有集群都关闭，然后在重新启动，会报以下错误
```bash
redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1
```
会报以下错误，
```bash
[ERR] Node 127.0.0.1 7006 is not empty. Either the node already knows other nodes (check with CLUSTER NODES) or contains some key in database 0.
```

第一次启动集群时，/etc/redis下只有redis.conf，所以我想把除了redis.conf外的其他文件全部删除，
在启动肯定是可以的，但是集群是有数据的，所以保留了配置文件和数据文件。

查看复制打印?
```bash
# cd /etc/redis       
  
# rm -f *.aof nodes-63*  
  
# ll     //保留了配置文件和数据文件  
总用量 204  
-rw-r--r-- 1 root root 18 5月 7 11:21 dump-6379.rdb  
-rw-r--r-- 1 root root 18 5月 7 11:21 dump-6380.rdb  
-rw-r--r-- 1 root root 18 5月 7 11:21 dump-6381.rdb  
-rw-r--r-- 1 root root 41412 4月 30 23:30 redis-6379.conf  
-rw-r--r-- 1 root root 41412 4月 30 23:39 redis-6380.conf  
-rw-r--r-- 1 root root 41412 4月 30 23:39 redis-6381.conf  

```
这样是可以启动的，但是原来的数据还是丢失了，不知道是自己的想法不对，还是redis cluster根本没考虑，
所有节点都会挂掉的情况。

