
## Redis删除大Key

> 这里说的大key是指包含很多元素的set,sorted set,list和hash。

删除操作，我们一般想到有2种，del和expire。


## DEL

如果要删除的key是一个集合，包含了很多元素，那么DEL时的耗时和元素个数成正比，所以如果直接DEL，会很慢。

## EXPIRE

想着expire会不会可以不是直接删除，可惜官网的描述让我心灰意冷，如果expire后指定的timeout不是正数，也就是<=0，那其实就是DEL。



## 一点一点删

我们知道Redis的工作线程是单线程的，如果一个command堵塞了，那所有请求都会超时，这时候，一些骚操作也许可以帮助你。

其实如果想删除key，可以分解成2个目的，1：不想让其他人访问到这个key，2：释放空间。

那其实我们可以分解成两步，先用RENAME把原先的key rename成另一个key，比如：
```bash
RENAME userInfo:123 "deleteKey:userInfo:123"
```

然后可以慢慢去删”deleteKey:userInfo:123”，如果是set，那么可以用SREM慢慢删，最后再用DEL彻底删掉。

>这里可以搞个task去SCAN deleteKey:*，然后慢慢删除。

## [UNLINK](../02、redis命令/30、UNLINK.md)

Redis 4.0.0提供了一个更加方便的命令
```
Available since 4.0.0.

Time complexity: O(1) for each key removed regardless of its size. 
Then the command does O(N) work in a different thread in order to reclaim memory, 
where N is the number of allocations the deleted objects where composed of.

```
UNLINK其实是直接返回，然后在后台线程慢慢删除。

如果你的Redis版本>=4.0.0，那么强烈建议使用UNLINK来删除。

UNLINK 删除指定的key(s),若key不存在则该key被跳过。但是，相比DEL会产生阻塞，
该命令会在另一个线程中回收内存，因此它是非阻塞的。 

## [redis-4.0 非阻塞删除](http://www.hulkdev.com/posts/redis-async-del)

对于 Redis 这种单线程模型的服务来说，一些耗时的命令阻塞其他请求是个头痛的问题。典型的命令如 KEYS/FLUSHALL/FLUSHDB 等等，
一般线上也会禁用这些会遍历整个库的命令。而像 DEL/LRANGE/HGETALL 这些可能导致阻塞的命令经常被工程师忽视，
这些命令在 value 比较大的时候跟 KEYS 这些并没有本质区别。

Redis 4.0 开始针对 DEL/FLUSHALL/FLUSHDB 做了一些优化。

## 1) DEL/FLUSHALL/FLUSHDB 异步化

FLUSHALL/FLUSHDB 清除库的时候因为要对每个 kv 进行遍历会比较耗时。同理对于 DEL 命令也是，如 VALUE 是链表，集合或者字典，
同样要遍历删除。在 Redis 4.0 针对这三个命令引入了异步化处理，避免阻塞其他请求。FLUSHALL/FLUSHDB 加了一个 ASYNC 参数，
同时新增 UNLINK 来表示异步化的删除命令。

为什么 DEL 也不使用类似 FLUSHALL/FLUSHDB 命令加个参数的方式？

调皮的作者是这么说的:

> There are reasons why UNLINK is not the default for DEL. I know things… I can’t talk (**).

意思大概就是: 「原因我知道但不告诉你...」

不过我猜主要原因是因为 DEL 命令是支持不定参数，如果加个 ASYNC 参数没办法判断到底这个是 key 还是异步删除的选项。

