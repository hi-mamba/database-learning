

# redis数据结构

## 1 Key
Key 不能太长，比如1024字节，但antirez也不喜欢太短如"u:1000:pwd"，要表达清楚意思才好。
他私人建议用":"分隔域，用"."作为单词间的连接，如"comment:1234:reply.to"。

Keys，返回匹配的key，支持通配符如 "keys a*" 、 "keys a?c"，但不建议在生产环境大数据量下使用。

Sort，对集合按数字或字母顺序排序后返回或另存为list，还可以关联到外部key等。
因为复杂度是最高的O(N+M*log(M))(N是集合大小，M 为返回元素的数量)，有时会安排到slave上执行。

Expire/ExpireAt/Persist/TTL，关于Key超时的操作。默认以秒为单位，也有p字头的以毫秒为单位的版本

## 2 String

最普通的key-value类型，说是String，其实是任意的byte[]，比如图片，最大512M。 
所有常用命令的复杂度都是O(1)，普通的Get/Set方法，可以用来做Cache，存Session，为了简化架构甚至可以替换掉Memcached。

Incr/IncrBy/IncrByFloat/Decr/DecrBy，可以用来做计数器，做自增序列。
key不存在时会创建并贴心的设原值为0。IncrByFloat专门针对float，没有对应的decrByFloat版本？用负数啊。

SetNx， 仅当key不存在时才Set。可以用来选举Master或做分布式锁：所有Client不断尝试使用SetNx master myName抢注Master，
成功的那位不断使用Expire刷新它的过期时间。

如果Master倒掉了key就会失效，剩下的节点又会发生新一轮抢夺。

其他Set指令：

SetEx， Set + Expire 的简便写法，p字头版本以毫秒为单位。

GetSet， 设置新值，返回旧值。比如一个按小时计算的计数器，可以用GetSet获取计数并重置为0。这种指令在服务端做起来是举手之劳，客户端便方便很多。

MGet/MSet/MSetNx， 一次get/set多个key。

2.6.12版开始，Set命令已融合了Set/SetNx/SetEx三者，SetNx与SetEx可能会被废弃，这对Master抢注非常有用，
不用担心setNx成功后，来不及执行Expire就倒掉了。可惜有些懒惰的Client并没有快速支持这个新指令。

GetBit/SetBit/BitOp,与或非/BitCount， BitMap的玩法，比如统计今天的独立访问用户数时，
每个注册用户都有一个offset，他今天进来的话就把他那个位设为1，用BitCount就可以得出今天的总人树。

Append/SetRange/GetRange/StrLen，对文本进行扩展、替换、截取和求长度，只对特定数据格式如字段定长的有用，json就没什么用。

## 3 Hash
Key-HashMap结构，相比String类型将这整个对象持久化成JSON格式，Hash将对象的各个属性存入Map里，可以只读取/更新对象的某些属性。

这样有些属性超长就让它一边呆着不动，另外不同的模块可以只更新自己关心的属性而不会互相并发覆盖冲突。

另一个用法是土法建索引。比如User对象，除了id有时还要按name来查询。

可以有如下的数据记录:
```
(String) user:101 -> {"id":101,"name":"calvin"...}
(String) user:102 -> {"id":102,"name":"kevin"...}
(Hash) user:index-> "calvin"->101, "kevin" -> 102
```
底层实现是hash table，一般操作复杂度是O(1)，要同时操作多个field时就是O(N)，N是field的数量。

## 4 List
List是一个双向链表，支持双向的Pop/Push，江湖规矩一般从左端Push，右端Pop——LPush/RPop，
而且还有Blocking的版本BLPop/BRPop，客户端可以阻塞在那直到有消息到来，所有操作都是O(1)的好孩子，可以当Message Queue来用。

当多个Client并发阻塞等待，有消息入列时谁先被阻塞谁先被服务。任务队列系统Resque是其典型应用。

还有RPopLPush/ BRPopLPush，弹出来返回给client的同时，把自己又推入另一个list，LLen获取列表的长度。

还有按值进行的操作：LRem(按值删除元素)、LInsert(插在某个值的元素的前后)，复杂度是O(N)，
N是List长度，因为List的值不唯一，所以要遍历全部元素，而Set只要O(log(N))。

按下标进行的操作：下标从0开始，队列从左到右算，下标为负数时则从右到左。

LSet ，按下标设置元素值。

LIndex，按下标返回元素。

LRange，不同于POP直接弹走元素，只是返回列表内一段下标的元素，是分页的最爱。

LTrim，限制List的大小，比如只保留最新的20条消息。

复杂度也是O(N)，其中LSet的N是List长度，LIndex的N是下标的值，LRange的N是start的值+列出元素的个数，
因为是链表而不是数组，所以按下标访问其实要遍历链表，除非下标正好是队头和队尾。LTrim的N是移除元素的个数。

在消息队列中，并没有JMS的ack机制，如果消费者把job给Pop走了又没处理完就死机了怎么办？

解决方法之一是加多一个sorted set，分发的时候同时发到list与sorted set，以分发时间为score，
用户把job做完了之后要用ZREM消掉sorted set里的job，并且定时从sorted set中取出超时没有完成的任务，重新放回list。

另一个做法是为每个worker多加一个的list，弹出任务时改用RPopLPush，将job同时放到worker自己的list中，完成时用LREM消掉。

如果集群管理(如zookeeper)发现worker已经挂掉，就将worker的list内容重新放回主list。

## 5 Set
Set就是Set，可以将重复的元素随便放入而Set会自动去重，底层实现也是hash table。

SAdd/SRem/SIsMember/SCard/SMove/SMembers，各种标准操作。除了SMembers都是O(1)。

SInter/SInterStore/SUnion/SUnionStore/SDiff/SDiffStore，各种集合操作。
交集运算可以用来显示在线好友(在线用户 交集 好友列表)，共同关注(两个用户的关注列表的交集)。

O(N)，并集和差集的N是集合大小之和，交集的N是小的那个集合的大小*2。

## 6 Sorted Set
有序集，元素放入集合时还要提供该元素的分数。

ZRange/ZRevRange，按排名的上下限返回元素，正数与倒数。

ZRangeByScore/ZRevRangeByScore，按分数的上下限返回元素，正数与倒数。

ZRemRangeByRank/ZRemRangeByScore，按排名/按分数的上下限删除元素。

ZCount，统计分数上下限之间的元素个数。

ZRank/ZRevRank ，显示某个元素的正倒序的排名。

ZScore/ZIncrby，显示元素的分数/增加元素的分数。

ZAdd(Add)/ZRem(Remove)/ZCard(Count)，ZInsertStore(交集)/ZUnionStore(并集)，Set操作，与正牌Set相比，少了IsMember和差集运算。

Sorted Set的实现是hash table(element->score, 用于实现ZScore及判断element是否在集合内)，
和skip list(score->element,按score排序)的混合体。

skip list有点像平衡二叉树那样，不同范围的score被分成一层一层，每层是一个按score排序的链表。

ZAdd/ZRem是O(log(N))，ZRangeByScore/ZRemRangeByScore是O(log(N)+M)，N是Set大小，M是结果/操作元素的个数。

可见，原本可能很大的N被很关键的Log了一下，1000万大小的Set，复杂度也只是几十不到。

当然，如果一次命中很多元素M很大那谁也没办法了。