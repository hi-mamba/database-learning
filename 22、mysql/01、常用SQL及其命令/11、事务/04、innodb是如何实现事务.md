
# innodb是如何实现事务

innode 通过buffer pool,logBuffer,Red log,Undo log来实现事务

以一个update语句为例：

1. innodb在收到一个update 语句后，会先根据条件找到数据所在的页，并将该页缓存在buffer pool中
2. 执行update语句，修改buffer pool中的数据，也就是内存中的数据，
3. 针对update语句生成一个red log 对象，并存入log buffer中
4. 针对update语句生成undo log日志，用于事务回滚
5. 如果事务提交，那么则把redo log对象进行持久化，后续还有其他机制将buffer rool中所修改的数据页持久化到磁盘中
6. 如果事务回滚，则利用undolog日志进行回滚。
