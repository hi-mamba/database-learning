
## [原文](http://www.itpub.net/thread-1847386-1-1.html)

# 一个mysql 范围锁的问题

## 1. 创建了一个t表
```mysql
mysql> create table z (a int  primary key,b int , key(b));

```

## 2. 插入数据：
```mysql
insert into z values(1,1),(3,1),(5,3),(7,6),(10,8);
```
```mysql
mysql> select * from z;
+----+------+
| a  | b    |
+----+------+
|  1 |    1 |
|  3 |    1 |
|  5 |    3 |
|  7 |    6 |
| 10 |    8 |
+----+------+

```
 

## 3. 执行

| session1 | session2
|---|---
| autocommit=0; // 设置自动提交关闭| autocommit=0|
| begin;| 
| select * from z where b=3 for update; |
|  |  insert into z values(8,6); // 执行成功
|  | rollback; //回滚
|  | insert into z values(6,6); // 阻塞
 
 
## （6,6）为什么被阻塞

b 间隙锁属于（1,3）（3.6）上范围锁。而且 b 是非唯一索引，

Repeatable Read隔离级别下，id列上有一个非唯一索引，对应SQL`：select * from z where b=3 for update; `
首先，通过b索引定位到第一条满足查询条件的记录，加记录上的X锁，加GAP上的GAP锁，
然后加主键聚簇索引上的记录X锁， 然后返回；然后读取下一条，重复进行。
直至进行到第一条不满足条件的记录[7,6]， 此时，不需要加记录X锁，但是仍旧需要加GAP锁，最后返回结束。

## 参考

[ MySQL 加锁处理分析](03、MySQL%20加锁处理分析.md)
