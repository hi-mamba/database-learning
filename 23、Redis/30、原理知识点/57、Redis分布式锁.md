
## [原文](http://redis.cn/topics/distlock)

## [原文2](https://crossoverjie.top/2018/03/29/distributed-lock/distributed-lock-redis/)

### [原文3](https://tech.meituan.com/2016/09/29/distributed-system-mutually-exclusive-idempotence-cerberus-gtis.html)

# Redis分布式锁

因此业界常用的解决方案通常是借助于一个第三方组件并利用它自身的排他性来达到多进程的互斥。如：

- 基于 DB 的唯一索引。
- 基于 ZK 的临时有序节点。
- 基于 `Redis 的 NX EX `参数或者 GETSET。

通过代码发现 Redis实现分布式锁 其实调用 命令 set 来实现的，只是参数包含来 NX 和PX

> NX: 意思是SET IF NOT EXIST，即`当key不存在时，我们进行set操作`；`若key已经存在，则不做任何操作`；  
> 
> PX: 意思是我们要给这个`key加一个过期的设置`，具体时间由第五个参数决定

```java
/** SetParams 包含了 NX PX 定义*/
public String set(final String key, final String value, final SetParams params) {}
``` 
该命令可以保证 NX EX 的原子性。

一定不要把两个命令(NX EX)分开执行，如果在 NX 之后程序出现问题就有可能产生死锁。

Redis的分布式缓存特性使其成为了分布式锁的一种基础实现。通过Redis中是否存在某个锁ID，则可以判断是否上锁。
为了保证判断锁是否存在的原子性，保证只有一个线程获取同一把锁，
Redis有`SETNX`（即SET if Not eXists）和`GETSET`（先写新值，返回旧值，原子性操作，可以用于分辨是不是首次操作）操作。

为了防止主机宕机或网络断开之后的死锁，Redis没有ZK那种天然的实现方式，只能`依赖设置超时时间来规避`。


以下是一种比较普遍但不太完善的Redis分布式锁的实现步骤（与下图一一对应）：  
1. 线程A发送SETNX lock.orderid 尝试获得锁，如果`锁不存在，则set并获得锁`。   
2. 如果锁存在，则`再判断锁的值（时间戳）是否大于当前时间`，如果没有超时，则等待一下再重试。   
3. 如果已经超时了，在用GETSET lock.{orderid} 来尝试获取锁，如果这时候拿到的时间戳仍旧超时，则说明已经获得锁了。   
4. 如果在此之前，另一个线程C快一步执行了上面的操作，那么A拿到的时间戳是个未超时的值，这时A没有如期获得锁，需要再次等待或重试。 

该实现还有一个需要考虑的问题是`全局时钟问题`，由于生产环境主机时钟不能保证完全同步，对时间戳的判断也可能会产生误差。

以上是Redis的一种常见的实现方式，除此以外还可以用SETNX+EXPIRE来实现。
Redisson是一个官方推荐的Redis客户端并且实现了很多分布式的功能。
它的分布式锁就提供了一种更完善的解决方案，源码：<https://github.com/mrniko/redisson>