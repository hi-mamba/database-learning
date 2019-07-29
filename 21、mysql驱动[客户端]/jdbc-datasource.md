# JDBC之数据库连接池


## 　连接池技术 

### 引言

对于共享资源，有一个很著名的设计模式：资源池(resource pool)。
该模式正是为解决资源频繁分配、释放所造成的问题。数据库连接池的基本思想就是为数据库连接建立一个“缓冲池”。
预先在缓冲池中放入一定数量的连接，当需要建立数据库连接时，只需要从缓冲池中取出一个了，使用完毕后再放回去。
我们可以通过设定连接池最大数来防止系统无尽的与数据库连接。
更为重要的是我们可以通过连接池的管理机制监视数据库连接使用数量，使用情况，为系统开发，测试以及性能调整提供依据。


#### 什么是连接？

连接，是我们的编程语言与数据库交互的一种方式。我们经常会听到这么一句话“数据库连接很昂贵“。

有人接受这种说法，却不知道它的真正含义。因此，下面我将解释它究竟是什么。 

创建连接的代码片段：
```java
String connUrl = "jdbc:mysql://your.database.domain/yourDBname"; 
Class.forName("com.mysql.jdbc.Driver"); 
Connection con = DriverManager.getConnection (connUrl); 
```

当我们创建了一个Connection对象，它在内部都执行了什么：

- 1.“DriverManager”检查并注册驱动程序，
- 2.“com.mysql.jdbc.Driver”就是我们注册了的驱动程序，它会在驱动程序类中调用“connect(url…)”方法。
- 3.com.mysql.jdbc.Driver的connect方法根据我们请求的“connUrl”，
创建一个“Socket连接”，连接到IP为“your.database.domain”，默认端口3306的数据库。
- 4.创建的Socket连接将被用来查询我们指定的数据库，并最终让程序返回得到一个结果。

#### 为什么昂贵？

现在让我们谈谈为什么说它“昂贵“。

如果创建Socket连接花费的时间比实际的执行查询的操作所花费的时间还要更长。

这就是我们所说的“数据库连接很昂贵”，因为连接资源数是1，它需要每次创建一个Socket连接来访问DB。

因此，我们将使用连接池。

连接池初始化时创建一定数量的连接，然后从连接池中重用连接，而不是每次创建一个新的。


#### 怎样工作？

接下来我们来看看它是如何工作，以及如何管理或重用现有的连接。

我们使用的连接池供应者，它的内部有一个连接池管理器，当它被初始化：

1.它创建连接池的默认大小，比如指定创建5个连接对象，并把它存放在“可用”状态的任何集合或数组中。

例如，代码片段：

```java

... 
  String connUrl = "jdbc:mysql://your.database.domain/yourDBname"; 
  String driver = "com.mysql.jdbc.Driver"; 
  private Map<java.sql.Connection, String> connectionPool = null; 
  private void initPool() { 
    try { 
      connectionPool = new HashMap<java.sql.Connection, String>(); 
      Class.forName(driver); 
      java.sql.Connection con = DriverManager.getConnection(dbUrl); 
      for (int poolInd = poolSize; poolInd < 0; poolInd++) { 
        connectionPool.put(con, "AVAILABLE"); 
      } 
  } 
... 
```

2.当我们调用connectionProvider.getConnection()，然后它会从集合中获取一个连接，当然状态也会更改为“不可用”。

例如，代码片段：

```java
...
  public java.sql.Connection getConnection() throws ClassNotFoundException, SQLException
  { 
      boolean isConnectionAvailable = true; 
      for (Entry<java.sql.Connection, String> entry : connectionPool.entrySet()) { 
          synchronized (entry) { 
              if (entry.getValue()=="AVAILABLE") { 
                  entry.setValue("NOTAVAILABLE"); 
                  return (java.sql.Connection) entry.getKey(); 
              } 
              isConnectionAvailable = false; 
          } 
      } 
      if (!isConnectionAvailable) { 
          Class.forName(driver); 
          java.sql.Connection con = DriverManager.getConnection(connUrl); 
          connectionPool.put(con, "NOTAVAILABLE"); 
          return con; 
      } 
      return null; 
  } 
  ... 
```

3.当我们关闭得到的连接，ConnectionProvider是不会真正关闭连接。相反，只是将状态更改为“AVAILABLE”。

例如，代码片段：
```java

... 
public void closeConnection(java.sql.Connection connection) throws ClassNotFoundException, SQLException { 
    for (Entry<java.sql.Connection, String> entry : connectionPool.entrySet()) { 
        synchronized (entry) { 
            if (entry.getKey().equals(connection)) { 
                //Getting Back the conncetion to Pool 
                entry.setValue("AVAILABLE"); 
            } 
        } 
    } 
} 
... 
```

基本上连接池的实际工作原理就是这样，但也有可能使用不同的方式，

对象在池中是具有自己生命周期：创建、验证、使用、销毁等等。
Pool的方式也许是最好的方式用来管理同一的资源。


数据库连接池的基本原理是在内部对象池中维护一定数量的数据库连接，并对外暴露数据库连接获取和返回方法。如：

外部使用者可通过getConnection 方法获取连接，使用完毕后再通过releaseConnection 方法将连接返回，
注意此时连接并没有关闭，而是由连接池管理器回收，并为下一次使用做好准备。



最小连接数是连接池一直保持的数据连接。如果应用程序对数据库连接的使用量不大，将会有大量的数据库连接资源被浪费掉。

最大连接数是连接池能申请的最大连接数。如果数据连接请求超过此数，
后面的数据连接请求将被加入到等待队列中，这会影响之后的数据库操作。

数据库池连接数量一直保持一个不少于最小连接数的数量，当数量不够时，
数据库会创建一些连接，直到一个最大连接数，之后连接数据库就会等待


[转载](https://www.oschina.net/question/157182_72094)


### 连接池原理

连接池技术的核心思想是：连接复用，通过建立一个数据库连接 池以及一套连接使用、分配、管理策略，
使得该连接池中的连接可以得到高效、安全的复用，避免了数据库连接频繁建立、关闭的开销。
另外，由于对JDBC中的 原始连接进行了封装，从而方便了数据库应用对于连接的使用（特别是对于事务处理），提高了开发

效率，也正是因为这个封装层的存在，隔离了应用的本身的处理逻辑和具体数据库访问逻辑，使应用本身的复用成为可能。
连接池主要由三部分组成（如图1所示）：连接池的建立、连接池中连接的使用管理、连接池的关闭。
下面就着重讨论这三部分及连接池的配置问题。



#### 连接池的工作原理

下面，简单的阐述下连接池的工作原理。

连接池技术的核心思想是连接复用，通过建立一个数据库连接池以及一套连接使用、分配和管理策略，使得该连接池中的连接可以得到高效、
安全的复用，避免了数据库连接频繁建立、关闭的开销。

连接池的工作原理主要由三部分组成，分别为连接池的建立、连接池中连接的使用管理、连接池的关闭。

第一、连接池的建立。一般在系统初始化时，连接池会根据系统配置建立，并在池中创建了几个连接对象，以便使用时能从连接池中获取。
连接池中的连接不能随意创建和关闭，这样避免了连接随意建立和关闭造成的系统开销。Java中提供了很多容器类可以方便的构建连接池，例如Vector、Stack等。

第二、连接池的管理。连接池管理策略是连接池机制的核心，连接池内连接的分配和释放对系统的性能有很大的影响。其管理策略是：

当客户请求数据库连接时，首先查看连接池中是否有空闲连接，如果存在空闲连接，则将连接分配给客户使用；如果没有空闲连接，
则查看当前所开的连接数是否已经达到最大连接数，如果没达到就重新创建一个连接给请求的客户；
如果达到就按设定的最大等待时间进行等待，如果超出最大等待时间，则抛出异常给客户。
当客户释放数据库连接时，先判断该连接的引用次数是否超过了规定值，如果超过就从连接池中删除该连接，否则保留为其他客户服务。

该策略保证了数据库连接的有效复用，避免频繁的建立、释放连接所带来的系统资源开销。

第三、连接池的关闭。当应用程序退出时，关闭连接池中所有的连接，释放连接池相关的资源，该过程正好与创建相反。



[转载2](http://www.uml.org.cn/sjjm/201004153.asp)


### 连接池的相关问题分析：

#### 1、并发问题。

为了使连接管理服务具有最大的通用性，必须考虑多线程环境，并发问题。
这个问题相对比较好解决，因为各个语言自身提供了并发管理的支持，
比如java c#等，使用synchronized(java)  lock(c#)等关键字确保线程同步。


##### 2、事务管理。

我们知道，事务具有原子性，此时要求对数据库操作符合“ALL-ALL-NOTHING”原则，
即对于一组sql语句要么全做，要么全不做。我们知道当两个线程共用一个连接connection对象时，
而且各自都有自己的事务要处理时，对于连接池是一个很头疼的问题，因为即使connection类提供了相应的事务支持，
可是我们仍然不能确定那个数据库操作对应那个事务。知识由于我们的两个线程都在进行事务操作。

为此我们可以使用每一个事物独占一个连接来实现，虽然这种方法有点浪费连接池资源但是可以大大降低事务管理的复杂性。


#### 3、连接池的分配与释放

连接池的分配与释放，对系统的性能有很大的影响。合理的分配与释放，可以提高连接的复用度，
从而降低建立新连接的开销，同时还可以加快用户的访问速度。 　　
对于连接的管理可使用一个List。即把已经创建的连接都放入List中去统一管理。
每当用户请求一个连接时，系统检查这个List中有没有可以分配的连接。
如果有就把那个最合适的连接分配给他（如何能找到最合适的连接文章将在关键议题中指出）；
如果没有就抛出一个异常给用户，List中连接是否可以被分配由一个线程来专门管理捎后我会介绍这个线程的具体实现。

#### 4、连接池的配置与维护

连接池中到底应该放置多少连接，才能使系统的性能最佳？
系统可采取设置最小连接数（minConnection）和最大连接数（maxConnection）等参数来控制连接池中的连接。

比方说，最小连接数是系统启动时连接池所创建的连接数。
如果创建过多，则系统启动就慢，但创建后系统的响应速度会很快；
如果创建过少，则系统启动的很快，响应起来却慢。
这样，可以在开发时，设置较小的最小连接数，开发起来会快，而在系统实际使用时设置较大的，因为这样对访问客户来说速度会快些。
最大连接数是连接池中允许连接的最大数目，具体设置多少，要看系统的访问量，可通过软件需求上得到。
如何确保连接池中的最小连接数呢？有动态和静态两种策略。
动态即每隔一定时间就对连接池进行检测，如果发现连接数量小于最小连接数，
则补充相应数量的新连接,以保证连接池的正常运转。静态是发现空闲连接不够时再去检查。


引用记数

在分配、释放策略对于有效复用连接非常重要，我们采用的方法也是采用了一个很有名的设计模式：reference counting（引用记数）。
该模式在复用资源方面使用非常广泛，我们把该方法运用到对于连接分配释放上。
每一个数据库连接，保留一个引用记数，用来记录该链接的使用者的个数。
具体实现上，我们对connection类进行了进一步包装来实现引用记数。
被包装的connection类我们提供2个方法来实现引用记数的操作，一个是repeat（被分配出去）一个是remove（被释放回来）;
然后利用repeatnow属性来确定当前引用多少，具体是哪个用户引用了该连接，将在连接池中登记；
最后提供isRepeat属性来确定该连接是否可以使用引用记数技术。
一旦一个连接被分配出去，那么就会对该连接的申请者进行登记，并且增加引用记数，
当被释放回来时就删除他登记的信息，同时减少一次引用记数。
这样做的一个很大的好处是，使得我们可以高效的使用连接，
因为一旦所有连接都被分配出去，我们就可以根据相应的策略从使用池中挑出一个正在使用的连接来复用，
而不是随便拿出一个连接去复用。



#### 5、 多数据库服务器和多用户

对于大型的企业级应用，常常需要同时连接不同的数据库（如连接oracle和sybase）。
如何连接不同的数据库呢？
我们采用的策略是：设计一个符合单例模式的连接池管理类，在连接池管理类的唯一实例被创建时读取一个资源文件，
其中资源文件中存放着多个数据库的url地址等信息。
根据资源文件提供的信息，创建多个连接池类的实例，每一个实例都是一个特定数据库的连接池。
连接池管理类实例为每个连接池实例取一个名字，通过不同的名字来管理不同的连接池。

对于同一个数据库有多个用户使用不同的名称和密码访问的情况，也可以通过资源文件处理，
即在资源文件中设置多个具有相同url地址，但具有不同用户名和密码的数据库连接信息。




连接池用于创建和管理数据库连接的缓冲技术，缓冲池中的连接可以被任何需要他们的线程使用。
当一个线程需要使用JDBC对一个数据库操作时，将从池中请求一个连接。当这个链接使用完毕后，
将返回连接池中，等待为其他的线程服务。

#### 连接池的主要优点：

1）减少连接的创建时间，连接池中的连接是已准备好的，可以重复使用的，获取后可以直接访问数据库，

因此减少了连接创建的次数和时间。

2）简化的编程模式。当使用连接池时，每一个单独的线程能够像创建自己的JDBC连接一样操作，允许用户直接使用　JDBC编程技术。

3）控制资源的使用。如果不使用连接池，每次访问数据库都需要创建一个连接，这样系统的稳定性受系统的连接需求影响很大，
很容易产生资源浪费和高负载异常。连接池能够使性能最大化，将资源利用控制在一定的水平之下。
连接池能控制池中的链接数量，增强了系统在大量用户应用时的稳定性。

连接池的工作原理：

连接池的核心思想是连接的复用，通过建立一个数据库连接池以及一套连接使用、分配和管理策略，
使得该连接池中的连接可以得到高效，安全的复用，避免了数据库连接频繁建立和关闭的开销。

连接池的工作原理主要由三部分组成，分别为连接池的建立，连接池中连接的使用管理，连接池的关闭。

第一、连接池的建立。一般在系统初始化时，连接池会根据系统配置建立，并在池中建立几个连接对象，以便使用时能从连接池中获取，连接池中的连接不能随意创建和关闭，这样避免了连接随意建立和关闭造成的系统开销。java中提供了很多容器类，可以方便的构建连接池，例如Vector,stack等。

第二、连接池的管理。连接池管理策略是连接池机制的核心，连接池内连接的分配和释放对系统的性能有很大的影响。其策略是：

当客户请求数据库连接时，首先查看连接池中是否有空闲连接，如果存在空闲连接，则将连接分配给客户使用；如果没有控线连接，则查看当前所开的连接数是否已经达到最大连接数，例如如果没有达到就重新创建一个请求的客户；如果达到，就按设定的最大等待时间进行等待，如果超出最大等待时间，则抛出异常给客户。

当客户释放数据库连接时，先判断该连接的引用次数是否超过了规定值，如果超过了就从连接池中删除该连接，否则就保留为其他客户服务。该策略保证了数据库连接的有效复用，避免了频繁建立释放连接所带来的系统资源的开销。

第三、连接池的关闭。当应用程序退出时，关闭连接池中所有的链接，释放连接池相关资源，该过程正好与创建相反。


[转载1](http://www.cnblogs.com/blogofwyl/p/5407764.html)


[转载](https://jackchan1999.github.io/2017/05/01/javaweb/JDBC%E4%B9%8B%E6%95%B0%E6%8D%AE%E5%BA%93%E8%BF%9E%E6%8E%A5%E6%B1%A0/)


![](./images/jdbc/jdbc-translations.png)


## 1. 池参数（所有池参数都有默认值）

- 初始大小：10个
- 最小空闲连接数：3个
- 增量：一次创建的最小单位（5个）
- 最大空闲连接数：12个
- 最大连接数：20个
- 最大的等待时间：1000毫秒

## 2. 四大连接参数
连接池也是使用四大连接参数来完成创建连接对象！

## 3. 实现的接口
连接池必须实现：javax.sql.DataSource接口！

连接池返回的Connection对象，它的close()方法与众不同！调用它的close()不是关闭，而是把连接归还给池！

## 4. 数据库连接池

### 4.1 数据库连接池的概念
用池来管理Connection，这可以重复使用Connection。
有了池，所以我们就不用自己来创建Connection，而是通过池来获取Connection对象。
当使用完Connection后，调用Connection的close()方法也不会真的关闭Connection，而是把Connection“归还”给池。
池就可以再利用这个Connection对象了.


![](./images/jdbc/jdbc-database-1.png)


### 4.2 JDBC数据库连接池接口（DataSource）
Java为数据库连接池提供了公共的接口：javax.sql.DataSource，各个厂商可以让自己的连接池实现这个接口。
这样应用程序可以方便的切换不同厂商的连接池！

### 4.3 自定义连接池（ItcastPool）
分析：ItcastPool需要有一个List，用来保存连接对象。
在ItcastPool的构造器中创建5个连接对象放到List中！
当用人调用了ItcastPool的getConnection()时，那么就从List拿出一个返回。当List中没有连接可用时，抛出异常

我们需要对Connection的close()方法进行增强，所以我们需要自定义ItcastConnection类，对Connection进行装饰！
即对close()方法进行增强。因为需要在调用close()方法时把连接“归还”给池，
所以ItcastConnection类需要拥有池对象的引用，并且池类还要提供“归还”的方法

![](./images/jdbc/jdbc-database-2.png)

  
## 5. DBCP

### 5.1 什么是DBCP？

DBCP是Apache提供的一款开源免费的数据库连接池！

Hibernate3.0之后不再对DBCP提供支持！因为Hibernate声明DBCP有致命的缺欠！DBCP因为Hibernate的这一毁谤很是生气，并且说自己没有缺欠

5.2 DBCP的使用

```java

public void fun1() throws SQLException {
  BasicDataSource ds = new BasicDataSource();
  ds.setUsername("root");
  ds.setPassword("123");
  ds.setUrl("jdbc:mysql://localhost:3306/mydb1");
  ds.setDriverClassName("com.mysql.jdbc.Driver");
  ds.setMaxActive(20);
  ds.setMaxIdle(10);
  ds.setInitialSize(10);
  ds.setMinIdle(2);
  ds.setMaxWait(1000);
  Connection con = ds.getConnection();
  System.out.println(con.getClass().getName());
  con.close();
}

```

### 5.3 DBCP的配置信息
下面是对DBCP的配置介绍：

```properties

#基本配置
driverClassName=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/mydb1
username=root
password=123
#初始化池大小，即一开始池中就会有10个连接对象
默认值为0
initialSize=0
#最大连接数，如果设置maxActive=50时，池中最多可以有50个连接，当然这50个连接中包含被使用的和没被使用的（空闲）
#你是一个包工头，你一共有50个工人，但这50个工人有的当前正在工作，有的正在空闲
#默认值为8，如果设置为非正数，表示没有限制！即无限大
maxActive=8
#最大空闲连接
#当设置maxIdle=30时，你是包工头，你允许最多有20个工人空闲，如果现在有30个空闲工人，那么要开除10个
#默认值为8，如果设置为负数，表示没有限制！即无限大
maxIdle=8
#最小空闲连接
#如果设置minIdel=5时，如果你的工人只有3个空闲，那么你需要再去招2个回来，保证有5个空闲工人
#默认值为0
minIdle=0
#最大等待时间
#当设置maxWait=5000时，现在你的工作都出去工作了，又来了一个工作，需要一个工人。
#这时就要等待有工人回来，如果等待5000毫秒还没回来，那就抛出异常
#没有工人的原因：最多工人数为50，已经有50个工人了，不能再招了，但50人都出去工作了。
#默认值为-1，表示无限期等待，不会抛出异常。
maxWait=-1
#连接属性
#就是原来放在url后面的参数，可以使用connectionProperties来指定
#如果已经在url后面指定了，那么就不用在这里指定了。
#useServerPrepStmts=true，MySQL开启预编译功能
#cachePrepStmts=true，MySQL开启缓存PreparedStatement功能，
#prepStmtCacheSize=50，缓存PreparedStatement的上限
#prepStmtCacheSqlLimit=300，当SQL模板长度大于300时，就不再缓存它
connectionProperties=useUnicode=true;characterEncoding=UTF8;useServerPrepStmts=true;cachePrepStmts=true;prepStmtCacheSize=50;prepStmtCacheSqlLimit=300
#连接的默认提交方式
#默认值为true
defaultAutoCommit=true
#连接是否为只读连接
#Connection有一对方法：setReadOnly(boolean)和isReadOnly()
#如果是只读连接，那么你只能用这个连接来做查询
#指定连接为只读是为了优化！这个优化与并发事务相关！
#如果两个并发事务，对同一行记录做增、删、改操作，是不是一定要隔离它们啊？
#如果两个并发事务，对同一行记录只做查询操作，那么是不是就不用隔离它们了？
#如果没有指定这个属性值，那么是否为只读连接，这就由驱动自己来决定了。即Connection的实现类自己来决定！
defaultReadOnly=false
#指定事务的事务隔离级别
#可选值：NONE,READ_UNCOMMITTED, READ_COMMITTED, REPEATABLE_READ, SERIALIZABLE
#如果没有指定，那么由驱动中的Connection实现类自己来决定
defaultTransactionIsolation=REPEATABLE_READ

```

## 6. C3P0

###6.1 C3P0简介
C3P0也是开源免费的连接池！C3P0被很多人看好！

### 6.2 C3P0的使用
C3P0中池类是：ComboPooledDataSource。

```java
public void fun1() throws PropertyVetoException, SQLException {
  ComboPooledDataSource ds = new ComboPooledDataSource();
  ds.setJdbcUrl("jdbc:mysql://localhost:3306/mydb1");
  ds.setUser("root");
  ds.setPassword("123");
  ds.setDriverClass("com.mysql.jdbc.Driver");
  ds.setAcquireIncrement(5);
  ds.setInitialPoolSize(20);
  ds.setMinPoolSize(2);
  ds.setMaxPoolSize(50);
  Connection con = ds.getConnection();
  System.out.println(con);
  con.close();
}

```

配置文件要求：

- 文件名称：必须叫c3p0-config.xml
- 文件位置：必须在src下

c3p0也可以指定配置文件，而且配置文件可以是properties，也可骒xml的。
当然xml的高级一些了。但是c3p0的配置文件名必须为c3p0-config.xml，并且必须放在类路径下。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<c3p0-config>
	<default-config>
		<property name="jdbcUrl">jdbc:mysql://localhost:3306/mydb1</property>
		<property name="driverClass">com.mysql.jdbc.Driver</property>
		<property name="user">root</property>
		<property name="password">123</property>
		<property name="acquireIncrement">3</property>
		<property name="initialPoolSize">10</property>
		<property name="minPoolSize">2</property>
		<property name="maxPoolSize">10</property>
	</default-config>
	<named-config name="oracle-config">
		<property name="jdbcUrl">jdbc:mysql://localhost:3306/mydb1</property>
		<property name="driverClass">com.mysql.jdbc.Driver</property>
		<property name="user">root</property>
		<property name="password">123</property>
		<property name="acquireIncrement">3</property>
		<property name="initialPoolSize">10</property>
		<property name="minPoolSize">2</property>
		<property name="maxPoolSize">10</property>
	</named-config>
</c3p0-config>

```

c3p0的配置文件中可以配置多个连接信息，可以给每个配置起个名字，这样可以方便的通过配置名称来切换配置信息。
上面文件中默认配置为mysql的配置，名为oracle-config的配置也是mysql的配置，呵呵

```java

public void fun2() throws PropertyVetoException, SQLException {
  ComboPooledDataSource ds = new ComboPooledDataSource();
  Connection con = ds.getConnection();
  System.out.println(con);
  con.close();
}
public void fun2() throws PropertyVetoException, SQLException {
  ComboPooledDataSource ds = new ComboPooledDataSource("orcale-config");
  Connection con = ds.getConnection();
  System.out.println(con);
  con.close();
}

```

## 7. Tomcat配置连接池

### 7.1 Tomcat配置JNDI资源

JNDI（Java Naming and Directory Interface），Java命名和目录接口。
JNDI的作用就是：在服务器上配置资源，然后通过统一的方式来获取配置的资源

我们这里要配置的资源当然是连接池了，这样项目中就可以通过统一的方式来获取连接池对象了

下图是Tomcat文档提供的：

![](./images/jdbc/jdbc-database-jndi.png)


配置JNDI资源需要到<Context>元素中配置<Resource>子元素：

name：指定资源的名称，这个名称可以随便给，在获取资源时需要这个名称
factory：用来创建资源的工厂，这个值基本上是固定的，不用修改
type：资源的类型，我们要给出的类型当然是我们连接池的类型了
bar：表示资源的属性，如果资源存在名为bar的属性，那么就配置bar的值。
对于DBCP连接池而言，你需要配置的不是bar，因为它没有bar这个属性，而是应该去配置url、username等属性


```xml

<Context>  
  <Resource name="mydbcp"
			type="org.apache.tomcat.dbcp.dbcp.BasicDataSource"
			factory="org.apache.naming.factory.BeanFactory"
			username="root"
			password="123"
			driverClassName="com.mysql.jdbc.Driver"    
			url="jdbc:mysql://127.0.0.1/mydb1"
			maxIdle="3"
			maxWait="5000"
			maxActive="5"
			initialSize="3"/>
</Context>  
<Context>  
  <Resource name="myc3p0"
			type="com.mchange.v2.c3p0.ComboPooledDataSource"
			factory="org.apache.naming.factory.BeanFactory"
			user="root"
			password="123"
			classDriver="com.mysql.jdbc.Driver"    
			jdbcUrl="jdbc:mysql://127.0.0.1/mydb1"
			maxPoolSize="20"
			minPoolSize ="5"
			initialPoolSize="10"
			acquireIncrement="2"/>
</Context>

```

### 7.2 获取资源

配置资源的目的当然是为了获取资源了。只要你启动了Tomcat，那么就可以在项目中任何类中通过JNDI获取资源的方式来获取资源了

下图是Tomcat文档提供的，与上面Tomcat文档提供的配置资源是对应的。

![](./images/jdbc/jdbc-database-jndi-2.png)

获取资源：

Context：javax.naming.Context
InitialContext：javax.naming.InitialContext
lookup(String)：获取资源的方法，其中”java:comp/env”是资源的入口（这是固定的名称），
获取过来的还是一个Context，这说明需要在获取到的Context上进一步进行获取。
”bean/MyBeanFactory”对应<Resource>中配置的name值，这回获取的就是资源对象了


```java

ontext cxt = new InitialContext();
DataSource ds = (DataSource)cxt.lookup("java:/comp/env/mydbcp");
Connection con = ds.getConnection();
System.out.println(con);
con.close();
Context cxt = new InitialContext();
Context envCxt = (Context)cxt.lookup("java:/comp/env");
DataSource ds = (DataSource)env.lookup("mydbcp");
Connection con = ds.getConnection();
System.out.println(con);
con.close();

```

上面两种方式是相同的效果

### 7.3 修改JdbcUtils

因为已经学习了连接池，那么JdbcUtils的获取连接对象的方法也要修改一下了。

JdbcUtils.java

```java
public class JdbcUtils {
	private static DataSource dataSource = new ComboPooledDataSource();
	public static DataSource getDataSource() {
		return dataSource;
	}
	public static Connection getConnection() {
		try {
			return dataSource.getConnection();
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}
}

```

## 8. ThreadLocal
Thread ->人类
Runnable -> 任务类


key | value
---|---
thread1	| aaa
thread2	| bbb
thread3	| ccc

### 8.1 ThreadLocal API

ThreadLocal类只有三个方法

返回值 | 方法说明 | 功能描述
----|----|---
void | set(T value) | 保存值
T	 | get()	    | 获取值
void |	remove()    | 移除值

### 8.2 ThreadLocal的内部是Map
ThreadLocal内部其实是个Map来保存数据。
虽然在使用ThreadLocal时只给出了值，没有给出键，
其实它内部使用了当前线程做为键

```java

class MyThreadLocal<T> {
	private Map<Thread,T> map = new HashMap<Thread,T>();
	public void set(T value) {
		map.put(Thread.currentThread(), value);
	}
	public void remove() {
		map.remove(Thread.currentThread());
	}
	public T get() {
		return map.get(Thread.currentThread());
	}
}

```

## 9. BaseServlet

### 9.1 BaseServlet的作用
在开始客户管理系统之前，我们先写一个工具类：BaseServlet

我们知道，写一个项目可能会出现N多个Servlet，而且一般一个Servlet只有一个方法（doGet或doPost），
如果项目大一些，那么Servlet的数量就会很惊人

为了避免Servlet的“膨胀”，我们写一个BaseServlet。它的作用是让一个Servlet可以处理多种不同的请求。
不同的请求调用Servlet的不同方法。我们写好了BaseServlet后，
让其他Servlet继承BaseServlet，例如CustomerServlet继承BaseServlet，
然后在CustomerServlet中提供add()、update()、delete()等方法，每个方法对应不同的请求。



### 9.2 BaseServlet分析
我们知道，Servlet中处理请求的方法是service()方法，这说明我们需要让service()方法去调用其他方法。
例如调用add()、mod()、del()、all()等方法！具体调用哪个方法需要在请求中给出方法名称！
然后service()方法通过方法名称来调用指定的方法

无论是点击超链接，还是提交表单，请求中必须要有method参数，这个参数的值就是要请求的方法名称，
这样BaseServlet的service()才能通过方法名称来调用目标方法。例如某个链接如下：

> <a href=”/xxx/CustomerServlet?method=add”>添加客户</a>

### 9.3 BaseServlet代码

```java
public class BaseServlet extends HttpServlet {
	/*
	 * 它会根据请求中的m，来决定调用本类的哪个方法
	 */
	protected void service(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");
		res.setContentType("text/html;charset=utf-8");
		// 例如：http://localhost:8080/demo1/xxx?m=add
		String methodName = req.getParameter("method");// 它是一个方法名称
		// 当没用指定要调用的方法时，那么默认请求的是execute()方法。
		if(methodName == null || methodName.isEmpty()) {
			methodName = "execute";
		}
		Class c = this.getClass();
		try {
			// 通过方法名称获取方法的反射对象
			Method m = c.getMethod(methodName, HttpServletRequest.class,
					HttpServletResponse.class);
			// 反射方法目标方法，也就是说，如果methodName为add，那么就调用add方法。
			String result = (String) m.invoke(this, req, res);
			// 通过返回值完成请求转发
			if(result != null && !result.isEmpty()) {
				req.getRequestDispatcher(result).forward(req, res);
			}
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}
}

```
