

## [原文](https://blog.csdn.net/yageeart/article/details/7973381)

# MySQL 查看表结构简单命令

## 一、简单描述表结构，字段类型

```sql
desc tabl_name;
```

显示表结构，字段类型，主键，是否为空等属性，但不显示外键。


## 二、查询表中列的注释信息

```sql
select * from information_schema.columns

where table_schema = 'db'  #表所在数据库

and table_name = 'tablename' ; #你要查的表

```

## 三、只查询列名和注释
```sql
select  column_name, column_comment 
from information_schema.columns
where table_schema ='db'  and table_name = 'tablename' ;

```

## 四、查看表的注释

```sql

select table_name,table_comment from information_schema.tables  
where table_schema = 'db' and table_name ='tablename'

```

ps：二～四是在元数据表中查看，我在实际操作中，常常不灵光，不知为什么，有了解的大侠请留印。


## 五、查看表生成的DDL 

```sql
show create table table_name;

```

这个命令虽然显示起来不是太容易看， 这个不是问题可以用\G来结尾，使得结果容易阅读；
该命令把创建表的DDL显示出来，于是表结构、类型，外键，备注全部显示出来了。
我比较喜欢这个命令：输入简单，显示结果全面。