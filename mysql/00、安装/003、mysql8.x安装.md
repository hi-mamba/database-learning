

# mysql8.x安装遇到的坑

## mysql8.x 二进制方式安装

> 注意不要使用root 账号来操作！！

### 下载mysql 安装包

[mysql下载地址](https://dev.mysql.com/downloads/mysql/8.0.html#downloads)

[mysql 国内清华镜像下载](https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/)

[mysql 国内163镜像下载](http://mirrors.163.com/mysql/Downloads/MySQL-8.0/)

> 推荐使用国内镜像来下载

```shell script
wget https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz

#  解压tar // 注意 tar -xvf xxx.tar 不需要 -zxvf 有参数z 有问题.
tar tar -xvf mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz

# 重命名下文件夹,为了之后安装主从做准备
mv mysql-8.0.15-linux-glibc2.12-x86_64 mysql_master_3306
cd mysql_master_3306

```

### 自定义 my.cnf 配置及其 日志、数据文件目录
```shell script
mkdir data
mkdir tmp
mkdir log
mkdir etc
vim etc/my.cnf
```
- my.cnf 的配置

自定义 [my.cnf](my.cnf)
```shell script
[client]
socket=/home/mamba/soft/mysql/mysql_master_3306//tmp/mysql.sock
default-character-set=utf8

[mysql]
basedir=/home/mamba/soft/mysql/mysql_master_3306/
datadir=/home/mamba/soft/mysql/mysql_master_3306/data/
socket=/home/mamba/soft/mysql/mysql_master_3306//tmp/mysql.sock
port=3306
user=mamba

log_timestamps=SYSTEM
log-error=/home/mamba/soft/mysql/mysql_master_3306/log/mysql.err

default-character-set=utf8

[mysqld]
basedir=/home/mamba/soft/mysql/mysql_master_3306/
datadir=/home/mamba/soft/mysql/mysql_master_3306/data/
socket=/home/mamba/soft/mysql/mysql_master_3306/tmp/mysql.sock
port=3306
user=mamba
log_timestamps=SYSTEM
collation-server = utf8_unicode_ci
character-set-server = utf8

default_authentication_plugin= mysql_native_password
language=/home/mamba/soft/mysql/mysql_master_3306/share/english


[mysqld_safe]
log-error=/home/mamba/soft/mysql/mysql_master_3306/log/mysqld_safe.err
pid-file=/home/mamba/soft/mysql/mysql_master_3306/tmp/mysqld.pid
socket=/home/mamba/soft/mysql/mysql_master_3306/tmp/mysql.sock

[mysql.server]
basedir=/home/mamba/soft/mysql/mysql_master_3306
socket=/home/mamba/soft/mysql/mysql_master_3306/tmp/mysql.sock

[mysqladmin]
socket=/home/mamba/soft/mysql/mysql_master_3306/tmp/mysql.sock
```

### 初始化
- 注意不要使用root 账号执行，注意 这个账号 mamba 需要有这个目录的权限
```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysqld  --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf --user=mamba --initialize
2019-10-16T03:08:11.548977+08:00 0 [Warning] [MY-010139] [Server] Changed limits: max_open_files: 1024 (requested 8161)
2019-10-16T03:08:11.548989+08:00 0 [Warning] [MY-010142] [Server] Changed limits: table_open_cache: 431 (requested 4000)
2019-10-16T03:08:11.549316+08:00 0 [Warning] [MY-011068] [Server] The syntax '--language/-l' is deprecated and will be removed in a future release. Please use '--lc-messages-dir' instead.
2019-10-16T03:08:11.549322+08:00 0 [Warning] [MY-010143] [Server] Ignoring user change to 'mamba' because the user was set to 'mysql' earlier on the command line
2019-10-16T03:08:11.549436+08:00 0 [System] [MY-013169] [Server] /home/mamba/soft/mysql/mysql_master_3306/bin/mysqld (mysqld 8.0.15) initializing of server in progress as process 903
2019-10-16T03:08:11.549487+08:00 0 [Warning] [MY-010339] [Server] Using pre 5.5 semantics to load error messages from /home/mamba/soft/mysql/mysql_master_3306/share/english/. If this is not intended, refer to the documentation for valid usage of --lc-messages-dir and --language parameters.
2019-10-16T03:08:11.550557+08:00 0 [Warning] [MY-013242] [Server] --character-set-server: 'utf8' is currently an alias for the character set UTF8MB3, but will be an alias for UTF8MB4 in a future release. Please consider using UTF8MB4 in order to be unambiguous.
2019-10-16T03:08:11.550581+08:00 0 [Warning] [MY-013244] [Server] --collation-server: 'utf8_unicode_ci' is a collation of the deprecated character set UTF8MB3. Please consider using UTF8MB4 with an appropriate collation instead.
2019-10-16T03:08:11.551700+08:00 0 [Warning] [MY-010122] [Server] One can only use the --user switch if running as root
2019-10-16T03:08:14.672768+08:00 5 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: 4FwhxrZgcN?T
2019-10-16T03:08:16.306676+08:00 0 [System] [MY-013170] [Server] /home/mamba/soft/mysql/mysql_master_3306/bin/mysqld (mysqld 8.0.15) initializing of server has completed
```

### 初始化数据库

```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysqld_safe --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf &
[1] 31853
[mamba@localhost mysql_master_3306]$ 2019-10-15T21:51:56.529871Z mysqld_safe Logging to '/home/mamba/soft/mysql/mysql_master_3306/log/mysqld_safe.err'.
2019-10-15T21:51:56.563380Z mysqld_safe Starting mysqld daemon with databases from /home/mamba/soft/mysql/mysql_master_3306/data/mysql/mysql_master_3306/etc/my.cnf &
```
这样我们就完整安装好且启动mysql。

### 客户端命令行方式登陆mysql　

```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysql -uroot -p -S tmp/mysql.sock
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 8.0.15

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.

```
此时需要我们重置密码.
```shell script
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'root';
FLUSH PRIVILEGES;
```
然后再次登陆就OK了
```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysql -uroot -p -S tmp/mysql.sock
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 10
Server version: 8.0.15 MySQL Community Server - GPL

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show database;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'database' at line 1
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.00 sec)

mysql>
```


## 

参考下面的安装和配置（文章的依赖包可以不需要）

[CentOs服务器下安装两个个MySql数据库踩坑日记](https://blog.csdn.net/u010898329/article/details/83064373)

## root密码是多少呢？忘记了～～

修改 my.cnf 添加 
```mysql
skip-grant-tables
```
```bash
ps -ef|grep myql
```
查看服务，然后 kill 掉 mysql，重新执行
```mysql
[mamba@localhost mysql_master_3306]$ ./bin/mysqld_safe --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf &
```
```bash
[mamba@localhost mysql_master_3306]$ ./bin/mysql -uroot -p -S tmp/mysql.sock
```
就可以免密码登陆了，

> 目前找不到办法修改 root 用户的命令。。。。一直都是失败.
> 因此就创建一个用户赋予所有权限

[ERROR 1698 (28000): Access denied for user 'root'@'localhost'](https://stackoverflow.com/questions/39281594/error-1698-28000-access-denied-for-user-rootlocalhost?noredirect=1&lq=1)

[MySQL 8.0.14 新的密码认证方式和客户端链接](https://www.cnblogs.com/yinzhengjie/p/10301516.html)


## 无法修改 root 用户的密码
查看用户的加密插件
```mysql
mysql> SELECT user,host,plugin from mysql.user;
+------------------+-----------+-----------------------+
| user             | host      | plugin                |
+------------------+-----------+-----------------------+
| root             | %         | caching_sha2_password |
| test             | %         | mysql_native_password |
| mysql.infoschema | localhost | caching_sha2_password |
| mysql.session    | localhost | caching_sha2_password |
| mysql.sys        | localhost | caching_sha2_password |
+------------------+-----------+-----------------------+
5 rows in set (0.00 sec)
```

> 在MySQL 8.0.11中，caching_sha2_password是默认的身份验证插件，而不是以往的mysql_native_password。
>有关此更改对服务器操作的影响以及服务器与客户端和连接器的兼容性的信息，
>请参阅caching_sha2_password作为首选的身份验证插件。

- 如果无法修改 root 用户的密码，那么修改创建新用户且赋予所有权限.

- 创建用户

> 先修改 root 用户的命令为空，去掉 my.cnf 的配置 skip-grant-tables 然后在赋予权限

skip-grant-tables 模式下设置 root 账号秘密为空
```mysql
UPDATE mysql.user SET authentication_string=null WHERE User='root';
FLUSH PRIVILEGES;
exit;
```

重启服务(kill 然后执行 )
[mamba@localhost mysql_master_3306]$ ./bin/mysqld_safe --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf &

登陆
```mysql
[mamba@localhost mysql_master_3306]$ ./bin/mysql -uroot -p -S tmp/mysql.sock
```

> 这里指定mysql的plugin认证方式为mysql_native_password
```mysql
use mysql;
create user test@'%' IDENTIFIED WITH mysql_native_password BY 'test'; 
```
授权
```mysql
grant all on *.* to test@'%';
```

# 安装遇到的坑

##  Failed to set datadir to '/home/mamba/soft/mysql/mysql_master_3306/data/' (OS errno: 13 - Permission denied)

不能使用root 来启动,且最好是当前用户来启动

```shell script
[mamba@localhost mysql_master_3306]$ sudo ./bin/mysqld --user=mamba --initialize --defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf
2019-10-15T18:23:44.055183Z 0 [System] [MY-013169] [Server] /home/mamba/soft/mysql/mysql_master_3306/bin/mysqld (mysqld 8.0.15) initializing of server in progress as process 8239
2019-10-15T18:23:44.057746Z 0 [ERROR] [MY-013276] [Server] Failed to set datadir to '/home/mamba/soft/mysql/mysql_master_3306/data/' (OS errno: 13 - Permission denied)
2019-10-15T18:23:44.057752Z 0 [ERROR] [MY-013236] [Server] Newly created data directory /home/mamba/soft/mysql/mysql_master_3306/data/ is unusable. You can safely remove it.
2019-10-15T18:23:44.057810Z 0 [ERROR] [MY-010119] [Server] Aborting
2019-10-15T18:23:44.057972Z 0 [System] [MY-010910] [Server] /home/mamba/soft/mysql/mysql_master_3306/bin/mysqld: Shutdown complete (mysqld 8.0.15)  MySQL Community Server - GPL.
```

## [mysql启动报错 "unknown variable 'defaults-file=/etc/my.cnf"](https://www.cnblogs.com/qiumingcheng/p/11191759.html)

使用指定的my.cnf,而不用默认的/etc/my.cnf文件，可以在启动时，
在mysqld_safe后加上参数--default-file=/usr/local/server/mysql2/etc/my.cnf，
但是要注意的是，主参数必须紧接着mysqld_safe后面，如果做第二个或者第二个以后的参数加入时，则会出现如下类似错误错误：

/usr/local/server/mysql/libexec/mysqld: unknown variable 'defaults-file=/usr/local/server/mysql2/etc/my.cnf' 且服务无法启动！

这是mysql的一个bug！

```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysqld --user=mamba --initialize --defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf
2019-10-15T18:38:08.585491Z 0 [Warning] [MY-010139] [Server] Changed limits: max_open_files: 1024 (requested 8161)
2019-10-15T18:38:08.585507Z 0 [Warning] [MY-010142] [Server] Changed limits: table_open_cache: 431 (requested 4000)
2019-10-15T18:38:08.585995Z 0 [System] [MY-013169] [Server] /home/mamba/soft/mysql/mysql_master_3306/bin/mysqld (mysqld 8.0.15) initializing of server in progress as process 15740
2019-10-15T18:38:11.932503Z 0 [ERROR] [MY-000067] [Server] unknown variable 'defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf'.
2019-10-15T18:38:11.932511Z 0 [Warning] [MY-010952] [Server] The privilege system failed to initialize correctly. If you have upgraded your server, make sure you're executing mysql_upgrade to correct the issue.
2019-10-15T18:38:11.932517Z 0 [ERROR] [MY-013236] [Server] Newly created data directory /home/mamba/soft/mysql/mysql_master_3306/data/ is unusable. You can safely remove it.
2019-10-15T18:38:11.932745Z 0 [ERROR] [MY-010119] [Server] Aborting
```

## mysqld: [ERROR] Failed to open required defaults file: /usr/mamba/soft/mysql/mysql_master_3306/etc/my.cnf

MD: 这个 my.cnf 文件指定错误。。。。不是在这个文件夹里。我擦,注意你指定的 my.cnf 文件路径是否正确
```shell script
[mamba@localhost mysql_master_3306]$ ./bin/mysqld  --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf --user=mamba --initialize
mysqld: [ERROR] Failed to open required defaults file: /usr/soft/mysql/mysql_master_3306/etc/my.cnf
mysqld: [ERROR] Fatal error in defaults handling. Program aborted!
```


## [ERROR] [MY-013236] [Server] Newly created data directory  is unusable. You can safely remove it.

> MYSQL安装报错 -- 出现 Failed to find valid data directory.

解决方法：手动删掉自己创建的data文件夹   

## ‘./mysql-bin.index' not found (Errcode: 13)

errcode13，一般就是权限问题，mysql用户是否对数据库目录内的所有文件具有写的权限，查看一下权限，修改MySQL目录的用户和用户组权限：

> chown -R mysql:mysql 对应目录的权限

## 参考

[CentOS安装多版本MySQL](https://www.voidking.com/dev-centos-multiple-mysql/)

[centos7安装运行多个mysql实例笔记](https://my.oschina.net/hollowj/blog/796146)

[centos7.4下mysql8.0多实例安装](http://www.fdlly.com/p/283198450.html)

[mysql8.0.11用户密码设置注意事项](https://blog.csdn.net/ligaofeng/article/details/80022448)

