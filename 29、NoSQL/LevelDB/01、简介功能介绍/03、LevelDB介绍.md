

# 介绍

LevelDB是Google开源的持久化KV单机数据库，具有很高的随机写，顺序读/写性能，但是随机读的性能很一般，也就是说，
LevelDB很适合应用在查询较少，而写很多的场景。LevelDB应用了LSM (Log Structured Merge) 策略，
lsm_tree对索引变更进行延迟及批量处理，并通过一种类似于归并排序的方式高效地将更新迁移到磁盘，
降低索引插入开销，关于LSM，本文在后面也会简单提及。

 
根据Leveldb官方网站的描述，LevelDB的特点和限制如下：

## 特点：
1、key和value都是任意长度的字节数组；

2、entry（即一条K-V记录）默认是按照key的字典顺序存储的，当然开发者也可以重载这个排序函数；

3、提供的基本操作接口：Put()、Delete()、Get()、Batch()；

4、支持批量操作以原子操作进行；

5、可以创建数据全景的snapshot(快照)，并允许在快照中查找数据；

6、可以通过前向（或后向）迭代器遍历数据（迭代器会隐含的创建一个snapshot）；

7、自动使用Snappy压缩数据；

8、可移植性；

## 限制：

1、非关系型数据模型（NoSQL），不支持sql语句，也不支持索引；

2、一次只允许一个进程访问一个特定的数据库；

3、没有内置的C/S架构，但开发者可以使用LevelDB库自己封装一个server；

 
 
它是 Google 开源的 NOSQL 存储引擎库，是现代分布式存储领域的一枚原子弹。在它的基础之上，
Facebook 开发出了另一个 NOSQL 存储引擎库 RocksDB，沿用了 LevelDB 的先进技术架构的同时还解决了 LevelDB 的一些短板。
你可以将 RocksDB 比喻成氢弹，它比 LevelDB 的威力更大一些。现代开源市场上有很多数据库都在使用 RocksDB 作为底层存储引擎，
比如大名鼎鼎的 TiDB。



但是为什么我要讲 LevelDB 而不是 RocksDB 呢？其原因在于 LevelDB 技术架构更加简单清晰易于理解。
如果我们先把 LevelDB 吃透了再去啃一啃 RocksDB 就会非常好懂了，RocksDB 也只是在 LevelDB 的基础上添砖加瓦进行了一系列优化而已。
等到我们攻破了 RocksDB 这颗氢弹，TiDB 核动力宇宙飞船已经在前方不远处等着我们了。

