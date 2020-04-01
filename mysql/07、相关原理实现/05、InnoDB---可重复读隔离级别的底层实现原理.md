## [原文](https://blog.csdn.net/chuixue24/article/details/86536372)

# InnoDB---可重复读隔离级别的底层实现原理

## 可重复读实现原理

Innodb的已提交读和可重复读隔离级别下，读有快照读（snapshot read）和当前读（current read）之分,
当前读就是`SELECT ... LOCK IN SHARE MODE`和`SELECT ... FOR UPDATE`，快照读就是`普通的SELECT`操作。

快照读的实现，利用了`undo log`和`read view`。

快照读不是在读的时候生成快照，而是在`写的时候保留了旧版本数据`。

快照读实现了`Multi-Version Concurrent Control`（多版本并发控制），简称MVCC，
指对于`同一个记录`，`不同的事务会`有`不同的版本`，`不同版本互不影响`，最后事务提交时`根据版本先后`确定能否提交。

但是，Innodb的读写事务会加`排他锁`，不同版本其实是串行的，所以首先要指出的是，Innodb事务快照读不是严格的MVCC实现


