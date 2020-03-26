
##### [原文](http://zhuzhuodong.com/tech/redis/how-redis-aof-save-expire-info)

# Redis AOF模式如何保存过期信息

在学习Redis时，了解到持久化数据Redis有RDB、AOF两种模式，AOF是通过存储客户端的命令来实现的，
在没有看AOF文件之前，对于缓存时间的保存存有疑问，例如以下命令：
```shell script
set testkey testvalue
expire testkey 60
```
很容易理解，设置一个测试kv，并且设置60秒后过期，但是这个时候就在想，如果AOF文件缓存的也是这两个命令，
那重新加载AOF文件后，过期时间等于被重新设置，就不对了。


于是就测试了下，最终生成的AOF文件内容如下：
```shell script
*2
$6
SELECT
$1
0
*3
$3
set
$7
testkey
$9
testvalue
*3
$9
PEXPIREAT
$7
testkey
$13
1490954236652
```
最后我们可以看出来，其实对于过期命令，Redis做了特殊处理，最终保存的是PEXPIREAT，保存的是testkey的过期的时间节点。

另外在这里也说明下Redis对过期的处理，Redis设置过期时间有四个命令：expire、expireat、pexpire、pexpireat，这四个命令的用法如下：

- expire [缓存有效期，秒]：例如expire 60代表有效期是60s
- expireat [有效截止时间unixTime，秒数]：例如 expire 1490954500代表2017-03-31 18:01:40过期
- expire [缓存有效期，毫秒]：例如expire 60000代表有效期是60s
- pexpireat [有效截止时间毫秒数，毫秒数]：例如 expire 1490954500000代表2017-03-31 18:01:40过期

但是无论执行哪个命令，对于Redis底层来说，**最终都是转换成`pexpireat`来实现的**，
也就是说实际保存的都是该key过期时间的毫秒数，这个和Redis本身的[`过期时间处理策略`](../30、原理知识点/51、Redis数据过期策略详解.md)有关。

因此，AOF模式时，除了正常命令原样保存外，对于设置过期时间，统一由pexpireat命令实现。