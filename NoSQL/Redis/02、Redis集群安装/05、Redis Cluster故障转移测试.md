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

- master fail的情况

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

- master 没有 slave 情况

如果集群任意master挂掉,且当前master没有slave.集群进入fail状态,也可以理解成集群的slot映射[0-16383]不完成时进入fail状态.
> redis-3.0.0.rc1加入cluster-require-full-coverage参数,默认关闭,打开集群兼容部分失败.

如果集群超过半数以上master挂掉，无论是否有slave集群进入fail状态.
> 当集群不可用时,所有对集群的操作做都不可用，收到((error) CLUSTERDOWN The cluster is down)错误

如下所示：
```bash
127.0.0.1:7001> CLUSTER nodes
68f70837be0a376a72aa31f58411c619b2eaa4ae 127.0.0.1:7001@17001 myself,master - 0 1556007539000 2 connected 5461-10922
f32fee069189ab0c36d23d0e4c2ec3c0673b7950 127.0.0.1:7002@17002 slave,fail a7ab6384d307cb95ac82781047ea6fade7731707 1556007490341 1556007489635 7 disconnected
838f2a0513a500a1f43b5e13e527871fe820c348 127.0.0.1:7003@17003 slave 68f70837be0a376a72aa31f58411c619b2eaa4ae 0 1556007539171 4 connected
a7ab6384d307cb95ac82781047ea6fade7731707 127.0.0.1:7004@17004 master,fail - 1556007524794 1556007523985 7 disconnected 10923-16383
e0fc82a0644a03d94267d25d79961cdbfb966be6 127.0.0.1:7005@17005 slave e0de091879cf88fee33d2b437669dd2d9429bdc7 0 1556007538159 6 connected
e0de091879cf88fee33d2b437669dd2d9429bdc7 127.0.0.1:7000@17000 master - 0 1556007539576 1 connected 0-5460
127.0.0.1:7001> get test
(error) CLUSTERDOWN The cluster is down
```

- 如果集群都down 了，那么在重启slave 之后不会恢复，需要再重启master。
- 如果集群都down 了，那么重启master 之后可以恢复.

## 新增slave，删除slave 或者master 

关于更多的在线添加节点，删除节点，以及对集群进行重新分片请参考官方文档