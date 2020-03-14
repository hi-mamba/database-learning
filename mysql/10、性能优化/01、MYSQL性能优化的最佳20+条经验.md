

## [原文](http://coolshell.cn/articles/1846.html)

# MYSQL性能优化的最佳20+条经验


今天，数据库的操作越来越成为整个应用的性能瓶颈了，这点对于Web应用尤其明显。
关于数据库的性能，这并不只是DBA才需要担心的事，而这更是我们程序员需要去关注的事情。
当我们去设计数据库表结构，对操作数据库时（尤其是查表时的SQL语句），我们都需要注意数据操作的性能。
这里，我们不会讲过多的SQL语句的优化，而只是针对MySQL这一Web应用最多的数据库。希望下面的这些优化技巧对你有用。

## 1. 为查询缓存优化你的查询
大多数的MySQL服务器都开启了查询缓存。这是提高性最有效的方法之一，而且这是被MySQL的数据库引擎处理的。
当有很多相同的查询被执行了多次的时候，这些查询结果会被放到一个缓存中，这样，后续的相同的查询就不用操作表而直接访问缓存结果了。

这里最主要的问题是，对于程序员来说，这个事情是很容易被忽略的。因为，我们某些查询语句会让MySQL不使用缓存。请看下面的示例：
 
 ```mysql
// 查询缓存不开启
$r = mysql_query("SELECT username FROM user WHERE signup_date >= CURDATE()");
 ```
// 开启查询缓存
$today = date("Y-m-d");
$r = mysql_query("SELECT username FROM user WHERE signup_date >= '$today'");
上面两条SQL语句的差别就是 CURDATE() ，MySQL的查询缓存对这个函数不起作用。所以，像 NOW() 
和 RAND() 或是其它的诸如此类的SQL函数都不会开启查询缓存，因为这些函数的返回是会不定的易变的。
所以，你所需要的就是用一个变量来代替MySQL的函数，从而开启缓存。


## 2. EXPLAIN 你的 SELECT 查询

## 3. 当只要一行数据时使用 LIMIT 1

## 4. 为搜索字段建索引

## 5. 在Join表的时候使用相当类型的例，并将其索引

## 6. 千万不要 ORDER BY RAND()

## 7. 避免 SELECT *

## 8. 永远为每张表设置一个ID

## 9. 使用 ENUM 而不是 VARCHAR

## 10. 从 PROCEDURE ANALYSE() 取得建议

## 11. 尽可能的使用 NOT NULL

## 12. Prepared Statements

## 13. 无缓冲的查询

## 14. 把IP地址存成 UNSIGNED INT


## 15. 固定长度的表会更快


## 16. 垂直分割

## 17. 拆分大的 DELETE 或 INSERT 语句

## 18. 越小的列会越快

## 19. 选择正确的存储引擎

## 20. 使用一个对象关系映射器（Object Relational Mapper）

## 21. 小心“永久链接”

