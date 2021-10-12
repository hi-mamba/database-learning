## [原文](https://www.cnblogs.com/letcafe/p/mysqlautodump.html)


# MySQL数据备份

### 1.1、 mysqldump命令备份数据
在MySQL中提供了命令行导出数据库数据以及文件的一种方便的工具mysqldump,我们可以通过命令行直接实现数据库内容的导出dump,首先我们简单了解一下mysqldump命令用法:

## MySQLdump常用
```mysql
mysqldump -u root -p --databases 数据库1 数据库2 > xxx.sql
```
### 1.2、 mysqldump常用操作示例
1.备份全部数据库的数据和结构
```myql
mysqldump -uroot -p123456 -A > /data/mysqlDump/mydb.sql
```
2.备份全部数据库的结构（加 -d 参数）
```mysql
mysqldump -uroot -p123456 -A -d > /data/mysqlDump/mydb.sql
```
3.备份全部数据库的数据(加 -t 参数)
```mysql
mysqldump -uroot -p123456 -A -t > /data/mysqlDump/mydb.sql
```
4.备份单个数据库的数据和结构(,数据库名mydb)
```mysql
mysqldump -uroot-p123456 mydb > /data/mysqlDump/mydb.sql
```
5.备份单个数据库的结构
```mysql
mysqldump -uroot -p123456 mydb -d > /data/mysqlDump/mydb.sql
```
6.备份单个数据库的数据
```mysql
mysqldump -uroot -p123456 mydb -t > /data/mysqlDump/mydb.sql
```
7.备份多个表的数据和结构（数据，结构的单独备份方法与上同）
```mysql
mysqldump -uroot -p123456 mydb t1 t2 > /data/mysqlDump/mydb.sql
```
8.一次备份多个数据库
```mysql
mysqldump -uroot -p123456 --databases db1 db2 > /data/mysqlDump/mydb.sql
```
### 1.3、 还原mysql备份内容
有两种方式还原，第一种是在MySQL命令行中，第二种是使用SHELL行完成还原

1.在系统命令行中，输入如下实现还原：
```mysql
mysql -uroot -p123456 < /data/mysqlDump/mydb.sql
```
2.在登录进入mysql系统中,通过source指令找到对应系统中的文件进行还原：
```mysql
mysql> source /data/mysqlDump/mydb.sql
```

