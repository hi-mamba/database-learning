
## [原文](https://www.jianshu.com/p/b13ec76117c4)

# MySQL关闭自动commit（autocommit）

对于mysql来讲，在事务处理时，默认是在动提交的（autocommit），以下方法可以自动关闭autocommit；


```mysql
mysql> select version();
+-------------+
| version()   |
+-------------+
| 5.6.25-73.1 |
+-------------+
1 row in set (0.00 sec)

mysql> show variables like '%autocommit%';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| autocommit    | ON    |                ；；默认autocommit是开启的
+---------------+-------+
1 row in set (0.03 sec)
```

在当前session关闭autocommit：
```mysql
mysql> set @@session.autocommit=0;
Query OK, 0 rows affected (0.00 sec)

mysql> show variables like '%autocommit%';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| autocommit    | OFF   |
+---------------+-------+
1 row in set (0.00 sec)
```

在global级别关闭autocommit：
```mysql

mysql> set @@global.autocommit=0;
Query OK, 0 rows affected (0.01 sec)
```



## 开始事务

```mysql
mysql> begin;
Query OK, 0 rows affected (0.00 sec)
```

## 手动提交事务
```mysql
mysql> commit;
Query OK, 0 rows affected (0.00 sec)
```

## 事务回滚
```mysql
mysql> rollback;
Query OK, 0 rows affected (0.00 sec)
```













