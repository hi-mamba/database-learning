
## [原文](https://www.cnblogs.com/cuisi/p/7685893.html)

# mysql left join中where和on条件的区别

join过程可以这样理解：首先两个表做一个笛卡尔积，on后面的条件是对这个笛卡尔积做一个过滤形成一张临时表，
如果没有where就直接返回结果，如果有where就对上一步的临时表再进行过滤

## left join中关于where和on条件的几个知识点：   
1. 多表left join是会生成一张临时表，并返回给用户
    
2. where条件是针对最后生成的这张临时表进行过滤，过滤掉不符合where条件的记录，是真正的不符合就过滤掉。
    
3. on条件是对left join的右表进行条件过滤，但依然返回左表的所有行，右表中没有的补为NULL
    
4. on条件中如果有对左表的限制条件，无论条件真假，依然返回左表的所有行,但是会影响右表的匹配值。也就是说on中左表的限制条件只影响右表的匹配内容，不影响返回行数。

## 结论：
    1. where条件中对左表限制，不能放到on后面   
    2. where条件中对右表限制，放到on后面，会有数据行数差异，比原来行数要多
 
## 测试：
创建两张表：
```mysql
CREATE TABLE t1(id INT,name VARCHAR(20));
insert  into `t1`(`id`,`name`) values (1,'a11');
insert  into `t1`(`id`,`name`) values (2,'a22');
insert  into `t1`(`id`,`name`) values (3,'a33');
insert  into `t1`(`id`,`name`) values (4,'a44');
 
CREATE TABLE t2(id INT,local VARCHAR(20));
insert  into `t2`(`id`,`local`) values (1,'beijing');
insert  into `t2`(`id`,`local`) values (2,'shanghai');
insert  into `t2`(`id`,`local`) values (5,'chongqing');
insert  into `t2`(`id`,`local`) values (6,'tianjin');
```
#### 测试01：返回左表所有行，右表符合on条件的原样匹配，不满足条件的补NULL
```mysql
root@localhost:cuigl 11:04:25 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id;
+------+------+----------+
| id   | name | local    |
+------+------+----------+
|    1 | a11  | beijing  |
|    2 | a22  | shanghai |
|    3 | a33  | NULL     |
|    4 | a44  | NULL     |
+------+------+----------+
4 rows in set (0.00 sec)
```

#### 测试02：on后面增加对右表的限制条件：t2.local='beijing'    
结论02：左表记录全部返回，右表筛选条件生效
```mysql
root@localhost:cuigl 11:19:42 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id and t2.local='beijing';
+------+------+---------+
| id   | name | local   |
+------+------+---------+
|    1 | a11  | beijing |
|    2 | a22  | NULL    |
|    3 | a33  | NULL    |
|    4 | a44  | NULL    |
+------+------+---------+
4 rows in set (0.00 sec)
```
 
#### 测试03：只在where后面增加对右表的限制条件：t2.local='beijing'    
结论03：针对右表，相同条件，在where后面是对最后的临时表进行记录筛选，行数可能会减少；在on后面是作为匹配条件进行筛选，筛选的是右表的内容。

```mysql
root@localhost:cuigl 11:20:07 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id where t2.local='beijing';  
+------+------+---------+
| id   | name | local   |
+------+------+---------+
|    1 | a11  | beijing |
+------+------+---------+
1 row in set (0.01 sec)
```

#### 测试04：t1.name='a11' 或者 t1.name='a33'    
结论04：on中对左表的限制条件，不影响返回的行数，只影响右表的匹配内容
```mysql
root@localhost:cuigl 11:24:46 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id and t1.name='a11'; 
+------+------+---------+
| id   | name | local   |
+------+------+---------+
|    1 | a11  | beijing |
|    2 | a22  | NULL    |
|    3 | a33  | NULL    |
|    4 | a44  | NULL    |
+------+------+---------+
4 rows in set (0.00 sec)
root@localhost:cuigl 11:25:04 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id and t1.name='a33';
+------+------+-------+
| id   | name | local |
+------+------+-------+
|    1 | a11  | NULL  |
|    2 | a22  | NULL  |
|    3 | a33  | NULL  |
|    4 | a44  | NULL  |
+------+------+-------+
4 rows in set (0.00 sec)
```

#### 测试05：where t1.name='a33' 或者 where t1.name='a22'    
结论05：where条件是在最后临时表的基础上进行筛选，显示只符合最后where条件的行
```mysql
root@localhost:cuigl 11:25:15 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id where t1.name='a33';  
+------+------+-------+
| id   | name | local |
+------+------+-------+
|    3 | a33  | NULL  |
+------+------+-------+
1 row in set (0.00 sec)
root@localhost:cuigl 11:27:27 >SELECT t1.id,t1.name,t2.local FROM t1 LEFT JOIN t2 ON t1.id=t2.id where t1.name='a22';
+------+------+----------+
| id   | name | local    |
+------+------+----------+
|    2 | a22  | shanghai |
+------+------+----------+
1 row in set (0.00 sec)

```



