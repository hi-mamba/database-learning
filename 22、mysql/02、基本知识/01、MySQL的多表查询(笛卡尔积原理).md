### [原文](https://www.cnblogs.com/toolo/p/3634563.html)

# MySQL的多表查询(笛卡尔积原理)
  
先确定数据要用到哪些表。
将多个表先通过笛卡尔积变成一个表。
然后去除不符合逻辑的数据（根据两个表的关系去掉）。
最后当做是一个虚拟表一样来加上条件即可。
 

注意：列名最好使用表别名来区别。

![image](https://user-images.githubusercontent.com/7867225/137567975-497beb00-d181-4580-85f4-cf34c7f9b1cc.png)

例子：

![image](https://user-images.githubusercontent.com/7867225/137568009-635969ba-8395-4d01-8d81-cdd0314f1216.png)


![image](https://user-images.githubusercontent.com/7867225/137568043-dd299118-fa0d-4211-8803-d75aa199ca1f.png)
