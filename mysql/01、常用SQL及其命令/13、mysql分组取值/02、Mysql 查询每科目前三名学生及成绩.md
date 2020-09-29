
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

先查询排名前 n 的总数

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
