## [原文](https://www.cnblogs.com/XL-Liang/archive/2012/05/03/2481310.html)

# 开启MySQL远程访问权限 允许远程连接

## 1、登陆mysql数据库    

   mysql -u root -p

   查看user表

```mysql
mysql> use mysql;
Database changed
mysql> select host,user,password from user;
+--------------+------+-------------------------------------------+
| host         | user | password                                  |
+--------------+------+-------------------------------------------+
| localhost    | root | *A731AEBFB621E354CD41BAF207D884A609E81F5E |
| 192.168.1.1 | root | *A731AEBFB621E354CD41BAF207D884A609E81F5E |
+--------------+------+-------------------------------------------+
2 rows in set (0.00 sec)

```
 

   可以看到在user表中已创建的root用户。host字段表示登录的主机，其值可以用IP，也可用主机名，

   (1)有时想用本地IP登录，那么可以将以上的Host值改为自己的Ip即可。

## 2、实现远程连接(授权法)

   将host字段的值改为%就表示在任何客户端机器上能以root用户登录到mysql服务器，建议在开发时设为%。   
   update user set host = ’%’ where user = ’root’;

   将权限改为ALL PRIVILEGES
```mysql
mysql> use mysql;
Database changed
mysql> grant all privileges  on *.* to root@'%' identified by "root";
Query OK, 0 rows affected (0.00 sec)

mysql> select host,user,password from user;
+--------------+------+-------------------------------------------+
| host         | user | password                                  |
+--------------+------+-------------------------------------------+
| localhost    | root | *A731AEBFB621E354CD41BAF207D884A609E81F5E |
| 192.168.1.1 | root | *A731AEBFB621E354CD41BAF207D884A609E81F5E |
| %            | root | *A731AEBFB621E354CD41BAF207D884A609E81F5E |
+--------------+------+-------------------------------------------+
3 rows in set (0.00 sec)

```
这样机器就可以以用户名root密码root远程访问该机器上的MySql.

## 3、实现远程连接（改表法）

```mysql
use mysql;

update user set host = '%' where user = 'root';

```

这样在远端就可以通过root用户访问Mysql.


## 遇到异常

[原文](https://www.jianshu.com/p/53ac2d55b279)

> MySQL 报错 ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement

报错提示告诉我们，需要重新设置密码。那我们就重新设置一下密码，命令如下：

> set password = password('root');

