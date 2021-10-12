

##### [原文](https://blog.csdn.net/lamp_yang_3533/article/details/52266320)
 
# 如何查看MySQL的版本？

## mysql -V
没有登录
```mysql
> mysql -V
```

## mysql> select version();
```mysql
mysql> select version();
+-----------+
| version() |
+-----------+
| 8.0.18    |
+-----------+
1 row in set (0.00 sec)
```

## mysql> status

```mysql
mysql> status
--------------
mysql  Ver 8.0.18 for Linux on x86_64 (MySQL Community Server - GPL)

Connection id:		52
Current database:
Current user:		root@localhost
SSL:			Not in use
Current pager:		stdout
Using outfile:		''
Using delimiter:	;
Server version:		8.0.18 MySQL Community Server - GPL
Protocol version:	10
Connection:		Localhost via UNIX socket
Server characterset:	utf8mb4
Db     characterset:	utf8mb4
Client characterset:	latin1
Conn.  characterset:	latin1
UNIX socket:		/var/lib/mysql/mysql.sock
Uptime:			19 min 29 sec

Threads: 3  Questions: 157  Slow queries: 0  Opens: 183  Flush tables: 3  Open tables: 103  Queries per second avg: 0.134
--------------
```