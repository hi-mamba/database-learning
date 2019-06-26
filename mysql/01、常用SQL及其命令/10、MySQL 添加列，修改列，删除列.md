
## [原文](https://www.cnblogs.com/zhanqi/archive/2011/01/05/1926608.html)

# MySQL 添加列，修改列，删除列

ALTER TABLE：添加，修改，删除表的列，约束等表的定义。

```mysql


查看列：desc 表名;

修改表名：alter table t_book rename to bbb;

添加列：alter table 表名 add column 列名 varchar(30);

删除列：alter table 表名 drop column 列名;

mysql删除多个字段：alter table tablename drop column1,drop column2

修改列名MySQL： alter table bbb change nnnnn hh int;

修改列名SQLServer：exec sp_rename't_student.name','nn','column';

修改列名Oracle：lter table bbb rename column nnnnn to hh int;

修改列属性：alter table t_book modify name varchar(22);

```

sp_rename：SQLServer 内置的存储过程，用与修改表的定义。

## mysql 触发器自动更新时间

字段的设置
```mysql

`update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
```
