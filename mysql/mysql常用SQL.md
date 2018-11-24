

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


## 查询出来多列合成一列，且换行

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
 