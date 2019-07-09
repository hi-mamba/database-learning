

# 003、mysql到底有没有执行更新操作

我们创建了一个简单的表t，并插入一行，然后对这一行做修改。
```mysql
mysql> CREATE TABLE `t` (
`id` int(11) NOT NULL primary key auto_increment,
`a` int(11) DEFAULT NULL
) ENGINE=InnoDB;
insert into t values(1,2);

```
这时候，表t里有唯一的一行数据(1,2)。假设，我现在要执行：

```mysql
mysql> update t set a=2 where id=1;

```
你会看到这样的结果：
```mysql
mysql> update t set a=2 where id=1;
Query OK, 0 rows affected (0.00 sec)
Rows matched: 1  Changed: 0  Warnings: 0
```

结果显示，匹配(rows matched)了一行，修改(Changed)了0行。

仅从现象上看，MySQL内部在处理这个命令的时候，可以有以下三种选择：

1. 更新都是先读后写的，MySQL读出数据，发现a的值本来就是2，不更新，直接返回，执行结束；

2. MySQL调用了InnoDB引擎提供的“修改为(1,2)”这个接口，但是引擎发现值与原来相同，不更新，直接返回；

3. InnoDB认真执行了“把这个值修改成(1,2)"这个操作，该加锁的加锁，该更新的更新。

你觉得实际情况会是以上哪种呢？你可否用构造实验的方式，来证明你的结论？
进一步地，可以思考一下，MySQL为什么要选择这种策略呢？

## 答案

> 答案应该是选项3，即：InnoDB认真执行了“把这个值修改成(1,2)"这个操作，该加锁的加锁，该更新的更新。

在命令行先执行以下命令（注意不要提交事务）：
```mysql
BEGIN;
UPDATE t SET a=2 WHERE id=1;
```

新建一个命令行终端，执行以下命令：

```mysql
UPDATE t SET a=2 WHERE id=1;
```

从新建的命令行终端的执行结果看，这条更新语句被阻塞了，如果时间足够的话（InnoDB行锁默认等待时间是50秒），
还会报锁等待超时的错误。

综上，MySQL应该是采用第3种方式处理题述场景。

对于MySQL为什么采用这种方式，我们可以利用《08 | 事务到底是隔离的还是不隔离的？》图5的更新逻辑图来解释：假设事务C更新后a的值就是2，
而事务B执行再执行UPDATE t SET a=2 WHERE id=1;时不按第3种方式处理，即不加锁不更新，
那么在事务B中接下来查询a的值将还是1，因为对事务B来说，trx_id为102版本的数据是不可见的，这就违反了“当前读的规则”。



## 字段 update_time 设置触发器自动更新
如果表中有timestamp字段而且设置了自动更新的话，那么更新“别的字段”的时候，
MySQL会读入所有涉及的字段，这样通过判断，就会发现不需要修改。

