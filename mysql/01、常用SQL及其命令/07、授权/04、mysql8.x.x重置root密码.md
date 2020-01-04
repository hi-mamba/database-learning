## [How to reset the root password in MySQL 8.0.11?](https://stackoverflow.com/a/52579886/4712855)


# [mysql8 之后首次登录之后操作需要重置密码](https://dev.mysql.com/doc/refman/8.0/en/resetting-permissions.html)

> You must reset your password using ALTER USER statement before executing this statement

> ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123';

# 04、mysql8.x.x重置root密码

> 注意这里是非 skip-grant-tables 模式下，如果是 skip-grant-tables模式，请先修改root密码为空
```mysql
UPDATE mysql.user SET authentication_string=null WHERE User='root';
FLUSH PRIVILEGES;
exit;
```

> 注意 用户 user 的 host 必须是 localhost，我之前修改为% 之后死活修改不了密码.



```mysql
mysql> SELECT user,host,plugin from mysql.user;
+------------------+-----------+-----------------------+
| user             | host      | plugin                |
+------------------+-----------+-----------------------+
| test             | %         | mysql_native_password |
| mysql.infoschema | localhost | caching_sha2_password |
| mysql.session    | localhost | caching_sha2_password |
| mysql.sys        | localhost | caching_sha2_password |
| root             | localhost | caching_sha2_password |
+------------------+-----------+-----------------------+
5 rows in set (0.00 sec)

mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'root';
Query OK, 0 rows affected (0.02 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)
```




