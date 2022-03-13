

# redis 中文网系列文章

[点击我查看文章](http://redis.cn/topics/)



## redis 是单线程架构吗？

redis 主进程执行是 `单线程` 处理命令

redis fork 字进程处理其他

redis6.0 网络io 是一个`多线程`
> 网络请求，请求的解析是一个多线程，但是对于 （队列）


## redis hash 表会装满吗？装满怎么办

- 哈希表工作机制
> 链式hash，当链式hash 到底阈值 进行rehash

- rehash过程
- 潜在影响


## redis 性能突然变慢了有什么好办法？

> 潜在的性能阻塞点

- aop 重写
- 执行O(n)的命令方法


- cpu 过载
> 使用 keys  的命令,集合操作

- 内存问题
> 访问大量内存，或者删除大量的key,

- 网络io (网卡打满 bigkey 的问题)
- 
