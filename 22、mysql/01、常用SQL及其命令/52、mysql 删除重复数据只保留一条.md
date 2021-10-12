## [参考](http://www.mysqltutorial.org/mysql-delete-duplicate-rows/)

# mysql 删除重复数据 只保留一条


```mysql
DELETE t1 FROM contacts t1
INNER JOIN contacts t2 
WHERE 
    t1.id < t2.id AND 
    t1.email = t2.email;
```

## 查询重复数据 
```mysql
 select min(id),user_name,count(user_name) from  user 
 group by user_name having count(user_name) > 1 order by   count(user_name) desc ;
```
