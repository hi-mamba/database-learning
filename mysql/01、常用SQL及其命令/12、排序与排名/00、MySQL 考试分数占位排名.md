原文：<https://renwei.vip/?p=713>

# MySQL 考试分数占位排名

## 并列排名

```sql
SELECT
    obj.student_id,
    obj.total_score,
    CASE
WHEN @rowtotal = obj.total_score THEN
    @rownum
WHEN @rowtotal := obj.total_score THEN
    @rownum :=@rownum + 1
WHEN @rowtotal = 0 THEN
    @rownum :=@rownum + 1
END AS rownum
FROM
    (
        SELECT
            student_id,
            total_score
        FROM
            `qy_exam_student`
                WHERE
                      `exam_id` = 376
        ORDER BY
            total_score DESC
    ) AS obj,
    (SELECT @rownum := 0 ,@rowtotal := NULL) r
```


## 并列占位排名

分数一样排名就一样，但是排名会占用, （1,2,2,4,5,5,7.....）


```mysql
SELECT
    obj_new.student_id,
    obj_new.total_score,
    obj_new.rownum
FROM
    (
        SELECT
            obj.student_id,
            obj.total_score,
            @rownum := @rownum + 1 AS num_tmp,
            @incrnum := CASE
        WHEN @rowtotal = obj.total_score THEN
            @incrnum
        WHEN @rowtotal := obj.total_score THEN
            @rownum
            WHEN @rowtotal = 0 THEN //解决值为0 没有排名的问题
            @rownum :=@rownum + 1
        END AS rownum
        FROM
            (
                SELECT
                    student_id,
                    total_score
                FROM
                    `qy_exam_student`
                                WHERE
                                        `exam_id` = 376
                ORDER BY
                    total_score DESC
            ) AS obj,
            (
                SELECT
                    @rownum := 0 ,@rowtotal := NULL ,@incrnum := 0
            ) r
    ) AS obj_new

```
![image](https://user-images.githubusercontent.com/7867225/133801992-9186e8b8-216c-4bff-8d54-d2520980c050.png)


图片示例 可以看到是返回null 如果不想返回null 可以吧方案二的 WHEN @rowtotal = 0 THEN @rownum :=@rownum + 1 加上,
但是不建议这么做,null数据建议在业务层判断一下,获取考试的总人数(这样0分的同学就是最后一名了 哈哈)


如果要获取指定用户的排名可以在最后加上 WHERE student_id = xx 就可以获取到了.
