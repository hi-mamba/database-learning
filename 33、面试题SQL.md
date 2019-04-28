

# 面试题SQL

## 用一条sql语句查询出“每门”课程都大于80分的学生姓名

- 插入数据
```mysql
create table student (
  name varchar(20) not null, -- 姓名
  course varchar(20) not null,-- 科目
  score int ,-- 成绩
  bossEvaluate varchar(20),-- 校长评估
  familyEvaluate varchar(20),-- 家族评估
  societyEvaluate varchar(20), -- 社会评估
  primary key(name,course)
);
insert into student values('小王','数学','100','A','B','C');
insert into student values('小王','语文','100','A','B','C');
insert into student values('小王','英语','90','A','B','C');
insert into student values('小花','数学','90','A','A','A');
insert into student values('小花','语文','40','A','A','C');
insert into student values('小花','英语','10','A','B','C');
insert into student values('小虎','数学','25','C','B','C');
insert into student values('小虎','语文','10','A','C','C');

insert into student values('小小','数学','125','C','B','C');
insert into student values('小小','语文','110','A','C','C');
 

```

- 答案一

```mysql
select name  from  student GROUP BY name  having min(score) >80;
```

- 答案二
```mysql
select DISTINCT name from student where name not in  (select DISTINCT name from student where score< 80  )
```