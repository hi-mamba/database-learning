## [原文](https://www.jianshu.com/p/8fab76bbf448)

# Explain 详解各字段含义


![](../../images/mysql/explain/expain_1.png)

Extra字段显示Using temporary，表示的是需要使用临时表；Using filesort，表示的是需要执行排序操作。

因此这个Extra的意思就是，需要临时表，并且需要在临时表上排序。

## explain结果每个字段的含义说明

我们都知道用explain xxx分析sql语句的性能，但是具体从explain的结果怎么分析性能以及每个字段的含义你清楚吗？
这里我做下总结记录，也是供自己以后参考。

首先需要注意：MYSQL 5.6.3以前只能EXPLAIN SELECT; MYSQL5.6.3以后就可以EXPLAIN SELECT,UPDATE,DELETE


explain结果示例：
```mysql
mysql> explain select * from staff;
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
|  1 | SIMPLE      | staff | ALL  | NULL          | NULL | NULL    | NULL |    2 | NULL  |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
1 row in set
```

先上一个官方文档表格的中文版：

Column | 含义
|---|---
id             | 查询序号
select_type    | 查询类型
table          | 表名
partitions     | 匹配的分区
type           |join类型
prossible_keys |可能会选择的索引
key            | 实际选择的索引
key_len        | 索引的长度
ref            | 与索引作比较的列
rows           | 要检索的行数(估算值)
filtered       | 查询条件过滤的行数的百分比
Extra          | 额外信息

 
这是explain结果的各个字段，分别解释下含义：
## 1. id
SQL查询中的序列号。

> id列数字越大越先执行，如果说数字一样大，那么就从上往下依次执行。


## 2. select_type
查询的类型，可以是下表的任何一种类型：

select_type | 类型说明
|---|---
SIMPLE   | 简单SELECT(不使用UNION或子查询)
PRIMARY  | 最外层的SELECT
UNION    | UNION中第二个或之后的SELECT语句
DEPENDENT UNION  | UNION中第二个或之后的SELECT语句取决于外面的查询
UNION RESULT     | UNION的结果
SUBQUERY  | 子查询中的第一个SELECT
DEPENDENT SUBQUERY | 子查询中的第一个SELECT, 取决于外面的查询
DERIVED   | 衍生表(FROM子句中的子查询)
MATERIALIZED | 物化子查询
UNCACHEABLE SUBQUERY  | 结果集无法缓存的子查询，必须重新评估外部查询的每一行
UNCACHEABLE UNION  | UNION中第二个或之后的SELECT，属于无法缓存的子查询
DEPENDENT | 意味着使用了关联子查询。

## 3. table
查询的表名。不一定是实际存在的表名。
可以为如下的值：

- <unionM,N>: 引用id为M和N UNION后的结果。
- <derivedN>: 引用id为N的结果派生出的表。派生表可以是一个结果集，例如派生自FROM中子查询的结果。
- <subqueryN>: 引用id为N的子查询结果物化得到的表。即生成一个临时表保存子查询的结果。

## 4. type（重要）
这是最重要的字段之一，显示查询使用了何种类型。从最好到最差的连接类型依次为：

> system，const，eq_ref，ref，fulltext，ref_or_null，index_merge，unique_subquery，index_subquery，range，index，ALL

除了all之外，其他的type都可以使用到索引，除了index_merge之外，其他的type只可以用到一个索引。


### 1、system
表中只有一行数据或者是空表，这是const类型的一个特例。且只能用于myisam和memory表。如果是Innodb引擎表，type列在这个情况通常都是all或者index

### 2、const
最多只有一行记录匹配。当联合主键或唯一索引的所有字段跟常量值比较时，join类型为const。其他数据库也叫做唯一索引扫描

### 3、eq_ref
多表join时，对于来自前面表的每一行，在当前表中只能找到一行。这可能是除了system和const之外最好的类型。
当主键或唯一非NULL索引的所有字段都被用作join联接时会使用此类型。
eq_ref可用于使用'='操作符作比较的索引列。比较的值可以是常量，也可以是使用在此表之前读取的表的列的表达式。

> 相对于下面的ref区别就是它使用的唯一索引，即主键或唯一索引，而ref使用的是非唯一索引或者普通索引。
eq_ref只能找到一行，而ref能找到多行。


### 4、ref
对于来自前面表的每一行，在此表的索引中可以匹配到多行。若联接只用到索引的最左前缀或索引不是主键或唯一索引时，
使用ref类型（也就是说，此联接能够匹配多行记录）。

ref可用于使用'='或'<=>'操作符作比较的索引列。


### 5、 fulltext
使用全文索引的时候是这个类型。要注意，全文索引的优先级很高，若全文索引和普通索引同时存在时，mysql不管代价，优先选择使用全文索引


### 6、ref_or_null


跟ref类型类似，只是增加了null值的比较。实际用的不多。
```
eg.
SELECT * FROM ref_table
WHERE key_column=expr OR key_column IS NULL;
```
### 7、index_merge

表示查询使用了两个以上的索引，最后取交集或者并集，常见and ，or的条件使用了不同的索引，官方排序这个在ref_or_null之后，
但是实际上由于要读取多个索引，性能可能大部分时间都不如range

### 8、unique_subquery

用于where中的in形式子查询，子查询返回不重复值唯一值，可以完全替换子查询，效率更高。
该类型替换了下面形式的IN子查询的ref：
```
value IN (SELECT primary_key FROM single_table WHERE some_expr)
```

### 9、index_subquery
该联接类型类似于unique_subquery。适用于非唯一索引，可以返回重复值。

### 10、range

索引范围查询，常见于使用 =, <>, >, >=, <, <=, IS NULL, <=>, BETWEEN, IN()或者like等运算符的查询中。
```mysql
SELECT * FROM tbl_name
  WHERE key_column BETWEEN 10 and 20;

SELECT * FROM tbl_name
  WHERE key_column IN (10,20,30);

```
### 11、index

索引全表扫描，把索引从头到尾扫一遍。这里包含两种情况：
一种是查询使用了覆盖索引，那么它只需要扫描索引就可以获得数据，这个效率要比全表扫描要快，因为索引通常比数据表小，而且还能避免二次查询。
在extra中显示Using index，反之，如果在索引上进行全表扫描，没有Using index的提示。
```mysql
# 此表见有一个name列索引。
# 因为查询的列name上建有索引，所以如果这样type走的是index
mysql> explain select name from testa;
+----+-------------+-------+-------+---------------+----------+---------+------+------+-------------+
| id | select_type | table | type  | possible_keys | key      | key_len | ref  | rows | Extra       |
+----+-------------+-------+-------+---------------+----------+---------+------+------+-------------+
|  1 | SIMPLE      | testa | index | NULL          | idx_name | 33      | NULL |    2 | Using index |
+----+-------------+-------+-------+---------------+----------+---------+------+------+-------------+
1 row in set

# 因为查询的列cusno没有建索引，或者查询的列包含没有索引的列，这样查询就会走ALL扫描，如下：
mysql> explain select cusno from testa;
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
|  1 | SIMPLE      | testa | ALL  | NULL          | NULL | NULL    | NULL |    2 | NULL  |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
1 row in set

# 包含有未见索引的列
mysql> explain select * from testa;
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
|  1 | SIMPLE      | testa | ALL  | NULL          | NULL | NULL    | NULL |    2 | NULL  |
+----+-------------+-------+------+---------------+------+---------+------+------+-------+
1 row in set

```


### 12、all

全表扫描，性能最差。

## 5. partitions
版本5.7以前，该项是explain partitions显示的选项，5.7以后成为了默认选项。该列显示的为分区表命中的分区情况。非分区表该字段为空（null）。
## 6. possible_keys
查询可能使用到的索引都会在这里列出来
## 7. key
查询真正使用到的索引。
select_type为index_merge时，这里可能出现两个以上的索引，其他的select_type这里只会出现一个。
## 8. key_len
查询用到的索引长度（字节数）。
如果是单列索引，那就整个索引长度算进去，如果是多列索引，那么查询不一定都能使用到所有的列，用多少算多少。留意下这个列的值，算一下你的多列索引总长度就知道有没有使用到所有的列了。

> key_len只计算where条件用到的索引长度，而排序和分组就算用到了索引，也不会计算到key_len中。

## 9. ref
如果是使用的常数等值查询，这里会显示const，如果是连接查询，被驱动表的执行计划这里会显示驱动表的关联字段，如果是条件使用了表达式或者函数，或者条件列发生了内部隐式转换，这里可能显示为func

## 10. rows（重要）
rows 也是一个重要的字段。 这是mysql估算的需要扫描的行数（不是精确值）。
这个值非常直观显示 SQL 的效率好坏, 原则上 rows 越少越好.

## 11. filtered
这个字段表示存储引擎返回的数据在server层过滤后，剩下多少满足查询的记录数量的比例，注意是百分比，不是具体记录数。这个字段不重要

## 12. extra（重要）
EXplain 中的很多额外的信息会在 Extra 字段显示, 常见的有以下几种内容:


distinct：在select部分使用了distinc关键字

Using filesort：当 Extra 中有 Using filesort 时, 表示 MySQL 需额外的排序操作, 不能通过索引顺序达到排序效果. 
一般有 Using filesort, 都建议优化去掉, 因为这样的查询 CPU 资源消耗大.
```mysql
# 例如下面的例子:

mysql> EXPLAIN SELECT * FROM order_info ORDER BY product_name \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: order_info
   partitions: NULL
         type: index
possible_keys: NULL
          key: user_product_detail_index
      key_len: 253
          ref: NULL
         rows: 9
     filtered: 100.00
        Extra: Using index; Using filesort
1 row in set, 1 warning (0.00 sec)
我们的索引是

KEY `user_product_detail_index` (`user_id`, `product_name`, `productor`)
但是上面的查询中根据 product_name 来排序, 因此不能使用索引进行优化, 进而会产生 Using filesort.
如果我们将排序依据改为 ORDER BY user_id, product_name, 那么就不会出现 Using filesort 了. 例如:

mysql> EXPLAIN SELECT * FROM order_info ORDER BY user_id, product_name \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: order_info
   partitions: NULL
         type: index
possible_keys: NULL
          key: user_product_detail_index
      key_len: 253
          ref: NULL
         rows: 9
     filtered: 100.00
        Extra: Using index
1 row in set, 1 warning (0.00 sec)

```

- Using index
"覆盖索引扫描", 表示查询在索引树中就可查找所需数据, 不用扫描表数据文件, 往往说明性能不错

- Using temporary
查询有使用临时表, 一般出现于排序, 分组和多表 join 的情况, 查询效率不高, 建议优化.

除此之外还有其他值，这里就不一一一列举了。

通过以上这些总结，以后我们看到explain的结果，就知道该从哪些字段值去分析sql语句的执行效率了。


