
## [原文](https://blog.csdn.net/fanxl10/article/details/52800985)

# Mysql解决中文乱码及其支持emoji表情存储

正常使用uft-8方式存储是不能存储emoji表情文字的，主要原因是uft8字节不够，导致存储不了，
需要更改为uft8mb4，下面说说具体操作步骤：

## 1、需要你的mysql数据库版本在5.5以上；

## 2、更改你的数据库，表，以及需要存储emoji列的编码方式；

```mysql
# 对每一个数据库:
ALTER DATABASE 这里数据库名字 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
# 对每一个表:
ALTER TABLE 这里是表名字 CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# 对存储emoji表情的字段:
ALTER TABLE 这里是表名字 CHANGE 字段名字 字段名字 VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

utf8mb4完全向后兼容utf8，无乱码或其他数据丢失的形式出现。理论上是可以放心修改，如果您不放心修改，您可以拿备份恢复数据

## 3、修改my.ini（或者是my.cnf）数据库配置

> ps mac 安装mysql 后，没有配置文件，如果需要添加配置文件，需要在/etc 目录下面添加 my.cnf 文件。 添加方法
> 打开文件命令：sudo vi  /etc/my.cnf

添加如下配置

修改mysql配置文件/etc/my.cnf。
```mysql
[mysqld]
character-set-server=utf8 
[client]
default-character-set=utf8 
[mysql]
default-character-set=utf8
```

- 当然了，如果需要支持表情，需要修改成下面的 utf8mb4

```mysql
[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

## 4、修改服务器数据库连接配置
把连接上面的characterEncoding=utf-8去掉

## 5、重启mysql数据库
这个时候应该就可以保存emoji表情了，你还可以登录数据库，查询看下
```mysql
SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%' OR Variable_name LIKE 'collation%';

```
最后，还可以用以下两条命令对表进行修复和优化，跑到这一步其实没有任何必要修复和优化表，为了保险起见，
我还是运行了这两条命令，虽然不知道它有什么卵用，放在这里做个笔记吧

REPAIR TABLE 表名字;

OPTIMIZE TABLE 表名字;


