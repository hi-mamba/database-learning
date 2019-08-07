

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

> 这里指定mysql的plugin认证方式为mysql_native_password
```mysql
create user test@'%' IDENTIFIED WITH mysql_native_password BY 'test'; 
```
授权
```mysql
grant all on *.* to test@'%';
```


## 参考

[CentOS安装多版本MySQL](https://www.voidking.com/dev-centos-multiple-mysql/)

[centos7安装运行多个mysql实例笔记](https://my.oschina.net/hollowj/blog/796146)

[centos7.4下mysql8.0多实例安装](http://www.fdlly.com/p/283198450.html)

[mysql8.0.11用户密码设置注意事项](https://blog.csdn.net/ligaofeng/article/details/80022448)

