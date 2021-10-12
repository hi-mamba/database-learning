## [原文](https://blog.csdn.net/yaomingyang/article/details/79094869 )

# redis集群相关问题

（1）redis在单机模式下redis.conf配置文件中默认的数据库数量是16个，

 
```xml
# Set the number of databases. The default database is DB 0, you can select
# a different one on a per-connection basis using SELECT <dbid> where
# dbid is a number between 0 and 'databases'-1
databases 16
```

（2）在集群模式下这个配置是不起作用的，集群客户端是不支持多数据库db的，只有一个数据库默认是SELECT 0;

```bash
127.0.0.1:7005> SELECT 0
OK
127.0.0.1:7005> SELECT 1
(error) ERR SELECT is not allowed in cluster mode
```

（3）集群slave从节点默认是不支持读写操作的，但是在执行过readonly命令后可以执行读操作；
