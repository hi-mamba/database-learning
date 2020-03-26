## [原文](https://www.cnblogs.com/martinzhang/p/3415204.html)

# Redis事务及CAS(Check-And-Set)机制

> MULTI、EXEC、DISCARD和WATCH命令是Redis事务功能的基础。

## Redis事务机制特性

- 事务(transaction)的定义从multi开始，到exec结束。
- 同一个事务内的多个命令，具有原子性，不会被打断
   
## 乐观锁介绍：
watch指令在redis事物中提供了`CAS的行为`。为了检测被watch的keys在是否有多个clients同时改变引起冲突，
这些keys将会被监控。如果至少有一个被监控的key在执行exec命令前被修改，整个事物将会回滚，
不执行任何动作，从而保证原子性操作，并且执行exec会得到null的回复。

## 乐观锁工作机制：
watch 命令会监视给定的每一个key，当exec时如果监视的任一个key自从调用watch后发生过变化，
则整个事务会回滚，不执行任何动作。注意watch的key是对整个连接有效的，事务也一样。如果连接断开，监视和事务都会被自动清除。
当然exec，discard，unwatch命令，及客户端连接关闭都会清除连接中的所有监视。
还有，如果watch一个不稳定(有生命周期)的key并且此key自然过期，exec仍然会执行事务队列的指令。

