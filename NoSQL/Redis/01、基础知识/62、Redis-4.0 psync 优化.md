

# [Redis-4.0 psync 优化](http://www.hulkdev.com/posts/redis_new_psync)

redis 4.0 一个比较大的改动就是 psync 优化, 本篇会介绍这个优化的部分。

在 2.8 版本之前 redis 没有增量同步的功能，主从只要重连就必须全量同步数据。
如果实例数据量比较大的情况下，网络轻轻一抖就会把主从的网卡跑满从而影响正常服务，这是一个蛋疼的问题。
2.8 为了解决这个问题引入了 psync (partial sync)功能，顾名思义就是增量同步。

