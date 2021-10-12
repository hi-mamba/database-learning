## [原文](https://www.jianshu.com/p/e76d9ef35f73)

# 查询mysql事务隔离级别

## 1.查看当前会话隔离级别
```mysql
select @@tx_isolation;
```
## 2.查看系统当前隔离级别

```mysql
select @@global.tx_isolation;

```
## 3.设置当前会话隔离级别

```mysql
set session transaction isolatin level repeatable read;

```
## 4.设置系统当前隔离级别

```mysql
set global transaction isolation level repeatable read;

```
## 5.命令行，开始事务时

```mysql
set autocommit=off 或者 start transaction

```
 