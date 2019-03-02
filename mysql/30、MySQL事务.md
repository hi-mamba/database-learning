
## [原文](https://blog.csdn.net/u013235478/article/details/50625602)

# MySQL事务

事务（Transaction）是数据库区别于文件系统的重要特性之一，
事务会把数据库从一种一致性状态转换为另一种一致性状态。在数据库提交时，可以确保要么所有修改都已保存，要么所有修改都不保存。

## 事务的ACID特性
事务必须同时满足ACID的特性：

- 原子性（Atomicity）。事务中的所有操作要么全部执行成功，要么全部取消。
- 一致性（Consistency）。事务开始之前和结束之后，数据库完整性约束没有破坏。
- 隔离性（Isolation）。事务提交之前对其它事务不可见。
- 持久性（Durability）。事务一旦提交，其结果是永久的。

## 事务的分类
从事务理论的角度可以把事务分为以下几种类型：

- 扁平事务（Flat Transactions）
- 带有保存节点的扁平事务（Flat Transactions with Savepoints）
- 链事务（Chained Transactions）
- 嵌套事务（Nested Transactions）
- 分布式事务（Distributed Transactions）
 