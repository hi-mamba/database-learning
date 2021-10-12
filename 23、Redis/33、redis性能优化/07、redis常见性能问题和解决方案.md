## [原文](https://zhuanlan.zhihu.com/p/41951014)

# redis常见性能问题和解决方案



(1) Master最好不要做任何持久化工作，如RDB内存快照和AOF日志文件

(Master写内存快照，save命令调度rdbSave函数，会阻塞主线程的工作，当快照比较大时对性能影响是非常大的，
会间断性暂停服务，所以Master最好不要写内存快照;AOF文件过大会影响Master重启的恢复速度)

(2) 如果数据比较重要，某个Slave开启AOF备份数据，策略设置为每秒同步一次

(3) 为了主从复制的速度和连接的稳定性，Master和Slave最好在同一个局域网内

(4) 尽量避免在压力很大的主库上增加从库

(5) 主从复制不要用图状结构，用单向链表结构更为稳定，即：Master <- Slave1 <- Slave2 <- Slave3...

这样的结构方便解决单点故障问题，实现Slave对Master的替换。如果Master挂了，可以立刻启用Slave1做Master，其他不变。

