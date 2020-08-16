
##### [原文](https://cloud.tencent.com/developer/article/1631810)

#  SQL实现统计排名

### 前言： 

在某些应用场景中，我们经常会遇到一些排名的问题，比如按成绩或年龄排名。排名也有多种排名方式，
如直接排名、分组排名，排名有间隔或排名无间隔等等，这篇文章将总结几种MySQL中常见的排名问题。

### 创建测试表
```mysql
create table scores_tb (
    id int  auto_increment primary key,
    xuehao int not null, 
    score int not null
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
insert into scores_tb (xuehao,score) values (1001,89),(1002,99),(1003,96),(1004,96),(1005,92),(1006,90),(1007,90),(1008,94);
```
 查看下插入的数据
```mysql
mysql> select * from scores_tb;
+----+--------+-------+
| id | xuehao | score |
+----+--------+-------+
|  1 |   1001 |    89 |
|  2 |   1002 |    99 |
|  3 |   1003 |    96 |
|  4 |   1004 |    96 |
|  5 |   1005 |    92 |
|  6 |   1006 |    90 |
|  7 |   1007 |    90 |
|  8 |   1008 |    94 |
+----+--------+-------+
```

## 1.普通排名
按分数高低直接排名，从1开始，往下排，类似于row number。下面我们给出查询语句及排名结果。

### 查询语句
```mysql
SELECT xuehao, score, @curRank := @curRank + 1 AS rank
FROM scores_tb, (
SELECT @curRank := 0
) r
ORDER BY score desc;
```
排序结果
```
+--------+-------+------+
| xuehao | score | rank |
+--------+-------+------+
|   1002 |    99 |    1 |
|   1003 |    96 |    2 |
|   1004 |    96 |    3 |
|   1008 |    94 |    4 |
|   1005 |    92 |    5 |
|   1006 |    90 |    6 |
|   1007 |    90 |    7 |
|   1001 |    89 |    8 |
+--------+-------+------+
```
上述查询语句中，我们申明了一个变量 @curRank ,并将此变量初始化为0，查得一行将此变量加一，
并以此作为排名。我们看到这类排名是没间隔的并且有些分数相同但排名不同。

## 2.分数相同，名次相同，排名无间隔

查询语句
```mysql 
SELECT xuehao, score, 
CASE
WHEN @prevRank = score THEN @curRank
WHEN @prevRank := score THEN @curRank := @curRank + 1
END AS rank
FROM scores_tb, 
(SELECT @curRank :=0, @prevRank := NULL) r
ORDER BY score desc;
```

排名结果
```mysql
+--------+-------+------+
| xuehao | score | rank |
+--------+-------+------+
|   1002 |    99 | 1    |
|   1003 |    96 | 2    |
|   1004 |    96 | 2    |
|   1008 |    94 | 3    |
|   1005 |    92 | 4    |
|   1006 |    90 | 5    |
|   1007 |    90 | 5    |
|   1001 |    89 | 6    |
+--------+-------+------+
```
### 3.并列排名，排名有间隔
另外一种排名方式是相同的值排名相同，相同值的下一个名次应该是跳跃整数值，即排名有间隔。

查询语句
```mysql
SELECT xuehao, score, rank FROM
(SELECT xuehao, score,
@curRank := IF(@prevRank = score, @curRank, @incRank) AS rank, 
@incRank := @incRank + 1, 
@prevRank := score
FROM scores_tb, (
SELECT @curRank :=0, @prevRank := NULL, @incRank := 1
) r
ORDER BY score desc) s;
```
排名结果
```
+--------+-------+------+
| xuehao | score | rank |
+--------+-------+------+
|   1002 |    99 | 1    |
|   1003 |    96 | 2    |
|   1004 |    96 | 2    |
|   1008 |    94 | 4    |
|   1005 |    92 | 5    |
|   1006 |    90 | 6    |
|   1007 |    90 | 6    |
|   1001 |    89 | 8    |
+--------+-------+------+
```
上面介绍了三种排名方式，实现起来还是比较复杂的。好在MySQL8.0增加了窗口函数，使用内置函数可以轻松实现上述排名。

MySQL8.0 利用窗口函数实现排名

MySQL8.0中可以利用 ROW_NUMBER()，DENSE_RANK()，RANK() 三个窗口函数实现上述三种排名，
需要注意的一点是as后的别名，千万不要与前面的函数名重名，否则会报错，下面给出这三种函数实现排名的案例：

## 三条语句对于上面三种排名
```mysql
select xuehao,score, ROW_NUMBER() OVER(order by score desc) as row_r from scores_tb;
select xuehao,score, DENSE_RANK() OVER(order by score desc) as dense_r from scores_tb;
select xuehao,score, RANK() over(order by score desc) as r from scores_tb;
```
## 一条语句也可以查询出不同排名
```mysql
SELECT xuehao,score,
    ROW_NUMBER() OVER w AS 'row_r',
    DENSE_RANK() OVER w AS 'dense_r',
    RANK()       OVER w AS 'r'
FROM `scores_tb`
WINDOW w AS (ORDER BY `score` desc);
```
排名结果
```
+--------+-------+-------+---------+---+
| xuehao | score | row_r | dense_r | r |
+--------+-------+-------+---------+---+
|   1002 |    99 |     1 |       1 | 1 |
|   1003 |    96 |     2 |       2 | 2 |
|   1004 |    96 |     3 |       2 | 2 |
|   1008 |    94 |     4 |       3 | 4 |
|   1005 |    92 |     5 |       4 | 5 |
|   1006 |    90 |     6 |       5 | 6 |
|   1007 |    90 |     7 |       5 | 6 |
|   1001 |    89 |     8 |       6 | 8 |
+--------+-------+-------+---------+---+
```

## 总结： 

本文给出三种不同场景下实现统计排名的SQL，可以根据不同业务需求选取合适的排名方案。
对比MySQL8.0，发现利用窗口函数可以更轻松实现排名，其实业务需求远远比我们举的示例要复杂许多，
用SQL实现此类业务需求还是需要慢慢积累的。


[Mysql将查询后的数据进行排名的SQL语句](https://blog.csdn.net/wojiaowo11111/article/details/53350470)


