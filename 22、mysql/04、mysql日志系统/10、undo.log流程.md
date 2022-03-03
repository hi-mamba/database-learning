
<https://blog.csdn.net/Weixiaohuai/article/details/117867353#:~:text=%E7%9A%84%E5%8E%86%E5%8F%B2%E7%89%88%E6%9C%AC%E3%80%82-,%E5%9B%9B%E3%80%81undo%20log%E7%9A%84%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86,%E7%BA%BF%E7%A8%8B%E8%BF%9B%E8%A1%8C%E5%9B%9E%E6%94%B6%E5%A4%84%E7%90%86%E7%9A%84%E3%80%82>

# undo.log流程

## 什么时候产生：
事务开始之前，将当前是的版本生成`undo log`，undo 也会产生 redo 来保证undo log的可靠性

## 什么时候释放：
当事务提交之后，`undo log并不能立马被删除`，而是`放入待清理的链表`，
由`purge（清除）线程`判断是否由其他事务在使用undo段中表的`上一个事务`之前的版本信息，
决定是否可以清理undo log的日志空间。

## 流程
假设有2个数值，分别为A=1和B=2，然后将A修改为3，B修改为4
```mysql
0. start transaction;
1. 记录 A=1 到undo log;
2. update A = 3；
3. 记录 A=3 到redo log；
4. 记录 B=2 到undo log；
5. update B = 4；
6. 记录B = 4 到redo log；
7. 将redo log刷新到磁盘
8. commit
```
在1-8步骤的任意一步系统宕机，事务未提交，该事务就不会对磁盘上的数据做任何影响。
如果在8-9之间宕机，恢复之后可以选择回滚，也可以选择继续完成事务提交，
因为此时redo log已经持久化。若在9之后系统宕机，内存映射中变更的数据还来不及刷回磁盘，
那么系统恢复之后，可以根据redo log把数据刷回磁盘。

所以，redo log其实保证的是事务的持久性和一致性，而undo log则保证了事务的原子性。
undo log是逻辑日志，可以理解为:
```mysql
当delete一条记录时，undo log中会记录一条对应的insert记录
当insert一条记录时，undo log中会记录一条对应的delete记录
当update一条记录时，它记录一条对应相反的update记录
```
