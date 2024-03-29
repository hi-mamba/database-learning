
<https://shuxiao.wang/posts/redis-rdb-fork/>

<https://blog.51cto.com/u_12132623/3066100>

<https://www.cnblogs.com/me115/p/5032177.html>

<https://mp.weixin.qq.com/s/Qc4t_-_pL4w8VlSoJhRDcg>

<https://www.cnblogs.com/wangcp-2014/p/15504775.html>

<https://blog.csdn.net/y532798113/article/details/106870168#:~:text=%EF%BC%881%EF%BC%89%E5%90%8C%E6%AD%A5%E6%93%8D%E4%BD%9C,%E4%BC%9A%E9%98%BB%E5%A1%9Eredis%E4%B8%BB%E8%BF%9B%E7%A8%8B%E3%80%82>

# fork 操作会阻塞引起问题

> 虽然fork同步操作是非常快的，但是如果需要同步的数据量过大(比如超过20G)，fork就会阻塞redis主进程。
内存越大，fork同步数据耗时越长

当 Redis 开启了后台 `RDB `和 `AOF rewrite` 后，
在执行时，它们都需要主进程创`建出一个子进程`进行数据的持久化。

主进程创建子进程，会`调用操作系统`提供的 fork 函数。

而 fork 在执行过程中，`主进程`需要`拷贝`自己的`内存页表`给子进程`，
如果这个实例很大，那么这个拷贝的过程也会比较耗时。

而且这个 `fork 过程`会`消耗大量的 CPU 资源`，在完成 fork 之前，
整个 Redis 实例会被阻塞住，无法处理任何客户端请求。

如果此时你的 CPU 资源本来就很紧张，那么 fork 的耗时会更长，
甚至达到秒级，这会严重影响 Redis 的性能。

## 那如何确认确实是因为 fork 耗时导致的 Redis 延迟变大呢？
你可以在 Redis 上执行 INFO 命令，查看 `latest_fork_usec `项，单位微秒。

## 生成 RDB引起性能
数据持久化会生成 RDB 之外，当主从节点第一次建立数据同步时，
主节点也创建子进程生成 RDB，然后发给从节点进行一次全量同步，
所以，这个过程也会对 Redis 产生性能影响。


## 优化方案

### 1. 控制 Redis 实例的内存
尽量在 10G 以下，执行 fork 的耗时与实例大小有关，实例越大，耗时越久

### 2. 合理配置数据持久化策略
在 slave 节点执行 RDB 备份，推荐在低峰期执行，
而对于丢失数据不敏感的业务（例如把 Redis 当做纯缓存使用），
可以关闭 AOF 和 AOF rewrite

### 3. Redis 实例不要部署在虚拟机上
fork 的耗时也与系统也有关，虚拟机比物理机耗时更久

### 4. 降低主从库全量同步的概率
适当调大 repl-backlog-size 参数，避免主从全量同步

> repl-backlog-size  主节点保存操作日志的大小。默认1M

## 会同时存在多个子进程吗？
不会，多个子进程会影响服务

## 主进程fork()子进程

<https://blog.51cto.com/u_12132623/3066100>

主进程fork()子进程之后，内核把主进程中所有的内存页的权限都设为`read-only`，然后子进程的地址空间指向主进程。
`共享主进程的内存`，当其中某个进程写内存时(这里肯定是`主进程写`，因为子进程只负责rdb文件持久化工作，不参与客户端的请求)，
CPU硬件检测到`内存页`是`read-only`的，于是触发`页异常中断（page-fault）`，陷入内核的一个`中断`例程。
中断例程中，内核就会把触发的`异常的页复制一份`（这里仅仅复制异常页，也就是所修改的那个数据页，而不是内存中的全部数据），
于是主子进程各自持有独立的一份。


数据修改之前的样子
![image](https://user-images.githubusercontent.com/7867225/156731567-938a8dea-fd74-472d-b30b-7c2251658e2b.png)

数据修改之后的样子
![image](https://user-images.githubusercontent.com/7867225/156733799-e302f56d-3680-43df-8609-00afb4505d9d.png)

