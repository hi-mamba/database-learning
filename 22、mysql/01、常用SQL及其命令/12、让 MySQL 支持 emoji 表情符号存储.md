

## [原文](https://www.hi-linux.com/posts/50680.html)

# 让 MySQL 支持 emoji 表情符号存储


MySQL的文本(varchar,text)，对emoji表情符号不是很好的支持，
在5.5之前的版本，varchar和text都是不支持存储emoji表情符号的（即使是utf8）的编码模式。
原因在于mysql的utf8是规定了每一个utf8字符按照3个字节来存储，
而一个emoji（最初来自苹果系统，现在流行于各种移动操作系统）却需要4个字节来存储。
这就导致了如果强制将emoji存储到varchar，text等字段上的时候，
mysql会抛出异常，认为emoji是个不正确的文本。
```sql
ERROR 1366 (HY000): Incorrect string value: ‘\xF0\x9F\x91\xBD\xF0\x9F…’ for column ‘name’ at row 31

```
其原因是utf8是不定长的，根据左侧位来决定占用了几个字节。
emoji表情是4个字节，而MySQL的utf8编码最多支持3个字节，所以插入会出错。

为了解决这个问题，MySQL 5.5开始支持utf8mb4,
utf8mb4可支持4个字节utf编码，从而支持更大的字符集，并且兼容utf8。
简单来说，utf8mb4是utf8的超集。

要让MySQL开启utf8mb4支持，需要一些额外的设置。

## 检查MySQL Server版本
utf8mb4 支持需要MySQL Server v5.5.3+

## 设置

### 设置表的CHARSET
创建表的时候指定CHARSET为utf8mb4

```sql 
CREATE TABLE IF NOT EXISTS table_name (
...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;

```
### 修改数据库字符集
```sql
ALTER DATABASE database_name CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

```

### 修改表的字符集
```sql

ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; #将TABLE_NAME替换成你的表名
ALTER TABLE table_name modify name text charset utf8mb4;
```

### 修改字段的字符集
```sql
ALTER TABLE table_name CHANGE column_name column_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

```
## 修改MySQL配置文件
修改my.cnf的内容
```sql
[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect='SET  NAMES utf8mb4'
```

检查是否生效
正常情况下的结果应该如下所示

```sql
mysql> SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%' OR   Variable_name LIKE 'collation%';
+--------------------------+--------------------+
| Variable_name            | Value              |
+--------------------------+--------------------+
| character_set_client     | utf8mb4            |
| character_set_connection | utf8mb4            |
| character_set_database   | utf8mb4            |
| character_set_filesystem | binary             |
| character_set_results    | utf8mb4            |
| character_set_server     | utf8mb4            |
| character_set_system     | utf8               |
| collation_connection     | utf8mb4_unicode_ci |
| collation_database       | utf8mb4_unicode_ci |
| collation_server         | utf8mb4_unicode_ci |
+--------------------------+--------------------+

```
如果修改以上都不行请查询

```sql
mysql> show variables like '%sql_mode%'; 
+---------------+--------------------------------------------+
| Variable_name | Value                                      |
+---------------+--------------------------------------------+
| sql_mode      | STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION |
+---------------+--------------------------------------------+
1 row in set (0.00 sec)

```
如果是以上结果恭喜你是存储不了的

去设置这个sql_mod模式(注意这里修改看之后要退出控制台要不然还是看不到效果的，
而且这个配置写my.cnf重启服务器是不生效的)

```sql
mysql> show variables like '%sql_mode%';
+---------------+--------------------------------------------+
| Variable_name | Value                                      |
+---------------+--------------------------------------------+
| sql_mode      | STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION |
+---------------+--------------------------------------------+
1 row in set (0.00 sec)

```
### 指定MySQL连接时的charset
以mysql-python为例
```sql
MySQLdb.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        user=config.DB_USR,
        passwd=config.DB_PSW,
        db=config.DB_NAME,
        use_unicode=True,
        charset="utf8mb4")

```        
参考文档

<http://en.wikipedia.org/wiki/Mapping_of_Unicode_characters>
<http://dev.mysql.com/doc/refman/5.5/en/charset-unicode-utf8mb4.html>
<https://mathiasbynens.be/notes/mysql-utf8mb4#utf8-to-utf8mb4>
<http://blog.caoyue.me/post/support-emoji-in-mysql>

