## [原文](http://www.cnblogs.com/chenmh/p/5623474.html)

# mysql分区介绍


## 介绍
分区是指根据一定的规则将一个大表分解成多个更小的部分，这里的规则一般就是利用分区规则将表进行水平切分；
逻辑上没有发生变化但实际上表已经被拆分成了多个物理对象，每个分成被划分成了一个独立的对象。
相对于没有分区的当个表而言分区的表有很多的优势包括： 并发统计查询、快速归档删除分区数据、分散存储、查询性能更佳。

mysql5.7以后查询语句支持指定分区例如：“ SELECT * FROM t PARTITION (p0,p1) WHERE c < 5 ”指定分区同样适用DELETE, 
INSERT, REPLACE, UPDATE, and LOAD DATA, LOAD XML.

数据库版本：mysql5.7.12

- 是否支持分区
```mysql
SHOW PLUGINS ;

```

查询partition的的状态是active就代表支持分区，如果是源码安装的话在编译的过程中要添加“-DWITH_PARTITION_STORAGE_ENGINE=1 \”。

注意： MERGE, CSV, or FEDERATED存储引擎不支持分区，同一个表所有的分区必须使用相同的存储引擎，
不能分区1使用MYISAM分区2又使用INNODB；不同的分区表可以是不同的存储引擎。

## 分区介绍

目前mysql可用的分区类型主要有以下几种：

RANGE分区：基于一个给定的连续区间范围，RANGE主要是基于整数的分区，对于非整形的字段需要利用表达式将其转换成整形。

LIST分区：是基于列出的枚举值列表进行分区。

COLUMNS分区：可以无需通过表达式进行转换直接对非整形字段进行分区，同时COLUMNS分区还支持多个字段组合分区，
只有RANGELIST存在COLUMNS分区，COLUMNS是RANGE和LIST分区的升级。

HASH分区：基于给定的分区个数，将数据分配到不同的分区，HASH分区只能针对整数进行HASH，对于非整形的字段只能通过表达式将其转换成整数。

KEY分区：支持除text和BLOB之外的所有数据类型的分区,key分区可以直接基于字段做分区无需转换成整数。

 

## 说明

1. 注意分区名的大小写敏感问题，和关键字问题。

2. 无论哪种分区类型，要么分区表中没有主键或唯一键，要么主键或唯一键包含在分区列里面，对于存在主键或者唯一键的表不能使用主键或者唯一键之外的字段作为分区字段。

3.5.7以前的版本显示分区的执行计划使用：explain PARTITIONS；5.7以后直接执行：explain

4.没有强制要求分区列非空，建议分区的列为NOT NULL的列；在RANGE 分区中如果往分区列中插入NULL值会被当作最小的值来处理，
在LIST分区中NULL值必须在枚举列表中否则插入失败，在HASH/KEY分区中NULL值会被当作0来处理。

5.基于时间类型的字段的转换函数mysql提供了"YEAR(),MONTH(),DAY(),TO_DAYS(),TO_SECONDS(),WEEKDAY(),DAYOFYEAR()"

6.拆分合并分区后会导致修改的分区的统计信息失效,没有修改的分区的统计信息还在,不影响新插入的值加入到统计信息；这时需要对表执行Analyze操作.

7.针对非整形字段进行RANG\LIST分区建议使用COLUMNS分区。

 

## 删除增加分区

在每个分区内容介绍中详细介绍了每种分区的用法，但是都是介绍在创建表的时候创建分区和修改删除分区单个，
也可以在一张已经存在的表中加入分区，可以一次性删除整个表的分区。

1. 移除表的分区
```mysql

ALTER TABLE tablename
REMOVE PARTITIONING ;

```
注意：使用remove移除分区是仅仅移除分区的定义，并不会删除数据和drop PARTITION不一样，后者会连同数据一起删除

2. 对已经存在记录的表创建分区，以增加range分区为例，和创建表建分区的语法一样。

```mysql
ALTER TABLE `tb_partition`.`tb_varchar` 
PARTITION BY RANGE(id) PARTITIONS 3( PARTITION part0 VALUES LESS THAN (5000),  PARTITION part1 VALUES LESS THAN (10000),  PARTITION part2 VALUES LESS THAN (MAXVALUE)) ;

```
注意：对已有的表创建分区之后，数据会按照分区的定义分布到各个分区文件当中

 

## 分区系列文章： 

RANGE分区：<http://www.cnblogs.com/chenmh/p/5627912.html>

LIST分区：<http://www.cnblogs.com/chenmh/p/5643174.html>

COLUMN分区：<http://www.cnblogs.com/chenmh/p/5630834.html>

HASH分区：<http://www.cnblogs.com/chenmh/p/5644496.html>

KEY分区：<http://www.cnblogs.com/chenmh/p/5647210.html>

子分区：<http://www.cnblogs.com/chenmh/p/5649447.html>

指定各分区路径：<http://www.cnblogs.com/chenmh/p/5644713.html>

分区建索引：<http://www.cnblogs.com/chenmh/p/5761995.html>

分区介绍总结：<http://www.cnblogs.com/chenmh/p/5623474.html>

## 总结
具体的每个分区的详细介绍参考接下来的各分区详解。一个表只能存在一种分区形式，如果对一张表创建多个分区后一个分区会替换掉前一个分区。 
