## [原文](https://blog.csdn.net/woyixinyiyi/article/details/88290266)

# redis5.* 集群 新增节点，删除节点，节点slot复制，节点下线

在原来的7000-7005六个节点的基础上就行操作

cp -r 7005 7007将原来 7005的信息复制到7007目录

然后把redis.conf中的信息全部替换为7007

然后进入到bin目录 启动7007节点

./redis-server ../7007/redis.conf
```bash
 cluster ps -ef|grep redis
  501 80948     1   0  3:51下午 ??         0:21.25 redis-server 127.0.0.1:7001 [cluster]
  501 80950     1   0  3:51下午 ??         0:21.09 redis-server 127.0.0.1:7002 [cluster]
  501 80952     1   0  3:51下午 ??         0:20.35 redis-server 127.0.0.1:7003 [cluster]
  501 80954     1   0  3:51下午 ??         0:21.21 redis-server 127.0.0.1:7004 [cluster]
  501 80956     1   0  3:51下午 ??         0:20.31 redis-server 127.0.0.1:7005 [cluster]
  501 81246     1   0  4:00下午 ??         0:16.88 redis-server 127.0.0.1:7006 [cluster]
  501 81663     1   0  4:14下午 ??         0:14.43 redis-server 127.0.0.1:7007 [cluster]
```

说明节点7也起来了

随便进入一个客户端，比如7000
```bash
./redis-cli -p 7000

```
执行cluster nodes 
```bash
127.0.0.1:7001> CLUSTER nodes
0a68c8c6b4c30e92a4ccad1b98689f0803f015da 127.0.0.1:7007@17007 master - 0 1559380720428 8 connected 0
ea143f5d1bfee89ec737437d08ae4de82568b3c1 127.0.0.1:7006@17006 slave 39ec77bea0288aa550e6f3b3cf88dc8de7926588 0 1559380719116 7 connected
39ec77bea0288aa550e6f3b3cf88dc8de7926588 127.0.0.1:7004@17004 master - 0 1559380720024 7 connected 0-5460
203585fce854919a8868796925e8f6d5504027c9 127.0.0.1:7001@17001 myself,master - 0 1559380719000 2 connected 5795-10922
0692d0eb55d802ab04c31a68810e62130ed033e1 127.0.0.1:7005@17005 slave 203585fce854919a8868796925e8f6d5504027c9 0 1559380719000 6 connected
7a97a17f5c428a625004a5eb122dcdbd1314aeb6 127.0.0.1:7002@17002 master - 0 1559380720529 3 connected 11256-16383
```

说明新节点现在还没加入集群

此时新加入的节点node7并没有数据【connected 0 后面没有 slot】，并且也没有被分配slot也就是 目前node7是不可用的

执行 重新分配原集群（127.0.0.1:7000所在集群）的slot

redis-cli --cluster reshard 127.0.0.1:7000
```bash
cluster redis-cli --cluster reshard 127.0.0.1:7001

>>> Performing Cluster Check (using node 127.0.0.1:7001)
M: 203585fce854919a8868796925e8f6d5504027c9 127.0.0.1:7001
   slots:[5795-10922] (5128 slots) master
   1 additional replica(s)
S: ea143f5d1bfee89ec737437d08ae4de82568b3c1 127.0.0.1:7006
   slots: (0 slots) slave
   replicates 39ec77bea0288aa550e6f3b3cf88dc8de7926588
M: 39ec77bea0288aa550e6f3b3cf88dc8de7926588 127.0.0.1:7004
   slots:[0-5460] (5128 slots) master
   1 additional replica(s)
S: 686847aae9755c6d8b5deec1108b6730d8a1d010 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 7a97a17f5c428a625004a5eb122dcdbd1314aeb6
   replicates 0a68c8c6b4c30e92a4ccad1b98689f0803f015da
S: 0692d0eb55d802ab04c31a68810e62130ed033e1 127.0.0.1:7005
   slots: (0 slots) slave
   replicates 203585fce854919a8868796925e8f6d5504027c9
M: 7a97a17f5c428a625004a5eb122dcdbd1314aeb6 127.0.0.1:7002
   slots:[11256-16383] (5128 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
How many slots do you want to move (from 1 to 16384)?
```
一次要迁移多少个slot呢 先迁1000个把
```bash
How many slots do you want to move (from 1 to 16384)? 1000
What is the receiving node ID?
```

那个节点作为slot的接收方呢 必须使用nodeid 就是节点的唯一标示，就是前面执行的cluster nodes中最前面的一串

我这边设置7007作为接入方
```bash
How many slots do you want to move (from 1 to 16384)? 1000
What is the receiving node ID? 0a68c8c6b4c30e92a4ccad1b98689f0803f015da
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
Source node #1:
```

设置slot的迁出方，我这边选择all，即所有的 节点 总共迁移1000个slot的节点7
```bash
Source node #1: all

Ready to move 1000 slots.
  Source nodes:
    M: 203585fce854919a8868796925e8f6d5504027c9 127.0.0.1:7001
       slots:[5795-10922] (5128 slots) master
       1 additional replica(s)
    M: 39ec77bea0288aa550e6f3b3cf88dc8de7926588 127.0.0.1:7004
       slots:[333-5460] (5128 slots) master
       1 additional replica(s)
    M: 7a97a17f5c428a625004a5eb122dcdbd1314aeb6 127.0.0.1:7002
       slots:[11256-16383] (5128 slots) master
       1 additional replica(s)
  Destination node:
    M: 0a68c8c6b4c30e92a4ccad1b98689f0803f015da 127.0.0.1:7007
       slots:[0-332],[5461-5794],[10923-11255] (1000 slots) master
       1 additional replica(s)
  Resharding plan:
    Moving slot 5795 from 203585fce854919a8868796925e8f6d5504027c9
 
 // ...省略， ps 之前 这个7007 从其他 slot 迁移过数据来
Moving slot 11588 from 127.0.0.1:7002 to 127.0.0.1:7007:
```

这个时候 节点7已经有相关的slot信息了，可以接受客户端 正常的访问 了

节点7现在还是个单节点，我们这边 重复上面的复制目录7008 ，替换端口 等，

重启一个节点8
```bash
redis-server 7008_extension/redis.conf
```

节点8已经起来了
```bash
➜  cluster ps -ef|grep redis
  501 80948     1   0  3:51下午 ??         0:24.50 redis-server 127.0.0.1:7001 [cluster]
  501 80950     1   0  3:51下午 ??         0:24.29 redis-server 127.0.0.1:7002 [cluster]
  501 80952     1   0  3:51下午 ??         0:22.94 redis-server 127.0.0.1:7003 [cluster]
  501 80954     1   0  3:51下午 ??         0:24.46 redis-server 127.0.0.1:7004 [cluster]
  501 80956     1   0  3:51下午 ??         0:22.88 redis-server 127.0.0.1:7005 [cluster]
  501 81246     1   0  4:00下午 ??         0:19.50 redis-server 127.0.0.1:7006 [cluster]
  501 81663     1   0  4:14下午 ??         0:18.01 redis-server 127.0.0.1:7007 [cluster]
  501 83169     1   0  5:05下午 ??         0:05.19 redis-server 127.0.0.1:7008 [cluster]
```

## 新增节点加入从节点
```bash
redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7000 --cluster-slave --cluster-master-id ef1bcdb677b1c8f8c3d290a9b1ce2e54f8589835

```
把节点8假如到集群，并且是以从节点的形式存在，并且指定masterid为节点7
 
## 删除从节点8
```bash

redis-cli --cluster del-node 127.0.0.1:7000 f24b935a50a788692479c6beaf7c556f6d082253

```

> 删除节点之后，节确保点的slot的迁移到其他节点了

这个地方需要提一下的就是

假如 你要下线节点7，节点8，请务必先下线从节点，并且节点7的slot的迁移到其他节点了，

如果先线下节点7的话 会发产生故障切换，节点8成主节点了
 