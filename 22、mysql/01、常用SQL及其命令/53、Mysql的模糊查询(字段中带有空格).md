<https://blog.csdn.net/ll594317566/article/details/90747412>

# Mysql的模糊查询(字段中带有空格)

```mysql
select * from table_name where trim(replace(name,' ','')) like concat('%',#{name},'%')
```
mybatis

![image](https://user-images.githubusercontent.com/7867225/141121999-f1ec84d4-f403-4212-a57d-d163b1d500df.png)
