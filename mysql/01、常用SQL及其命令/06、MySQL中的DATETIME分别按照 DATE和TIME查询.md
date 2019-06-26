

# [How to part DATE and TIME from DATETIME in MySQL](https://stackoverflow.com/questions/12337195/how-to-part-date-and-time-from-datetime-in-mysql)

# MySQL中的DATETIME分别按照 DATE和TIME查询

I am storing(存储) a DATETIME field in a Table. 
After Storing the value its come like 2012-09-09 06:57:12 .

For storing I am using the syntax:

> date("Y-m-d H:i:s");

Now My Question is, While Fetching the data, 
How can get both date and time separate, using the single MySQL query.

Date like 2012-09-09 and time like 06:57:12.

## 解决方案

You can achieve that using [DATE_FORMAT()](http://davidwalsh.name/format-date-mysql-date_format)
 (click the link for more other formats)
```mysql
SELECT DATE_FORMAT(colName, '%Y-%m-%d') DATEONLY, 
       DATE_FORMAT(colName,'%H:%i:%s') TIMEONLY
```
### [SQLFiddle Demo](http://sqlfiddle.com/#!2/d41d8/1842)