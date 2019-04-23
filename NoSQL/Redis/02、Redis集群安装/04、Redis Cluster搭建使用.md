

## [原文](https://www.cnblogs.com/gomysql/p/4395504.html)

# Redis Cluster搭建使用

要让集群正常工作至少需要3个主节点，在这里我们要创建6个redis节点，其中三个为主节点，三个为从节点，
对应的redis节点的ip和端口对应关系如下（为了简单演示都在同一台机器上面）

```
127.0.0.1:7000
127.0.0.1:7001

127.0.0.1:7002

127.0.0.1:7003

127.0.0.1:7004

127.0.0.1:7005
```
## 1. 下载最新版redis。

> http://download.redis.io/releases/   

> wget http://download.redis.io/releases/redis-5.0.4.tar.gz

## 2. 解压，安装
```bash
tar xf redis-5.0.4.tar.gz                      
cd redis-5.0.4
make && make install
```
## 3. 创建存放多个实例的目录

```bash
mkdir /data/cluster -p
cd /data/cluster
mkdir 7000 7001 7002 7003 7004 7005

```
## 4. 修改配置文件
```bash
cp redis-5.0.4/redis.conf /data/cluster/7000/

```
修改配置文件中下面选项
```
port 7000

daemonize yes

cluster-enabled yes

cluster-config-file nodes_7000.conf

cluster-node-timeout 5000

appendonly yes
```
- cluster-enabled 选项用于开实例的集群模式， 
- cluster-conf-file 选项则设定了保存节点配置文件的路径， 
默认值为nodes.conf 。其他参数相信童鞋们都知道。节点配置文件无须人为修改， 它由 Redis 集群在启动时创建，
并在有需要时自动进行更新。

redis.conf 配置说明
```xml
#端口7000,7001,7002
port 7000

#默认ip为127.0.0.1，需要改为其他节点机器可访问的ip，否则创建集群时无法访问对应的端口，无法创建集群
bind 192.168.252.101

#redis后台运行
daemonize yes

#pidfile文件对应7000，7001，7002
pidfile /var/run/redis_7000.pid

#开启集群，把注释#去掉
cluster-enabled yes

#集群的配置，配置文件首次启动自动生成 7000，7001，7002          
cluster-config-file nodes_7000.conf

#请求超时，默认15秒，可自行设置 
cluster-node-timeout 10100    
        
#aof日志开启，有需要就开启，它会每次写操作都记录一条日志
appendonly yes
```
只是把目录改为7003、7004、7005、7006、7007、7008对应的配置文件也按照这个规则修改即可

修改完成后，把修改完成的redis.conf复制到7001-7005目录下，并且端口修改成和文件夹对应。

## 5. 分别启动6个redis实例

```bash
cd /data/cluster/7000
redis-server redis.conf

cd /data/cluster/7001
redis-server redis.conf

cd /data/cluster/7002
redis-server redis.conf

cd /data/cluster/7003
redis-server redis.conf

cd /data/cluster/7004
redis-server redis.conf

cd /data/cluster/7005
redis-server redis.conf
```

- 查看进程否存在
```bash
$ redis ps -ef|grep redis
  501 55786     1   0 11:35上午 ??         0:17.73 redis-server 127.0.0.1:7000 [cluster]
  501 55836     1   0 11:36上午 ??         0:17.53 redis-server 127.0.0.1:7001 [cluster]
  501 55848     1   0 11:36上午 ??         0:17.55 redis-server 127.0.0.1:7003 [cluster]
  501 55854     1   0 11:36上午 ??         0:17.33 redis-server 127.0.0.1:7004 [cluster]
  501 55860     1   0 11:36上午 ??         0:17.39 redis-server 127.0.0.1:7005 [cluster]
  501 57215     1   0  2:12下午 ??         0:00.04 redis-server 127.0.0.1:7002 [cluster]
```

## 6. 执行命令创建集群，首先安装依赖，否则创建集群失败。

>  redis5.x.x 好不需要安装这个了.

安装 Ruby
```bash
$ yum -y install ruby ruby-devel rubygems rpm-build
$ gem install redis
```

### 创建集群
> 注意：在任意一台上运行 不要在每台机器上都运行，一台就够了

```bash
redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1
```

命令的意义如下：

- 给定 redis-cli 程序的命令是 create ， 这表示我们希望创建一个新的集群。  
- 选项 --replicas 1 表示我们希望为集群中的每个主节点创建一个从节点。   
- 之后跟着的其他参数则是实例的地址列表， 我们希望程序使用这些地址所指示的实例来创建新集群。   

简单来说， 以上命令的意思就是让 redis-cli 程序创建一个包含三个主节点和三个从节点的集群。   

接着， redis-cli 会打印出一份预想中的配置给你看， 如果你觉得没问题的话， 就可以输入 yes ， redis-cli 就会将这份配置应用到集群当中：

```xml
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 127.0.0.1:7004 to 127.0.0.1:7000
Adding replica 127.0.0.1:7005 to 127.0.0.1:7001
Adding replica 127.0.0.1:7003 to 127.0.0.1:7002
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: e0de091879cf88fee33d2b437669dd2d9429bdc7 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
M: 68f70837be0a376a72aa31f58411c619b2eaa4ae 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
M: f32fee069189ab0c36d23d0e4c2ec3c0673b7950 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
S: 838f2a0513a500a1f43b5e13e527871fe820c348 127.0.0.1:7003
   replicates 68f70837be0a376a72aa31f58411c619b2eaa4ae
S: a7ab6384d307cb95ac82781047ea6fade7731707 127.0.0.1:7004
   replicates f32fee069189ab0c36d23d0e4c2ec3c0673b7950
S: e0fc82a0644a03d94267d25d79961cdbfb966be6 127.0.0.1:7005
   replicates e0de091879cf88fee33d2b437669dd2d9429bdc7
Can I set the above configuration? (type 'yes' to accept): yes
```
输入 yes 并按下回车确认之后， 集群就会将配置应用到各个节点， 并连接起（join）各个节点 —— 也即是， 让各个节点开始互相通讯：

```xml
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
...
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e0de091879cf88fee33d2b437669dd2d9429bdc7 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: 68f70837be0a376a72aa31f58411c619b2eaa4ae 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: f32fee069189ab0c36d23d0e4c2ec3c0673b7950 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: a7ab6384d307cb95ac82781047ea6fade7731707 127.0.0.1:7004
   slots: (0 slots) slave
   replicates f32fee069189ab0c36d23d0e4c2ec3c0673b7950
S: 838f2a0513a500a1f43b5e13e527871fe820c348 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 68f70837be0a376a72aa31f58411c619b2eaa4ae
S: e0fc82a0644a03d94267d25d79961cdbfb966be6 127.0.0.1:7005
   slots: (0 slots) slave
   replicates e0de091879cf88fee33d2b437669dd2d9429bdc7
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```
一切正常输出以下信息。


## 7. 集群验证

### 连接集群测试
参数 -C 可连接到集群，因为 redis.conf 将 bind 改为了ip地址，所以 -h 参数不可以省略，-p 参数为端口号

```bash
redis-cli -c -h 127.0.0.1 -p 7000
```
我们在 127.0.0.1 机器redis 7001 的节点set 一个key
```bash
127.0.0.1:7001> set test tet
OK
```
然后get获取数据,发现redis get test 之后重定向到127.0.0.1机器 redis 7001 这个节点
```bash
127.0.0.1:7000> get test
-> Redirected to slot [6918] located at 127.0.0.1:7001 "tet"
```
如果您看到这样的现象，说明集群已经是可用的了



### 打印集群信息

```
127.0.0.1:7000> cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:239
cluster_stats_messages_pong_sent:233
cluster_stats_messages_sent:472
cluster_stats_messages_ping_received:228
cluster_stats_messages_pong_received:239
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:472
```

### 列出集群节点
```bash
127.0.0.1:7001> CLUSTER nodes
68f70837be0a376a72aa31f58411c619b2eaa4ae 127.0.0.1:7001@17001 myself,master - 0 1555999577000 2 connected 5461-10922
f32fee069189ab0c36d23d0e4c2ec3c0673b7950 127.0.0.1:7002@17002 master - 0 1555999578061 3 connected 10923-16383
838f2a0513a500a1f43b5e13e527871fe820c348 127.0.0.1:7003@17003 slave 68f70837be0a376a72aa31f58411c619b2eaa4ae 0 1555999577051 4 connected
a7ab6384d307cb95ac82781047ea6fade7731707 127.0.0.1:7004@17004 slave f32fee069189ab0c36d23d0e4c2ec3c0673b7950 0 1555999577000 5 connected
e0fc82a0644a03d94267d25d79961cdbfb966be6 127.0.0.1:7005@17005 slave e0de091879cf88fee33d2b437669dd2d9429bdc7 0 1555999578564 6 connected
e0de091879cf88fee33d2b437669dd2d9429bdc7 127.0.0.1:7000@17000 master - 0 1555999577555 1 connected 0-5460
```
可以看到7000-7002是master，7003-7005是slave。

### 集群命令

语法格式
```bash
redis-cli -c -p port

```
#### 集群

```
cluster info ：打印集群的信息
cluster nodes ：列出集群当前已知的所有节点（ node），以及这些节点的相关信息。

```
#### 节点

```
cluster meet <ip> <port> ：将 ip 和 port 所指定的节点添加到集群当中，让它成为集群的一份子。
cluster forget <node_id> ：从集群中移除 node_id 指定的节点。
cluster replicate <node_id> ：将当前节点设置为 node_id 指定的节点的从节点。
cluster saveconfig ：将节点的配置文件保存到硬盘里面。

```
#### 槽(slot)

```
cluster addslots <slot> [slot ...] ：将一个或多个槽（ slot）指派（ assign）给当前节点。
cluster delslots <slot> [slot ...] ：移除一个或多个槽对当前节点的指派。
cluster flushslots ：移除指派给当前节点的所有槽，让当前节点变成一个没有指派任何槽的节点。
cluster setslot <slot> node <node_id> ：将槽 slot 指派给 node_id 指定的节点，如果槽已经指派给另一个节点，那么先让另一个节点删除该槽>，然后再进行指派。
cluster setslot <slot> migrating <node_id> ：将本节点的槽 slot 迁移到 node_id 指定的节点中。
cluster setslot <slot> importing <node_id> ：从 node_id 指定的节点中导入槽 slot 到本节点。
cluster setslot <slot> stable ：取消对槽 slot 的导入（ import）或者迁移（ migrate）。

```
#### 键

```
cluster keyslot <key> ：计算键 key 应该被放置在哪个槽上。
cluster countkeysinslot <slot> ：返回槽 slot 目前包含的键值对数量。
cluster getkeysinslot <slot> <count> ：返回 count 个 slot 槽中的键 。
```

## 遇到问题

```
All commands and features belonging to redis-trib.rb have been moved

```
解决办法:
```bash
redis-cli --cluster create 172.16.0.71:9001 172.16.0.71:9002 --cluster-replicas 1

解决方法：原本的命令./redis-trib.rb create --replicas 1 172.16.0.71:9001 172.16.0.71:9002 废弃了，提示改用redis-cli

换成 ./redis-cli --cluster create 127.0.0.1:6379..........便可以解决问题
```
[使用redis搭建集群时遇到的问题：You should use redis-cli instead.](https://blog.csdn.net/weixin_39183543/article/details/86102834)

## 参考

[CentOs7.3 搭建 Redis-4.0.1 Cluster 集群服务](https://segmentfault.com/a/1190000010682551)










