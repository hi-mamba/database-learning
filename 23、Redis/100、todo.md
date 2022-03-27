

[《进大厂系列》系列-Redis常见面试题（带答案）](https://zhuanlan.zhihu.com/p/91539644)

[服务器---分布式锁原理](https://zhuanlan.zhihu.com/p/361020373)


[分布式锁注意点及其实现](https://segmentfault.com/a/1190000039833373)


[基于Redission实现分布式锁](https://www.jianshu.com/p/67f700fad8b3)


<https://jishuin.proginn.com/p/763bfbd336ca>

redis 6.0 中，多线程主要用于网络 I/O 阶段，
也就是接收命令和写回结果阶段，而在执行命令阶段，还是由单线程串行执行。
由于执行时还是串行，因此无需考虑并发安全问题。




## redis 为什么使用单进程、单线程也很快


1、基于内存的操作



2、使用了 I/O 多路复用模型，select、epoll 等，基于 reactor 模式开发了自己的网络事件处理器



3、单线程可以避免不必要的上下文切换和竞争条件，减少了这方面的性能消耗。



4、以上这三点是 redis 性能高的主要原因，其他的还有一些小优化，例如：对数据结构进行了优化，简单动态字符串、压缩列表等。
