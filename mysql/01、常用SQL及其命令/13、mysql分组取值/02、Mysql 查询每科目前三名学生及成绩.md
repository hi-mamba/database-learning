##### [Department Top Three Salaries](https://leetcode.com/problems/department-top-three-salaries/)

##### [Mysql 查询每科目前两名学生及成绩](https://blog.csdn.net/xw791488540/article/details/88927441?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.channel_param&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.channel_param)

# Mysql 查询每科目前三名学生及成绩


```mysql
 CREATE TABLE student (person varchar(20) , subject_id int , score int);

INSERT INTO student VALUES('Bob',1,81);
INSERT INTO student VALUES('Jill',1,70);
INSERT INTO student VALUES('Shawn',1,72);
INSERT INTO student VALUES('Kobe',1,81);
INSERT INTO student VALUES('Mamba',1,100);

INSERT INTO student VALUES('Bob',2,29);
INSERT INTO student VALUES('Jill',2,66);
INSERT INTO student VALUES('Shawn',2,79);
INSERT INTO student VALUES('Kobe',2,82);
INSERT INTO student VALUES('Mamba',2,92);

```

## 解决方案

先查询排名前 3 的总数(3可以换成你先查询top n 的数)，

```mysql
	
SELECT
	*
FROM
	student s1
WHERE
	(
SELECT
	count( distinct score  )  -- 注意这里，如果相同分数排名一样只算一次的话这里需要去重
FROM
	student 
WHERE
	 s1.subject_id = subject_id
	AND  score > s1.score 
	) < 3 order by s1.subject_id asc, s1.score desc ;
	
```
