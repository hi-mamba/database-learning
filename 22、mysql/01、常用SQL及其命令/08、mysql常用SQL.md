

# Mysql 常用SQL

## 查看数据库表大小，How to get the sizes of the tables of a MySQL database?

```mysql

SELECT 
     table_schema as `Database`, 
     table_name AS `Table`, 
     round(((data_length + index_length) / 1024 / 1024), 2) `Size in MB` 
FROM information_schema.TABLES  where  table_name IN ('mysql','表明') 
ORDER BY (data_length + index_length) DESC;

```


## 查询出来多列合成一列，且换行,concat() mysql 多个字段拼接

[参考](https://www.cnblogs.com/duanxz/p/5098875.html)

```mysql
 SELECT
    CONCAT(
    CONCAT( title, "&lt;/br&gt;" ),
     username
    )
    FROM table_name
```

##  MySQL统计一个列中不同值的数量

需求：
MySQL 统计一个列中不同值的数量，其中 origin 是用户来源，
其中的值有 iPhone 、Android 、Web 三种，现在需要分别统计由这三种渠道注册的用户数量。
 
- 解决方案1 
```mysql

SELECT count(*) 
FROM user_operation_log 
WHERE origin = 'iPhone'; 

SELECT count(*) 
FROM user_operation_log 
WHERE origin = 'Android'; 

SELECT count(*) 
FROM user_operation_log 
WHERE origin = 'Web'; 

```

用 where 语句分别统计各自的数量。 
这样查询的量有点多了，如果这个值有 10 个呢，那还得写 10 条相似的语句，很麻烦。 
有没有一条语句就搞定的呢？于是去查了些资料。 

- 解决方案2 

我们知道 count 不仅可以用来统计行数，也能统计列值的数量，例如： 
统计 user_operation_log 有多少行： 
SELECT count(*) FROM user_operation_log 
统计 origin 这列值不为 NULL 的数量： 
SELECT count(origin) FROM user_operation_log 
所以我们可以利用这个特性来实现上面的需求 
第一种写法（用 count 实现） 
```mysql

SELECT 
  count(origin = 'iPhone' OR NULL)  AS iPhone, 
  count(origin = 'Android' OR NULL) AS Android, 
  count(origin = 'Web' OR NULL)     AS Web 
FROM user_operation_log; 

```
查询结果 
search_result 
第二种写法（用 sum 实现） 

```mysql
SELECT 
  sum(if(origin = 'iPhone', 1, 0))  AS iPhone, 
  sum(if(origin = 'Android', 1, 0)) AS Android, 
  sum(if(origin = 'Web', 1, 0))     AS Web 
FROM user_operation_log; 

SELECT 
  sum(origin = 'iPhone')  AS iPhone, 
  sum(origin = 'Android') AS Android, 
  sum(origin = 'Web')     AS Web 
FROM user_operation_log; 

```
- 第4种，最优的： 


```mysql
SELECT origin,count(*) num FROM user_operation_log GROUP BY origin; 

```
 
 

## Sql合并两个select查询
[原文](http://www.cnblogs.com/jasondan/p/3490470.html)

> 现有2个查询，需要将每个查询的结果合并起来(注意不是合并结果集，
因此不能使用union）,可以将每个查询的结果作为临时表，
然后再从临时表中select所需的列，示例如下
```mysql
SELECT get.daytime, get.data as get, xh.data as xh 
        FROM ( 
                SELECT daytime, sum(get_sum) as data 
                FROM yuanbao_get 
                group by daytime 
                order by daytime 
        ) as get, 
        ( 
                SELECT daytime, sum(xh_sum) as data 
                FROM yuanbao_xh 
                group by daytime 
                order by daytime 
        ) as xh 
        where get.daytime = xh.daytime
``` 


## MySql格式化小数保留小数点后两位

- 方式一：
```mysql

SELECT FORMAT(12562.6655,2);

```
结果：12,562.67

```mysql
SELECT FORMAT(12332.1,4);

```
结果：12,332.1000（小数没有数字会补0）

查看文档：Formats the number X to a format like ‘#,###,###.##’, 
rounded to D decimal places, and returns the result as a string. If D is 0,
 the result has no decimal point or fractional part.整数部分超过三位的时候以逗号分割，
 并且返回的结果是string类型的。

- 方式二

```mysql
select truncate(4545.1366,2);

```
结果：结果：4545.13（直接截取，不会四舍五入）

- 方式三

```mysql
select convert(4545.1366,decimal(10,2));

```
结果：4545.14 

convert()函数会对小数部分进行四舍五入操作，decimal(10,2)：
它表示最终得到的结果整数部分位数加上小数部分位数小于等于10，小数部分位数2

- 方式四
round：返回数字表达式并四舍五入为指定的长度或精度。

> 语法：ROUND ( numeric_expression , length [ , function ] ) 

参数： 

> numeric_expression ：精确数字或近似数字数据类型类别的表达式（bit数据类型除外）。

length：是numeric_e-xpression 将要四舍五入的精度。
length必须是tinyint、smallint或int。当length为正数时，
numeric_e-xpression四舍五入为length所指定的小数位数。当length为负数时，numeric_e- 
xpression则按length所指定的在小数点的左边四舍五入。

function：是要执行的操作类型。function必须是tinyint、smallint或int。
如果省略function或function的值为0（默认），numeric_expression将四舍五入。
当指定0以外的值时，将截断numeric_expression。

返回类型：返回与numeric_e-xpression相同的类型。 
ROUND始终返回一个值。如果length是负数且大于小数点前的数字个数，ROUND将返回0。
 
示例

```mysql
select ROUND(748.58, -4)；

```
结果：0 

当length是负数时，无论什么数据类型，ROUND都将返回一个四舍五入的numeric_e-xpression。 

示例

```
ROUND(748.58, -1);
ROUND(748.58, -2);
ROUND(748.58, -3);

```
结果：

``` 
750 
700 
1000

```

```mysql
select ROUND(4545.1366,2); 

```
结果：4545.15

