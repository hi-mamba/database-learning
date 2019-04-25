## [原文](https://blog.csdn.net/zhu_xun/article/details/16806285)

# redis中各种数据类型对应的jedis操作命令

## 一、常用数据类型简介：

      redis常用五种数据类型:string,hash,list,set,zset(sorted set).

### 1. String类型
```
String是最简单的类型，一个key对应一个value

String类型的数据最大1G。
String类型的值可以被视作integer，从而可以让“INCR”命令族操作(incrby、decr、decrby),这种情况下，该integer的值限制在64位有符号数。
在list、set和zset中包含的独立的元素类型都是Redis String类型。
```

### 2. List类型
```
链表类型，主要功能是push、pop、获取一个范围的所有值等。其中的key可以理解为链表的名字。

在Redis中，list就是Redis String的列表，按照插入顺序排序。比如使用LPUSH命令在list头插入一个元素，使用RPUSH命令在list的尾插入一个元素。
当这两个命令之一作用于一个空的key时，一个新的list就创建出来了。

List的最大长度是2^32-1个元素。
```
### 3. Set类型
```
集合，和数学中的集合概念相似。操作中的key理解为集合的名字。

在Redis中，set就是Redis String的无序集合，不允许有重复元素。

Set的最大元素数是2^32-1。

Redis中对set的操作还有交集、并集、差集等。
```
### 4. ZSet(Sorted Set)类型
```
Zset是set的一个升级版本，在set的基础上增加了一个顺序属性，这一属性在添加修改元素时可以指定，
每次指定后zset会自动安装指定值重新调整顺序。可以理解为一张表，一列存value，一列存顺序。操作中的key理解为zset的名字。

Zset的最大元素数是2^32-1。

对于已经有序的zset，仍然可以使用SORT命令，通过指定ASC|DESC参数对其进行排序。
```
### 5. hash类型
```
hash是最接近关系数据库结构的数据类型，可以将数据库一条记录或程序中一个对象转换成hashmap存放在redis中。
```

## 二、jedis操作命令：

1.对value操作的命令

     exists(key)：确认一个key是否存在

     del(key)：删除一个key

     type(key)：返回值的类型

     keys(pattern)：返回满足给定pattern的所有key

     randomkey：随机返回key空间的一个key

     rename(oldname, newname)：将key由oldname重命名为newname，若newname存在则删除newname表示的key

     dbsize：返回当前数据库中key的数目

     expire：设定一个key的活动时间（s）

     ttl：获得一个key的活动时间

     select(index)：按索引查询

     move(key, dbindex)：将当前数据库中的key转移到有dbindex索引的数据库

     flushdb：删除当前选择数据库中的所有key

     flushall：删除所有数据库中的所有key

<https://redis.io/commands#generic>

2.对String操作的命令

     set(key, value)：给数据库中名称为key的string赋予值value

     get(key)：返回数据库中名称为key的string的value

     getset(key, value)：给名称为key的string赋予上一次的value

     mget(key1, key2,…, key N)：返回库中多个string（它们的名称为key1，key2…）的value

     setnx(key, value)：如果不存在名称为key的string，则向库中添加string，名称为key，值为value

     setex(key, time, value)：向库中添加string（名称为key，值为value）同时，设定过期时间time

     mset(key1, value1, key2, value2,…key N, value N)：同时给多个string赋值，名称为key i的string赋值value i

     msetnx(key1, value1, key2, value2,…key N, value N)：如果所有名称为key i的string都不存在，则向库中添加string，名称key i赋值为value i

     incr(key)：名称为key的string增1操作

     incrby(key, integer)：名称为key的string增加integer

     decr(key)：名称为key的string减1操作

     decrby(key, integer)：名称为key的string减少integer

     append(key, value)：名称为key的string的值附加value

     substr(key, start, end)：返回名称为key的string的value的子串

<https://redis.io/commands#string>

3.对List操作的命令

     rpush(key, value)：在名称为key的list尾添加一个值为value的元素

     lpush(key, value)：在名称为key的list头添加一个值为value的 元素

     llen(key)：返回名称为key的list的长度

     lrange(key, start, end)：返回名称为key的list中start至end之间的元素（下标从0开始，下同）

     ltrim(key, start, end)：截取名称为key的list，保留start至end之间的元素

     lindex(key, index)：返回名称为key的list中index位置的元素

     lset(key, index, value)：给名称为key的list中index位置的元素赋值为value

     lrem(key, count, value)：删除count个名称为key的list中值为value的元素。count为0，删除所有值为value的元素，
count>0 从头至尾删除count个值为value的元素，count<0从尾到头删除|count|个值为value的元素。

     lpop(key)：返回并删除名称为key的list中的首元素

     rpop(key)：返回并删除名称为key的list中的尾元素

     blpop(key1, key2,… key N, timeout)：lpop命令的block版本。即当timeout为0时，若遇到名称为key i的list不存在或该list为空，
则命令结束。如果timeout>0，则遇到上述情况时，等待timeout秒，如果问题没有解决，则对key i+1开始的list执行pop操作。

     brpop(key1, key2,… key N, timeout)：rpop的block版本。参考上一命令。

     rpoplpush(srckey, dstkey)：返回并删除名称为srckey的list的尾元素，并将该元素添加到名称为dstkey的list的头部

<https://redis.io/commands#list>

4.对Set操作的命令

     sadd(key, member)：向名称为key的set中添加元素member

     srem(key, member) ：删除名称为key的set中的元素member

     spop(key) ：随机返回并删除名称为key的set中一个元素

     smove(srckey, dstkey, member) ：将member元素从名称为srckey的集合移到名称为dstkey的集合

     scard(key) ：返回名称为key的set的基数

     sismember(key, member) ：测试member是否是名称为key的set的元素

     sinter(key1, key2,…key N) ：求交集

     sinterstore(dstkey, key1, key2,…key N) ：求交集并将交集保存到dstkey的集合

     sunion(key1, key2,…key N) ：求并集

     sunionstore(dstkey, key1, key2,…key N) ：求并集并将并集保存到dstkey的集合

     sdiff(key1, key2,…key N) ：求差集

     sdiffstore(dstkey, key1, key2,…key N) ：求差集并将差集保存到dstkey的集合

     smembers(key) ：返回名称为key的set的所有元素

     srandmember(key) ：随机返回名称为key的set的一个元素

<https://redis.io/commands#set>

5.对zset（sorted set）操作的命令

     zadd(key, score, member)：向名称为key的zset中添加元素member，score用于排序。如果该元素已经存在，则根据score更新该元素的顺序。

     zrem(key, member) ：删除名称为key的zset中的元素member

     zincrby(key, increment, member) ：如果在名称为key的zset中已经存在元素member，则该元素的score增加increment；否则向集合中添加该元素，其score的值为increment

     zrank(key, member) ：返回名称为key的zset（元素已按score从小到大排序）中member元素的rank（即index，从0开始），若没有member元素，返回“nil”

     zrevrank(key, member) ：返回名称为key的zset（元素已按score从大到小排序）中member元素的rank（即index，从0开始），若没有member元素，返回“nil”

     zrange(key, start, end)：返回名称为key的zset（元素已按score从小到大排序）中的index从start到end的所有元素

     zrevrange(key, start, end)：返回名称为key的zset（元素已按score从大到小排序）中的index从start到end的所有元素

     zrangebyscore(key, min, max)：返回名称为key的zset中score >= min且score <= max的所有元素

     zcard(key)：返回名称为key的zset的基数

     zscore(key, element)：返回名称为key的zset中元素element的score

     zremrangebyrank(key, min, max)：删除名称为key的zset中rank >= min且rank <= max的所有元素

     zremrangebyscore(key, min, max) ：删除名称为key的zset中score >= min且score <= max的所有元素

     zunionstore / zinterstore(dstkeyN, key1,…,keyN, WEIGHTS w1,…wN, AGGREGATE SUM|MIN|MAX)：对N个zset求并集和交集，
并将最后的集合保存在dstkeyN中。对于集合中每一个元素的score，在进行AGGREGATE运算前，都要乘以对于的WEIGHT参数。
如果没有提供WEIGHT，默认为1。默认的AGGREGATE是SUM，即结果集合中元素的score是所有集合对应元素进行SUM运算的值，
而MIN和MAX是指，结果集合中元素的score是所有集合对应元素中最小值和最大值。

<https://redis.io/commands#sorted_set>

6.对Hash操作的命令

     hset(key, field, value)：向名称为key的hash中添加元素field<—>value

     hget(key, field)：返回名称为key的hash中field对应的value

     hmget(key, field1, …,field N)：返回名称为key的hash中field i对应的value

     hmset(key, field1, value1,…,field N, value N)：向名称为key的hash中添加元素field i<—>value i

     hincrby(key, field, integer)：将名称为key的hash中field的value增加integer

     hexists(key, field)：名称为key的hash中是否存在键为field的域

     hdel(key, field)：删除名称为key的hash中键为field的域

     hlen(key)：返回名称为key的hash中元素个数

     hkeys(key)：返回名称为key的hash中所有键

     hvals(key)：返回名称为key的hash中所有键对应的value

     hgetall(key)：返回名称为key的hash中所有的键（field）及其对应的value

<https://redis.io/commands#hash>

## 三、各种数据类型所对应的应用场景

1.String类型的应用场景

   String是最常用的一种数据类型,普通的key/value存储.

2.list类型的应用场景

   比较适用于列表式存储且顺序相对比较固定，例如：

省份、城市列表

品牌、厂商、车系、车型等列表

拆车坊专题列表...

3.set类型的应用场景

   Set对外提供的功能与list类似,当需要存储一个列表数据,又不希望出现重复数据时,可选用set

4.zset(sorted set)类型的应用场景

zset的使用场景与set类似,区别是set不是自动有序的,而zset可以通过用户额外提供一个优先级(score)的参数来为成员排序,并且是插入有序的,
即自动排序.当你需要一个有序的并且不重复的集合列表,那么可以选择zset数据结构。例如:

根据PV排序的热门车系车型列表

根据时间排序的新闻列表

5.hash类型的应用场景

类似于表记录的存储

页面视图所需数据的存储


