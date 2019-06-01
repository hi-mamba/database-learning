
## [参考](https://www.jianshu.com/p/7720c922dd80)

## [参考](https://blog.csdn.net/xiaoliuliu2050/article/details/72898828)

# Either the node already knows other nodes (check with CLUSTER NODES) or contains some key in database 0

新增节点8且已经起来了

然后把节点8假如到集群，并且是以从节点的形式存在，并且指定masterid为节点7
 
```bash
redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7007 --cluster-slave --cluster-master-id 0a68c8c6b4c30e92a4ccad1b98689f0803f015da
```

然后报异常


```bash
Either the node already knows other nodes (check with CLUSTER NODES) or contains some key in database 0
```

## 解决方案

- 先关闭新增节点8

- 删除 将需要新增的节点8下aof、rdb等本地备份文件删除；

- 重启节点把

然后在执行

```bash
redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7007 --cluster-slave --cluster-master-id 0a68c8c6b4c30e92a4ccad1b98689f0803f015da
```


- 执行成功

```bash
➜  cluster redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7007 --cluster-slave --cluster-master-id 0a68c8c6b4c30e92a4ccad1b98689f0803f015da
```

```
>>> Adding node 127.0.0.1:7008 to cluster 127.0.0.1:7007
>>> Performing Cluster Check (using node 127.0.0.1:7007)
M: 0a68c8c6b4c30e92a4ccad1b98689f0803f015da 127.0.0.1:7007
   slots:[0-332],[5461-5794],[10923-11255] (1000 slots) master
S: 686847aae9755c6d8b5deec1108b6730d8a1d010 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 7a97a17f5c428a625004a5eb122dcdbd1314aeb6
S: ea143f5d1bfee89ec737437d08ae4de82568b3c1 127.0.0.1:7006
   slots: (0 slots) slave
   replicates 39ec77bea0288aa550e6f3b3cf88dc8de7926588
M: 203585fce854919a8868796925e8f6d5504027c9 127.0.0.1:7001
   slots:[5795-10922] (5128 slots) master
   1 additional replica(s)
S: 0692d0eb55d802ab04c31a68810e62130ed033e1 127.0.0.1:7005
   slots: (0 slots) slave
   replicates 203585fce854919a8868796925e8f6d5504027c9
M: 7a97a17f5c428a625004a5eb122dcdbd1314aeb6 127.0.0.1:7002
   slots:[11256-16383] (5128 slots) master
   1 additional replica(s)
M: 39ec77bea0288aa550e6f3b3cf88dc8de7926588 127.0.0.1:7004
   slots:[333-5460] (5128 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 127.0.0.1:7008 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 127.0.0.1:7007.
[OK] New node added correctly.
```