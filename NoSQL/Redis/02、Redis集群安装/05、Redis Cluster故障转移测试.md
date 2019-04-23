## [原文](https://www.cnblogs.com/gomysql/p/4395504.html)

# Redis Cluster故障转移测试

故障转移测试：
```bash
127.0.0.1:7001> KEYS *
1) "name"
127.0.0.1:7001> get name
"yayun"
127.0.0.1:7001> 

```
可以看见7001是正常的，并且获取到了key，value，现在kill掉7000实例，再进行查询。


```bash
[root@redis-server ~]# ps -ef | grep 7000
root      4168     1  0 11:49 ?        00:00:03 redis-server *:7000 [cluster]
root      4385  4361  0 12:39 pts/3    00:00:00 grep 7000
[root@redis-server ~]# kill 4168
[root@redis-server ~]# ps -ef | grep 7000
root      4387  4361  0 12:39 pts/3    00:00:00 grep 7000
[root@redis-server ~]# redis-cli -c -p 7001
127.0.0.1:7001> get name
"yayun"
127.0.0.1:7001> 

```
可以正常获取到value，现在看看状态。


```bash
[root@redis-server ~]# redis-cli -c -p 7001 cluster nodes
2d03b862083ee1b1785dba5db2987739cf3a80eb 127.0.0.1:7001 myself,master - 0 0 2 connected 5461-10922
0456869a2c2359c3e06e065a09de86df2e3135ac 127.0.0.1:7002 master - 0 1428295271619 3 connected 10923-16383
37b251500385929d5c54a005809377681b95ca90 127.0.0.1:7003 master - 0 1428295270603 7 connected 0-5460
e2e2e692c40fc34f700762d1fe3a8df94816a062 127.0.0.1:7004 slave 2d03b862083ee1b1785dba5db2987739cf3a80eb 0 1428295272642 5 connected
2774f156af482b4f76a5c0bda8ec561a8a1719c2 127.0.0.1:7000 master,fail - 1428295159553 1428295157205 1 disconnected
9923235f8f2b2587407350b1d8b887a7a59de8db 127.0.0.1:7005 slave 0456869a2c2359c3e06e065a09de86df2e3135ac 0 1428295269587 6 connected
[root@redis-server ~]# 

```
原来的7000端口实例已经显示fail，原来的7003是slave，现在自动提升为master。

关于更多的在线添加节点，删除节点，以及对集群进行重新分片请参考官方文档