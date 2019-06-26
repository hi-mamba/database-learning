## [原文](https://www.cnblogs.com/nsw2018/p/6525711.html)

# MySQL模糊查询使用INSTR替代LIKE

instr函数，第一个参数是字段，第二个参数是要查询的串，返回串的位置，第一个是1，如果没找到就是0.

实例：
```sql
SELECT
     o.name
FROM
	user o
WHERE
	INSTR(o.name,'数据')>0
```  
 查找用户名称中包含主任的用户，作用类似于like ‘%数据%’
