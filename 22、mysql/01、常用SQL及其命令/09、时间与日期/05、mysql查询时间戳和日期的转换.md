## [参考](https://blog.csdn.net/xiaobing_blog/article/details/12998555)

# mysql查询时间戳和日期的转换

 
## mysql 提供两个函数做时间戳和日期转换:
- 将时间戳转换为日期
```mysql
from_unixtime(time_stamp)     
```

- 将指定的日期或者日期字符串转换为时间戳
```mysql
unix_timestamp(date)  
```
 
```mysql
mysql> select from_unixtime(1574524800);
+---------------------------+
| from_unixtime(1574524800) |
+---------------------------+
| 2019-11-24 00:00:00       |
+---------------------------+
1 row in set (0.00 sec)
```
如: unix_timestamp(date) 
```mysql
mysql> select unix_timestamp(date('2019-11-24'));
+------------------------------------+
| unix_timestamp(date('2019-11-24')) |
+------------------------------------+
|                         1574524800 |
+------------------------------------+
1 row in set (0.00 sec)
```
 