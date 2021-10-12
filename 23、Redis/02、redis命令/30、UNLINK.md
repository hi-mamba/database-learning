## [原文](http://www.redis.cn/commands/unlink.html)

# UNLINK key [key ...]

> 非阻塞删除

```
起始版本：4.0.0

时间复杂度：O(1) for each key removed regardless of its size. 
Then the command does O(N) work in a different thread in order to reclaim memory, 
where N is the number of allocations the deleted objects where composed of.
```
该命令和DEL十分相似：删除指定的key(s),若key不存在则该key被跳过。但是，相比DEL会产生阻塞，
该命令会在另一个线程中回收内存，因此它是非阻塞的。 
这也是该命令名字的由来：仅将keys从keyspace元数据中删除，真正的删除会在后续异步操作。

## 返回值
integer-reply：unlink的keys的数量.

## 例子
```bash
redis> SET key1 "Hello"
"OK"
redis> SET key2 "World"
"OK"
redis> UNLINK key1 key2 key3
(integer) 2
redis> 

```

