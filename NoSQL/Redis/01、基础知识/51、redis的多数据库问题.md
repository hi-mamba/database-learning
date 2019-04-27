

# redis的多数据库问题

## redis数据库

```
redis 的实例（instance） 等同于 mysql 的库（database）
redis 的库（database） 等同于 mysql 的表（table）
```

redis也是有数据库的,不过redis是提前创建好了

redis的数据库个数，在配置文件中设定死了，并且名称是不允许改的。
```xml
databases 16     //默认16个数据库
```

对于redis中默认有16个数据库,这16个数据库编号是0-15，如果没有切换数据库的话，默认是0号数据库.

- 名字是从0,1,2…15
- 在redis上所做的所有数据操作,都是默认在0号数据库上操作的

我们可以尝试对数据库进行操作
 
```bash
# telnet 127.0.0.1 6379  
Trying 127.0.0.1...  
Connected to 127.0.0.1.  
Escape character is '^]'.  
set test 123   //在0号数据库设置test为123  
+OK  
select 1  //切换到1号数据库  
+OK  
set test 456   //设置test为456  
+OK  
get test  //1号数据库test为456  
$3  
456  
select 0  //切换到0号数据库  
+OK  
get test  //test为123  
$3  
123  

```
> 数据库间相同的key,相互不受影响。


FLUSHALL 是一个非常有破坏力的命令，因为它会清掉所有库中的数据
```bash
127.0.0.1:6379[10]> get a
"test"
127.0.0.1:6379[10]> select 11
OK
127.0.0.1:6379[11]> get a
"in11"
127.0.0.1:6379[11]> FLUSHALL
OK
127.0.0.1:6379[11]> get a
(nil)
127.0.0.1:6379[11]> select 10
OK
127.0.0.1:6379[10]> get a
(nil)
127.0.0.1:6379[10]>

```
显然这说明了一个问题,据库和数据库之间,不能共享键值对,可以把一个数据库理解成一个map集合