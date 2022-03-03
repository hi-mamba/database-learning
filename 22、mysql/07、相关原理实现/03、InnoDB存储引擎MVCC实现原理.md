
##### [原文1](https://liuzhengyang.github.io/2017/04/18/innodb-mvcc/)

##### [原文2](https://juejin.im/post/5e747b206fb9a07cad3bc01c)

# InnoDB存储引擎MVCC实现原理

## 什么是 MVCC
MVCC (Multiversion Concurrency Control) 中文全程叫多版本并发控制，
是现代数据库（包括 MySQL、Oracle、PostgreSQL 等）引擎实现中常用的处理读写冲突的手段，
目的在于`提高数据库高并发`场景下的`吞吐性能`。

如此一来不同的事务在并发过程中，SELECT 操作可以`不加锁`而是通过 MVCC 机制`读取指定`的`版本历史记录`，
并通过一些手段保证保证读取的记录值符合事务所处的`隔离级别`，从而解决并发场景下的读写冲突。

## MVCC实现
MVCC是通过保存数据在某个时间点的`快照`来实现的. 不同存储引擎的MVCC实现是不同的,
典型的有乐观并发控制和悲观并发控制,`mysql的innodb则是使用的乐观锁机制`,即在每次事务开始之前取出该行的版本号,
再次取出时会比对`该行数据的版本号`是否是`事务之前的版本号`.

## MVCC原理
 对于mysql来说,MVCC由于其实现原理,只支持`read committed`和`repeatable read`隔离等级.

## MVCC具体实现


### Read View
   
## InnoDB与MVCC

- InnoDB中通过` undo log`实现了`数据的多版本`，而`并发控制`通过锁来实现。
- undo log除了实现MVCC外，还用于`事务的回滚`。
