## [原文](https://www.jianshu.com/p/154ec88b0cc1)

## [原文](https://blog.csdn.net/qq_19568599/article/details/52612421 )

# Redis与Zookeeper实现分布式锁的区别

## 1、Redis分布式锁实现

### a、原理
      Redis为单进程单线程模式，采用队列模式将并发访问变成串行访问，且多客户端对Redis的连接并不存在竞争关系。
其次Redis提供一些命令SETNX，GETSET，可以方便实现分布式锁机制。

```java

public class RedisKeyLock {
    private static Logger logger = Logger.getLogger(RedisKeyLock.class);
    private final static long ACCQUIRE_LOCK_TIMEOUT_IN_MS = 10 * 1000;
    private final static int EXPIRE_IN_SECOND = 5;//锁失效时间
    private final static long WAIT_INTERVAL_IN_MS = 100;
    private static RedisKeyLock lock;
    private JedisPool jedisPool;
    private RedisKeyLock(JedisPool pool){
        this.jedisPool = pool;
    }
    public static RedisKeyLock getInstance(JedisPool pool){
        if(lock == null){
            lock = new RedisKeyLock(pool);
        }
        return lock;
    }
 
    public void lock(final String redisKey) {
        Jedis resource = null;
        try {
            long now = System.currentTimeMillis();
            resource = jedisPool.getResource();
            long timeoutAt = now + ACCQUIRE_LOCK_TIMEOUT_IN_MS;
            boolean flag = false;
            while (true) {
                String expireAt = String.valueOf(now + EXPIRE_IN_SECOND * 1000);
                long ret = resource.setnx(redisKey, expireAt);
                if (ret == 1) {//已获取锁
                    flag = true;
                    break;
                } else {//未获取锁，重试获取锁
                    String oldExpireAt = resource.get(redisKey);
                    if (oldExpireAt != null && Long.parseLong(oldExpireAt) < now) {
                        oldExpireAt = resource.getSet(redisKey, expireAt);
                        if (Long.parseLong(oldExpireAt) < now) {
                            flag = true;
                            break;
                        }
                    }
                }
                if (timeoutAt < now) {
                    break;
                }
              TimeUnit.NANOSECONDS.sleep(WAIT_INTERVAL_IN_MS);
            }
            if (!flag) {
                throw new RuntimeException("canot acquire lock now ...");
            }
        } catch (JedisException je) {
            logger.error("lock", je);
            je.printStackTrace();
            if (resource != null) {
                jedisPool.returnBrokenResource(resource);
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("lock", e);
        } finally {
            if (resource != null) {
                jedisPool.returnResource(resource);
            }
        }
    }
    public boolean unlock(final String redisKey) {
        Jedis resource = null;
        try {
            resource = jedisPool.getResource();
            resource.del(redisKey);
            return true;
        } catch (JedisException je) {
            je.printStackTrace();
            if (resource != null) {
                jedisPool.returnBrokenResource(resource);
            }
            return false;
        } catch (Exception e) {
            logger.error("lock", e);
            return false;
        } finally {
            if (resource != null) {
                jedisPool.returnResource(resource);
            }
        }
    }
}
```

### c、代码分析
      lock:通过间隔时间段去请求Redis，来实现阻塞占用，一直到获取锁，或者超时。

     unlock:删除redis中key。

 

## Zookeeper分布式锁实现

###  a、原理
        ZooKeeper核心是一个精简的文件系统，它提供了一些简单的文件操作以及附加的功能 ，它的数据结构原型是一棵znode树（类似Linux的文件系统），
   并且它们是一些已经被构建好的块，可以用来构建大型的协作数据结构和协议 。
   
     每个锁都需要一个路径来指定(如:/geffzhang/lock)
   
   1.根据指定的路径, 查找zookeeper集群下的这个节点是否存在.(说明已经有锁了)
   
   2. 如果存在, 根据查询者的一些特征数据(如ip地址/hostname), 当前的锁是不是查询者的
   
   3. 如果不是查询者的锁, 则返回null, 说明创建锁失败
   
   4. 如果是查询者的锁, 则把这个锁返回给查询者
   
   5. 如果这个节点不存在, 说明当前没有锁, 那么创建一个临时节点, 并将查询者的特征信息写入这个节点的数据中, 然后返回这个锁.
   
   据以上5部, 一个分布式的锁就可以创建了.
   
   创建的锁有三种状态:
   
   1. 创建失败(null), 说明该锁被其他查询者使用了.’
   
   2. 创建成功, 但当前没有锁住(unlocked), 可以使用
   
   3. 创建成功, 但当前已经锁住(locked)了, 不能继续加锁.
 
### b、代码样例
```java
public class ZooKeeperLock implements Lock, Watcher {
 
    private Logger logger = LoggerFactory.getLogger(getClass());
 
    private static final String SPLITSTR = "_lock_";
    private static final int SESSION_TIMEOUT = 60000;//等锁的毫秒数
    private static final byte[] data = new byte[0];
 
 
    private ZooKeeper zk = null;
 
    private String root = "/locks";//根
    private String lockName;//竞争资源的标志
    private String waitNode;//等待前一个锁
    private String myZnode;//当前锁
 
    private CountDownLatch latch;//计数器
 
    /**
     * 创建分布式锁,使用前请确认config配置的zookeeper服务可用
     * @param server 127.0.0.1:2181
     * @param lockName 竞争资源标志,lockName中不能包含单词lock
     */
    public ZooKeeperLock(String server, String lockName){
        this.lockName = lockName;
        // 创建一个与服务器的连接
        try {
            zk = initZk(server);
            Stat stat = zk.exists(root, false);
            if(stat == null){
                // 创建根节点
                zk.create(root, data, ZooDefs.Ids.OPEN_ACL_UNSAFE,CreateMode.PERSISTENT);
            }
        } catch (Exception e) {
            throw new LockException(e);
        }
    }
 
    /**
     * zookeeper节点的监视器
     */
    @Override
    public void process(WatchedEvent event) {
        if(this.latch != null) {
            this.latch.countDown();
        }
    }
 
    @Override
    public void lock() {
        try {
            if(!tryLock()){
                boolean locked = waitForLock(waitNode, SESSION_TIMEOUT, TimeUnit.MILLISECONDS);//等待锁
                if(!locked){
                    logger.error("can not lock...");
                }
            }
        } catch (Exception e) {
            throw new LockException(e);
        }
    }
 
    public boolean tryLock() {
        try {
            if(lockName.contains(SPLITSTR)){
                throw new LockException("lockName can not contains \\u000B");
            }
            //创建临时子节点
            myZnode = zk.create(root + "/" + lockName + SPLITSTR, data, ZooDefs.Ids.OPEN_ACL_UNSAFE,CreateMode.EPHEMERAL_SEQUENTIAL);
 
            //取出所有子节点
            List<String> subNodes = zk.getChildren(root, false);
            //取出所有lockName的锁
            List<String> lockObjNodes = new ArrayList<>();
            for (String node : subNodes) {
                String _node = node.split(SPLITSTR)[0];
                if(_node.equals(lockName)){
                    lockObjNodes.add(node);
                }
            }
            Collections.sort(lockObjNodes);
 
            if(myZnode.equals(root+"/"+lockObjNodes.get(0))){
                //如果是最小的节点,则表示取得锁
                return true;
            }
            //如果不是最小的节点，找到比自己小1的节点
            String subMyZnode = myZnode.substring(myZnode.lastIndexOf("/") + 1);
            waitNode = lockObjNodes.get(Collections.binarySearch(lockObjNodes, subMyZnode) - 1);
        } catch (Exception e) {
            throw new LockException(e);
        }
        return false;
    }
 
    @Override
    public boolean tryLock(long time, TimeUnit unit) {
        try {
            return tryLock() || waitForLock(waitNode, time, unit);
        } catch (Exception e) {
            throw new LockException(e);
        }
    }
 
    private boolean waitForLock(String lower, long waitTime, TimeUnit unit) throws InterruptedException, KeeperException {
        Stat stat = zk.exists(root + "/" + lower, true);
        //判断比自己小一个数的节点是否存在,如果不存在则无需等待锁,同时注册监听
        if(stat != null){
            this.latch = new CountDownLatch(1);
            this.latch.await(waitTime, unit);
            this.latch = null;
        }
        return true;
    }
 
    @Override
    public void unlock() {
        try {
            zk.delete(myZnode,-1);
            myZnode = null;
        } catch (Exception e) {
            throw new LockException(e);
        }
    }
 
    private synchronized ZooKeeper initZk(String server) {
        try {
            if(zk == null){
                zk = new ZooKeeper(server, SESSION_TIMEOUT, this);
            }
        } catch (IOException e) {
            throw new LockException("zk init connect fail" + e.getMessage());
        }
        return zk;
    }
 
    @Override
    public void lockInterruptibly() throws InterruptedException {
        this.lock();
    }
 
    @Override
    public Condition newCondition() {
        return null;
    }
 
    private class LockException extends RuntimeException {
        private static final long serialVersionUID = 1L;
        private LockException(String e){
            super(e);
        }
        private LockException(Exception e){
            super(e);
        }
    }
}
```

### c、代码分析
      lock:根据根创建锁节点，然后获取当前已经存在锁的节点，如果第一个节点为自己创建，说明没有锁，不是自己加锁，
则给自己创建节点的上一个节点加监听，线程阻塞至上一个节点释放，并通知我，或者等待超时。

      unlock:删除自己创建的节点，zookeeper会自动通知加在节点上的监听。

 
## 两者区别
       Redis分布式锁，必须使用者自己间隔时间轮询去尝试加锁，当锁被释放后，存在多线程去争抢锁，
并且可能每次间隔时间去尝试锁的时候，都不成功，对性能浪费很大。

       Zookeeper分布锁，首先创建加锁标志文件，如果需要等待其他锁，则添加监听后等待通知或者超时，
当有锁释放，无须争抢，按照节点顺序，依次通知使用者。


 