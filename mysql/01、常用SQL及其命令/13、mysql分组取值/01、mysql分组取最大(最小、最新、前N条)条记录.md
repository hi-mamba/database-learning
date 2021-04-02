##### [原文](http://www.manongjc.com/article/1082.html)

# mysql分组取最大(最小、最新、前N条)条记录

先看一下本示例中需要使用到的数据

创建表并插入数据：
```mysql
create table tb(name varchar(10),val int,memo varchar(20))
insert into tb values('a',    2,   'a2')
insert into tb values('a',    1,   'a1')
insert into tb values('a',    3,   'a3')
insert into tb values('b',    1,   'b1')
insert into tb values('b',    3,   'b3')
insert into tb values('b',    2,   'b2')
insert into tb values('b',    4,   'b4')
insert into tb values('b',    5,   'b5')
```
数据表如下：
```
name	val	memo
a	2	a2
a	1	a1
a	3	a3
b	1	b1
b	3	b3
b	2	b2
b	4	b4
b	5	b5
```

## 按`name分组`取val最大的值所在行的数据

方法一：
>select a.* from tb a where val = (select max(val) from tb where name = a.name) order by a.name

方法二：
> select a.* from tb a where not exists(select 1 from tb where name = a.name and val > a.val)

方法三：
> select a.* from tb a,(select name,max(val) val from tb group by name) b where a.name = b.name and a.val = b.val order by a.name

方法四：
> select a.* from tb a inner join (select name , max(val) val from tb group by name) b on a.name = b.name and a.val = b.val order by

方法五：
> select a.* from tb a where 1 > (select count(*) from tb where name = a.name and val > a.val ) order by a.name

以上五种方法运行的结果均为如下所示：
```
name	val	memo
a	3	a3
b	5	b5
```
小编推荐使用第一、第三、第四钟方法,结果显示第1,3,4种方法效率相同，第2，5种方法效率差些。

按n`ame分组`取val最小的值所在行的数据

方法一：
> select a.* from tb a where val = (select min(val) from tb where name = a.name) order by a.name

方法二：
> select a.* from tb a where not exists(select 1 from tb where name = a.name and val < a.val)

方法三：
> select a.* from tb a,(select name,min(val) val from tb group by name) b where a.name = b.name and a.val = b.val order by a.name

方法四：
> select a.* from tb a inner join (select name , min(val) val from tb group by name) b on a.name = b.name and a.val = b.val order by a.name

方法五：
> select a.* from tb a where 1 > (select count(*) from tb where name = a.name and val < a.val) order by a.name

以上五种方法运行的结果均为如下所示：
```
name	val	memo
a	1	a1
b	1	b1
```

## 按name分组取第一次出现的行所在的数据 
sql如下：

> select a.* from tb a where val = (select top 1 val from tb where name = a.name) order by a.name

结果如下：
```
name	val	memo
a	2	a2
b	1	b1
``` 

## 按name分组随机取一条数据
sql如下：

> select a.* from tb a where val = (select top 1 val from tb where name = a.name order by newid()) order by a.name

结果如下：
```
name	val	memo
a	1	a1
b	3	b3
```

## 按`name分组`取最小的两个(N个)val
第一种方法：
> select a.* from tb a where 2 > (select count(*) from tb where name = a.name and val < a.val ) order by a.name,a.val

第二种方法：
> select a.* from tb a where val in (select top 2 val from tb where name=a.name order by val) order by a.name,a.val

第三种方法：
> select a.* from tb a where exists (select count(*) from tb where name = a.name and val < a.val having Count(*) < 2) order by a.name

结果如下：
```
name	val	memo
a	1	a1
a	2	a2
b	1	b1
b	2	b2
```

## 按name分组取最大的两个(N个)val
第一种方法：
> select a.* from tb a where 2 > (select count(*) from tb where name = a.name and val > a.val ) order by a.name,a.val

第二种方法：
> select a.* from tb a where val in (select top 2 val from tb where name=a.name order by val desc) order by a.name,a.val

第三种方法：
> select a.* from tb a where exists (select count(*) from tb where name = a.name and val > a.val having Count(*) < 2) order by a.name

结果如下：
```
name	val	memo
a	3	a3
a	2	a2
b	5	b5
b	4	b4
```