
#Redis等缓存系统/中间件/NoSQL/一致性Hash等

## 缓存击穿、失效以及热点key问题

### 缓存击穿：
　　查询一个数据库中不存在的数据，比如商品详情，查询一个不存在的ID，每次都会访问DB，
如果有人恶意破坏，很可能直接对DB造成过大地压力。

- 缓存击穿的解决方案：

　　当通过某一个key去查询数据的时候，如果对应在数据库中的数据都不存在，
我们将此key对应的value设置为一个默认的值，比如“NULL”，并设置一个缓存的失效时间，
这时在缓存失效之前，所有通过此key的访问都被缓存挡住了。后面如果此key对应的数据在DB中存在时，
缓存失效之后，通过此key再去访问数据，就能拿到新的value了。

### 缓存失效：
　　在高并发的环境下，如果此时key对应的缓存失效，此时有多个进程就会去同时去查询DB，
然后再去同时设置缓存。这个时候如果这个key是系统中的热点key或者同时失效的数量比较多时，DB访问量会瞬间增大，造成过大的压力。

#### 缓存失效的解决方案：

将系统中key的缓存失效时间均匀地错开，防止统一时间点有大量的key对应的缓存失效；
重新设计缓存的使用方式，当我们通过key去查询数据时，首先查询缓存，如果此时缓存中查询不到，
就通过分布式锁进行加锁，取得锁的进程查DB并设置缓存，然后解锁；其他进程如果发现有锁就等待，
然后等解锁后返回缓存数据或者再次查询DB。

### 热点key：

　　缓存中的某些Key(可能对应用与某个促销商品)对应的value存储在集群中一台机器，使得所有流量涌向同一机器，
成为系统的瓶颈，该问题的挑战在于它无法通过增加机器容量来解决。

- 热点key的解决方案：

客户端热点key缓存：将热点key对应value并缓存在客户端本地，并且设置一个失效时间。对于每次读请求，
将首先检查key是否存在于本地缓存中，如果存在则直接返回，如果不存在再去访问分布式缓存的机器。
将热点key分散为多个子key，然后存储到缓存集群的不同机器上，这些子key对应的value都和热点key是一样的。
当通过热点key去查询数据时，通过某种hash算法随机选择一个子key，然后再去访问缓存机器，将热点分散到了多个子key上。

<https://www.jianshu.com/p/d5a3668d4dad>
 
 
 缓存雪崩
 缓存雪崩可能是因为数据未加载到缓存中，或者缓存同一时间大面积的失效，从而导致所有请求都去查数据库，导致数据库CPU和内存负载过高，甚至宕机。
 
 解决思路：
 
 1，采用加锁计数，或者使用合理的队列数量来避免缓存失效时对数据库造成太大的压力。这种办法虽然能缓解数据库的压力，但是同时又降低了系统的吞吐量。
 
 2，分析用户行为，尽量让失效时间点均匀分布。避免缓存雪崩的出现。
 
 3，如果是因为某台缓存服务器宕机，可以考虑做主备，比如：redis主备，但是双缓存涉及到更新事务的问题，update可能读到脏数据，需要好好解决。
 
  
 
 缓存穿透
 缓存穿透是指用户查询数据，在数据库没有，自然在缓存中也不会有。这样就导致用户查询的时候，在缓存中找不到，每次都要去数据库中查询。
 
 解决思路：
 
 1，如果查询也为空，直接设置一个默认值存放到缓存，这样第二次到缓冲中获取就有值了，而不会继续访问数据库，这种办法最简单粗暴。
 
 2，根据缓存数据Key的规则。例如我们公司是做机顶盒的，缓存数据以Mac为Key，Mac是有规则，如果不符合规则就过滤掉，这样可以过滤一部分查询。在做缓存规划的时候，Key有一定规则的话，可以采取这种办法。这种办法只能缓解一部分的压力，过滤和系统无关的查询，但是无法根治。
 
 3，采用布隆，将所有可能存在的数据哈希到一个足够大的BitSet中，不存在的数据将会被拦截掉，从而避免了对存储系统的查询压力。关于布隆，详情查看：基于BitSet的布隆过滤器(Bloom Filter) 
 
 大并发的缓存穿透会导致缓存雪崩。
 
  
 
 缓存预热
 单机web系统情况下比较简单。
 
 解决思路：
 
 1，直接写个缓存刷新页面，上线时手工操作下。
 
 2，数据量不大，可以在WEB系统启动的时候加载。
 
 3，搞个定时刷新缓存，或者由用户触发都行。
 
 缓存系统，如Memcached，Redis，比如缓存系统比较大，由十几台甚至几十台机器组成，这样预热会复杂一些。
 
 解决思路：
 
 1，写个程序去跑。
 
 2，单个缓存预热。
 
 缓存预热的目标就是在系统上线前，将数据加载到缓存中。
 
  
 
 ### 缓存穿透
 什么是缓存穿透？
 一般的缓存系统，都是按照key去缓存查询，如果不存在对应的value，就应该去后端系统查找（比如DB）。
 如果key对应的value是一定不存在的，并且对该key并发请求量很大，就会对后端系统造成很大的压力。这就叫做缓存穿透。  
 
 如何避免？
 1：对查询结果为空的情况也进行缓存，缓存时间设置短一点，或者该key对应的数据insert了之后清理缓存。 
 2：对一定不存在的key进行过滤。可以把所有的可能存在的key放到一个大的Bitmap中，
 查询时通过该bitmap过滤。【感觉应该用的不多吧】
 
 ### 缓存雪崩
 
 - 什么是缓存雪崩？
 
 当缓存服务器重启或者大量缓存集中在某一个时间段失效，这样在失效的时候，也会给后端系统(比如DB)带来很大压力。
 
 如何避免？
 
 1：在缓存失效后，通过加锁或者队列来控制读数据库写缓存的线程数量。
 比如对某个key只允许一个线程查询数据和写缓存，其他线程等待。 2：不同的key，设置不同的过期时间，
 让缓存失效的时间点尽量均匀。 3：做二级缓存，A1为原始缓存，A2为拷贝缓存，A1失效时，
 可以访问A2，A1缓存失效时间设置为短期，A2设置为长期（此点为补充）  
 
 分布式缓存系统
 
 分布式缓存系统面临的问题
 
 缓存一致性问题
 1：缓存系统与底层数据的一致性。这点在底层系统是“可读可写”时，写得尤为重要 
 
 2：有继承关系的缓存之间的一致性。为了尽量提高缓存命中率，缓存也是分层：全局缓存，二级缓存。
 他们是存在继承关系的。全局缓存可以有二级缓存来组成。 
 
 3：多个缓存副本之间的一致性。为了保证系统的高可用性，缓存系统背后往往会接两套存储系统（如memcache，redis等）
 
 缓存穿透和缓存雪崩
 上面有讲述。  
 
 缓存数据的淘汰
 缓存淘汰的策略有两种： 
 
 (1) 定时去清理过期的缓存。
 
 (2）当有用户请求过来时，再判断这个请求所用到的缓存是否过期，过期的话就去底层系统得到新数据并更新缓存。  
 
 两者各有优劣，第一种的缺点是维护大量缓存的key是比较麻烦的，第二种的缺点就是每次用户请求过来都要判断缓存失效，
 逻辑相对比较复杂，具体用哪种方案，大家可以根据自己的应用场景来权衡。   
 
 1. 预估失效时间 2. 版本号（必须单调递增，时间戳是最好的选择）3. 提供手动清理缓存的接口。
 
  
 
 缓存算法
 FIFO算法：First in First out，先进先出。原则：一个数据最先进入缓存中，则应该最早淘汰掉。也就是说，
 当缓存满的时候，应当把最先进入缓存的数据给淘汰掉。
 
 LFU算法：Least Frequently Used，最不经常使用算法。
 
 LRU算法：Least Recently Used，近期最少使用算法。请 
 
 LRU和LFU的区别。LFU算法是根据在一段时间里数据项被使用的次数选择出最少使用的数据项，
 即根据使用次数的差异来决定。而LRU是根据使用时间的差异来决定的
 
<http://www.cnblogs.com/jinjiangongzuoshi/p/5240280.html>


## 列举一个常用的Redis客户端的并发模型。

## HBase如何实现模糊查询？

## 列举一个常用的消息中间件，如果消息要保序如何实现？

## 如何实现一个Hashtable？你的设计如何考虑Hash冲突？如何优化？

## 分布式缓存，一致性hash

## LRU算法，slab分配，如何减少内存碎片

## 如何解决缓存单机热点问题

## 什么是布隆过滤器，其实现原理是？ False positive指的是？

## memcache与redis的区别

1)、存储方式

Memecache把数据全部存在内存之中，断电后会挂掉，数据不能超过内存大小。

Redis有部份存在硬盘上，这样能保证数据的持久性。

2)、数据支持类型

Memcache对数据类型支持相对简单。

Redis有复杂的数据类型。

3)、使用底层模型不同

它们之间底层实现方式 以及与客户端之间通信的应用协议不一样。

Redis直接自己构建了VM 机制 ，因为一般的系统调用系统函数的话，会浪费一定的时间去移动和请求。

4）value大小 redis最大可以达到1GB，而memcache只有1MB


## zookeeper有什么功能，选举算法如何进行

## map/reduce过程，如何用map/reduce实现两个数据源的联合统计


 