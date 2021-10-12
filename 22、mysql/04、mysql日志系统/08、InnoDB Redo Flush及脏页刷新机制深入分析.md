##### [原文](https://www.cnblogs.com/clouddbdever/p/5707722.html)

# InnoDB Redo Flush及脏页刷新机制深入分析

我们知道InnoDB采用`Write Ahead Log`策略来防止宕机数据丢失，即事务提交时，先写重做日志，再修改内存数据页，
这样就产生了脏页。既然有重做日志保证数据持久性，查询时也可以直接从缓冲池页中取数据，
那为什么还要刷新脏页到磁盘呢？如果重做日志可以无限增大，同时缓冲池足够大，能够缓存所有数据，
那么是不需要将缓冲池中的脏页刷新到磁盘。
但是，通常会有以下几个问题：


- 服务器内存有限，缓冲池不够用，无法缓存全部数据

- 重做日志无限增大成本要求太高

- 宕机时如果重做全部日志恢复时间过长

事实上，当数据库宕机时，数据库不需要重做所有的日志，只需要执行`上次刷入点`之后的日志。
这个点就叫做`Checkpoint`，它解决了以上的问题：

- 缩短数据库恢复时间

- 缓冲池不够用时，将脏页刷新到磁盘

- 重做日志不可用时，刷新脏页

重做日志被设计成可`循环使用`，当日志文件写满时，重做日志中对应数据已经`被刷新到磁盘`的那部分不再需要的日志可以被覆盖重用。

InnoDB引擎通过`LSN(Log Sequence Number)`来标记版本，LSN是日志空间中`每条日志的结束点`，
用`字节`偏移量来表示。
每个page有LSN，redo log也有LSN，Checkpoint也有LSN。
可以通过命令show engine innodb status来观察：
```mysql
---
LOG
---
Log sequence number 1039878815567
Log flushed up to   1039878815567
Pages flushed up to 1039878814486
Last checkpoint at  1039878814486
0 pending log writes, 0 pending chkp writes
5469310 log i/o's done, 1.00 log i/o's/second
```
## Checkpoint机制每次刷新多少页，从哪里取脏页，什么时间触发刷新？

这些都是很复杂的。有两种Checkpoint，分别为：

- Sharp Checkpoint
- Fuzzy Checkpoint

Sharp Checkpoint发生在`关闭数据库`时，将所有脏页刷回磁盘。
在运行时使用Fuzzy Checkpoint进行`部分脏页`的刷新。部分脏页刷新有以下几种：

- Master Thread Checkpoint
- FLUSH_LRU_LIST Checkpoint
- Async/Sync Flush Checkpoint
- Dirty Page too much Checkpoint

### Master Thread Checkpoint

Master Thread以每秒或每十秒的速度从缓冲池的脏页列表中刷新一定比例的页回磁盘。
这个过程是`异步`的，不会阻塞查询线程。

### Flush LRU List Checkpoint
    
InnoDB要`保证LRU列表`中有100左右空闲页可使用。
在InnoDB1.1.X版本前，要检查LRU中是否有足够的页用于用户查询操作线程，
如果没有，会将LRU列表尾端的页淘汰，如果被淘汰的页中有脏页，
会强制执行Checkpoint刷回脏页数据到磁盘，显然这会阻塞用户查询线程。
从InnoDB1.2.X版本开始，这个检查放到单独的`Page Cleaner Thread`中进行，
并且用户可以通过`innodb_lru_scan_depth`控制LRU列表中可用页的数量，默认值为1024。

### Async/Sync Flush Checkpoint

是指重做日志文件不可用时，需要强制将脏页列表中的一些页刷新回磁盘。
这可以保证重做日志文件可循环使用。在InnoDB1.2.X版本之前，
Async Flush Checkpoint会阻塞发现问题的用户查询线程，
Sync Flush Checkpoint会阻塞所有查询线程。
InnoDB1.2.X之后放到单独的`Page Cleaner Thread`。

### Dirty Page Too Much Checkpoint

脏页数量太多时，InnoDB引擎会强制进行Checkpoint。
目的还是为了保证缓冲池中有足够可用的空闲页。
其可以通过参数innodb_max_dirty_pages_pct来设置，默认为75%：
```mysql
(root@localhost)[(none)]> show variables like 'innodb_max_dirty_pages_pct';
+----------------------------+-------+
| Variable_name              | Value |
+----------------------------+-------+
| innodb_max_dirty_pages_pct | 75    |
+----------------------------+-------+
1 row in set (0.00 sec)
```
以上是脏页刷新的几种触发机制，接下来，细说一下日志机制及其中第3点Async/Sync flush checkpoint原理。


## Async/Sync flush checkpoint原理

### Log及Checkpoint 简介

Innodb的`事务日志`是指`Redo log`，简称Log,保存在日志文件ib_logfile*里面。
Innodb还有另外一个日志`Undo log`，但Undo log是存放在`共享表空间`里面的（ibdata*文件）。

由于Log和Checkpoint紧密相关，因此将这两部分合在一起分析。

> 名词解释：LSN，`日志序列号`，Innodb的日志序列号是一个64位的整型。

### Log写入

LSN实际上对应日志文件的偏移量，新的LSN＝旧的LSN + 写入的日志大小。举例如下：

> LSN＝1G，日志文件大小总共为600M，本次写入512字节，则实际写入操作为：
```
| --- 求出偏移量：由于LSN数值远大于日志文件大小，因此通过取余方式，得到偏移量为400M；

| --- 写入日志：找到偏移400M的位置，写入512字节日志内容，下一个事务的LSN就是1000000512；
```


### Checkpoint写入

Innodb实现了`Fuzzy Checkpoint的机制`，每次取到最老的脏页，
然后确保此脏页对应的LSN之前的LSN都已经写入日志文件，再将此脏页的LSN作为Checkpoint点记录到日志文件，
意思就是`“此LSN之前的LSN对应的日志和数据都已经写入磁盘文件”`。
恢复数据文件的时候，Innodb扫描日志文件，`当发现LSN小于Checkpoint对应的LSN`，就认为恢复已经完成。

Checkpoint写入的位置在日志文件开头固定的偏移量处，即每次写Checkpoint都覆盖之前的Checkpoint信息。

### Flush刷新流程及原理介绍

Innodb的数据并不是实时写盘的，为了避免宕机时数据丢失，保证数据的ACID属性，
Innodb至少要保证数据对应的日志不能丢失。对于不同的情况，Innodb采取不同的对策：

1）宕机导致日志丢失

Innodb有日志刷盘机制，可以通过`innodb_flush_log_at_trx_commit`参数进行控制；

2）日志覆盖导致日志丢失

Innodb日志文件大小是固定的，写入的时候通过取余来计算偏移量，这样存在两个LSN写入到同一位置的可能，
后面写的把前面写得就覆盖了，以“写入机制”章节的样例为例，
LSN＝100000000和LSN＝1600000000两个日志的偏移量是相同的了。
这种情况下，为了保证数据一致性，`必须要求LSN=1000000000对应的脏页数据都已经刷到磁盘中`，
也就是要求Last checkpoint对应的LSN一定要大于1000000000，否则覆盖后日志也没有了，
数据也没有刷盘，一旦宕机，数据就丢失了。

为了解决第二种情况导致数据丢失的问题，Innodb实现了一套日志保护机制，详细实现如下：


上图中，直线代表日志空间（Log cap，约等于日志文件总大小*0.8，0.8是一个安全系数)，
Ckp age和Buf age是两个浮动的点，Buf async、Buf sync、Ckp async、Ckp sync是几个固定的点。
各个概念的含义如下：

概念	|计算	|含义
|---|---|---
Ckp  age	| LSN1- LSN4	|    还没有做Checkpoint的日志范围，若Ckp age超过日志空间，说明被覆盖的日志（LSN1－LSN4－Log cap）对应日志和数据“可能”还没有刷到磁盘上
Buf  age	| LSN1- LSN3	|    还没有将脏页刷盘的日志的范围，若Buf age超过日志空间，说明被覆盖的日志（LSN1－LSN3－Log cap）对应数据“肯定”还没有刷到磁盘上
Buf  async	| 日志空间大小 * 7/8	| 制将Buf age-Buf async的脏页刷盘，此时事务还可以继续执行，所以为async，对事务的执行速度没有直接影响（有间接影响，例如CPU和磁盘更忙了，事务的执行速度可能受到影响）
Buf  sync	| 日志空间大小 * 15/16| 制将2*(Buf age-Buf async)的脏页刷盘，此时事务停止执行，所以为sync，由于有大量的脏页刷盘，因此阻塞的时间比Ckp sync要长。
Ckp  async	| 日志空间大小 * 31/32| 制写Checkpoint，此时事务还可以继续执行，所以为async，对事务的执行速度没有影响（间接影响也不大，因为写Checkpoint的操作比较简单）
Ckp  sync	| 日志空间大小 * 64/64| 制写Checkpoint，此时事务停止执行，所以为sync，但由于写Checkpoint的操作比较简单，即使阻塞，时间也很短
 

当事务执行速度大于脏页刷盘速度时，Ckp age和Buf age会逐步增长，当达到async点的时候，
强制进行脏页刷盘或者写Checkpoint，如果这样做还是赶不上事务执行的速度，
则为了避免数据丢失，到达sync点的时候，`会阻塞其它所有的事务，专门进行脏页刷盘或者写Checkpoint`。

因此从理论上来说,`只要事务执行速度大于脏页刷盘速度`，最终都会触发日志保护机制，进而将事务阻塞，导致MySQL操作挂起。

由于写Checkpoint本身的操作相比写脏页要简单，耗费时间也要少得多，且Ckp sync点在Buf sync点之后，
因此绝大部分的阻塞都是阻塞在了Buf sync点，这也是当事务阻塞的时候，IO很高的原因，
因为这个时候在不断的刷脏页数据到磁盘。例如如下截图的日志显示了很多事务阻塞在了Buf sync点：

> 图片挂了



