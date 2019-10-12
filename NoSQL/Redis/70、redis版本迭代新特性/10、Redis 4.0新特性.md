## [ 【原文】Redis-4.0](http://www.hulkdev.com/posts/redis-module)

# [Redis 4.0新特性](http://antirez.com/news/110)

直到今天为止 (2017-01-17) Redis 4.0 已经发布了两个 rc 版本, 相比于上个版本(3.2)，
这个版本的改动应该说是巨大的。主要有以下几个点:

- 增加了模块的功能, 用户可以自己扩展命令和数据结构

- [psync 优化，避免主从切换过程需要重新全量同步](../03、基础知识/62、Redis-4.0%20psync%20优化.md)

- DEL, FLUSHALL/FLUSHDB异步化，不会阻塞主线程

- RDB-AOF 混合持久化

- 新增 MEMORY 命令

- 集群兼容 NAT / Docker

