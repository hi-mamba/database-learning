

# mysql8.x安装遇到的坑

## 安装

[mysql下载地址](https://dev.mysql.com/downloads/mysql/8.0.html#downloads)

解压tar // 注意 tar -xvf xxx.tar 不需要 -zxvf 有参数z 可能有问题.

参考下面的安装和配置（文章的依赖包可以不需要）
[CentOs服务器下安装两个个MySql数据库踩坑日记](https://blog.csdn.net/u010898329/article/details/83064373)

- 指定配置文件初始化
进入当前安装的mysql 文件夹
```mysql
./bin/mysqld --initalize --use=mysql --basedir=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16 --data=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/data defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf
```

```bash
2019-08-07T08:58:01.625666Z 0 [Warning] [MY-011070] [Server] 'Disabling symbolic links using --skip-symbolic-links (or equivalent) is the default. Consider not using this option as it' is deprecated and will be removed in a future release.
2019-08-07T08:58:01.628129Z 0 [System] [MY-010116] [Server] /usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/bin/mysqld (mysqld 8.0.16) starting as process 18037
2019-08-07T08:58:01.644195Z 0 [ERROR] [MY-013276] [Server] Failed to set datadir to '/usr/soft/mysql/mysql_master_3306/mysql-8.0.16/data/' (OS errno: 13 - Permission denied)
2019-08-07T08:58:01.644682Z 0 [ERROR] [MY-010119] [Server] Aborting
2019-08-07T08:58:01.650060Z 0 [System] [MY-010910] [Server] /usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/bin/mysqld: Shutdown complete (mysqld 8.0.16)  MySQL Community Server - GPL.
```

- 需要赋予mysql用户权限
```bash
chown -R mysql:mysql /usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/
```

- 初始化数据库
```mysql
./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf &
```
这个时候 mysql 服务就启来了，但是 root密码是多少呢？忘记了～～

修改 my.cnf 添加 
```mysql
skip-grant-tables
```
```bash
ps -ef|grep myql
```
查看服务，然后 kill 掉 mysql，重新执行
```mysql
./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf &
```

```bash
mysql -uroot -p -S /tmp/mysql3307.sock
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

## 创建用户

> 先修改 root 用户的命令为空，去掉 my.cnf 的配置 skip-grant-tables 然后在赋予权限

skip-grant-tables 模式下设置 root 账号秘密为空
```mysql
UPDATE mysql.user SET authentication_string=null WHERE User='root';
FLUSH PRIVILEGES;
exit;
```

重启服务(kill 然后执行 )
> ./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf &

登陆
```mysql
mysql -u root -p  -S /tmp/mysql3306.sock
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

## 赋予权限，不能使用 root 启动
```mysql
chown -R mysql:mysql /usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/

./bin/mysqld --initalize --user=mysql --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf

./bin/mysqld --initalize --user=mysql --basedir=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16  --datadir=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/data --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf

./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/etc/my.cnf &
```




```mysql

[root@SVNServer bin]# /etc/init.d/mysqld start
Starting MySQL. ERROR! The server quit without updating PID file (/data/mysql/AY14020816093477605eZ.pid).

```
重启mysql会抛出上面红色字体的错误。

上面只能看到mysql启动失败，具体的原因，需要查看数据库目录下的.err文件，查看.err文件，内容如下：
```
140726 00:18:10 mysqld_safe mysqld from pid file /data/mysql/AY14020816093477605eZ.pid ended

140726 00:31:19 mysqld_safe Starting mysqld daemon with databases from /data/mysql

/usr/local/mysql/bin/mysqld: File ‘./mysql-bin.index' not found (Errcode: 13)

140726  0:31:19 [ERROR] Aborting

140726  0:31:19 [Note] /usr/local/mysql/bin/mysqld: Shutdown complete
```
红色字标出来的就是这次错误报告，errcode13，一般就是权限问题，mysql用户是否对数据库目录内的所有文件具有写的权限，查看一下权限，修改MySQL目录的用户和用户组权限：

> chown -R mysql:mysql   /usr/local/mysql



## MYSQL安装报错 -- 出现 Failed to find valid data directory.

解决方法：  
1、手动删掉自己创建的data文件夹   
2、然后再管理员cmd下进入 bin 目录，移除自己的mysqld服务
```bash
D:\Program Files\MySQL\bin>mysqld -remove MySQL
Service successfully removed.
```
3、在cmd的bin目录执行 
> mysqld --initialize-insecure  

程序会在动MySQL文件夹下创建data文件夹以及对应的文件
```bash
[root@localhost mysql-8.0.16]# ./bin/mysqld --initialize-insecure
[root@localhost mysql-8.0.16]# ls data/
auto.cnf    client-cert.pem  ibdata1      #innodb_temp  performance_schema  server-cert.pem  undo_001
ca-key.pem  client-key.pem   ib_logfile0  mysql         private_key.pem     server-key.pem   undo_002
ca.pem      ib_buffer_pool   ib_logfile1  mysql.ibd     public_key.pem      sys
```

这里执行完成需要再次赋予 mysql 权限
> chown -R mysql:mysql /usr/soft/mysql/mysql_slave_3307/mysql-8.0.16/

## 参考

[CentOS安装多版本MySQL](https://www.voidking.com/dev-centos-multiple-mysql/)

[centos7安装运行多个mysql实例笔记](https://my.oschina.net/hollowj/blog/796146)

[centos7.4下mysql8.0多实例安装](http://www.fdlly.com/p/283198450.html)

[mysql8.0.11用户密码设置注意事项](https://blog.csdn.net/ligaofeng/article/details/80022448)

