
# JNDI原理


[转载](https://blog.csdn.net/wang_zhou_jian/article/details/5409209)


https://www.google.com/search?q=JNDI%E5%8E%9F%E7%90%86&oq=JNDI%E5%8E%9F%E7%90%86&aqs=chrome..69i57j69i61&sourceid=chrome&ie=UTF-8


### 运行机制： 

1、 首先程序代码获取初始化的 JNDI 环境并且调用 Context.lookup() 方法从 JNDI 服务提供者那里获一个 DataSource 对象

2、 中间层 JNDI 服务提供者返回一个 DataSource 对象给当前的 Java 应用程序这个 DataSource 对象代表了中间层服务上现存的缓冲数据源

3、 应用程序调用 DataSource 对象的 getConnection() 方法

4、 当 DataSource 对象的 getConnection() 方法被调用时，中间层服务器将查询数据库 连接缓冲池中有没有 PooledConnection 接口的实例对象。这个 PooledConnection 对象将被用于与数据库建立物理上的数据库连接

5、 如果在缓冲池中命中了一个 PooledCoonection 对象那么连接缓冲池将简单地更 新内部的缓冲连接队列并将该 PooledConnection 对象返回。如果在缓冲池内没 有找到现成的 PooledConnection 对象，那么 ConnectionPoolDataSource 接口将会被 用来产生一个新的 PooledConnection 对象并将它返回以便应用程序使用

6。 中间层服务器调用 PooledConnection 对象的 getConnection() 方法以便返还一个 java.sql.Connection 对象给当前的 Java 应用程序

7、 当中间层服务器调用 PooledConnection 对象的 getConnection() 方法时， JDBC 数据 库驱动程序将会创建一个 Connection 对象并且把它返回中间层服务器

8、 中间层服务器将 Connection 对象返回给应用程序 Java 应用程序，可以认为这个 Connection 对象是一个普通的 JDBC Connection 对象使用它可以和数据库建立。事 实上的连接与数据库引擎产生交互操作 。

9、 当应用程序不需要使用 Connection 对象时，可以调用 Connection 接口的 close() 方 法。请注意这种情况下 close() 方法并没有关闭事实上的数据库连接，仅仅是释 放了被应用程序占用的数据库连接，并将它还给数据库连接缓冲池，数据库连接 缓冲池会自动将这个数据库连接交给请求队列中下一个的应用程序使用。


<http://www.blogjava.net/ywj-316/archive/2010/02/23/313685.html>

### 什么是JNDI？为什么使用JNDI？

JNDI是Java 命名与目录接口（Java Naming and Directory Interface）

要了解JNDI的作用，我们可以从“如果不用JNDI我们怎样做？用了JNDI后我们又将怎样做？”这个问题来探讨。

#### 没有JNDI的做法：

程序员开发时，知道要开发访问MySQL数据库的应用，于是将一个对 MySQL JDBC 驱动程序类的引用进行了编码，
并通过使用适当的 JDBC URL 连接到数据库。
就像以下代码这样：

```java
Connection conn=null;
try { 
   Class.forName("com.mysql.jdbc.Driver",true, Thread.currentThread().getContextClassLoader());        
   conn=DriverManager.getConnection("jdbc:mysql://MyDBServer?user=qingfeng&password=mingyue");  
   /* 使用conn并进行SQL操作 */    
    conn.close();
} catch(Exception e) {
   e.printStackTrace();
} finally {
   if(conn!=null) {
    try {       conn.close();    
    } catch(SQLException e) {
    }
}}
```

这是传统的做法，这种做法一般在小规模的开发过程中不会产生问题，只要程序员熟悉Java语言、
了解JDBC技术和MySQL，可以很快开发出相应的应用程序。

##### 没有JNDI的做法存在的问题：
1、数据库服务器名称MyDBServer 、用户名和口令都可能需要改变，由此引发JDBC URL需要修改；\
2、数据库可能改用别的产品，如改用DB2或者Oracle，引发JDBC驱动程序包和类名需要修改；\
3、随着实际使用终端的增加，原配置的连接池参数可能需要调整；\
4、......

#### 解决办法：

程序员应该不需要关心“具体的数据库后台是什么？JDBC驱动程序是什么？JDBC URL格式是什么？
访问数据库的用户名和口令是什么？”等等这些问题，程序员编写的程序应该没有对 JDBC 驱动程序的引用，
没有服务器名称，没有用户名称或口令 —— 甚至没有数据库池或连接管理。而是把这些问题交给J2EE容器来配置和管理，
程序员只需要对这些配置和管理进行引用即可。

由此，就有了JNDI。

用了JNDI之后的做法：
首先，在在J2EE容器中配置JNDI参数，定义一个数据源，也就是JDBC引用参数，
给这个数据源设置一个名称；然后，在程序中，通过数据源名称引用数据源从而访问后台数据库.

#### 为什么会有jndi

jndi诞生的理由似乎很简单。随着分布式应用的发展，远程访问对象访问成为常用的方法。
虽然说通过 Socket等编程手段仍然可实现远程通信，但按照模式的理论来说，仍是有其局限性的。RMI技术，
RMI-IIOP技术的产生，使远程对象的查找成为了技术焦点。JNDI技术就应运而生。JNDI技术产生后，就可方便的查找远程或是本地对象。

JNDI的架构与实现

![](./images/jndi/jndi-1.jpeg)

JNDI的架构与JDBC的架构非常类似.JNDI架构提供了一组标准命名系统的API,
这些API在JDK1.3之前是作为一个单独的扩展包jndi.jar(通过这个地址下载),
这个基础API构建在与SPI之上。这个API提供如下五个包：
```
* javax.naming 
* javax.naming.directory 
* javax.naming.event 
* javax.naming.ldap 
* javax.naming.spi 
```
    
在应用程序中,我们实际上只使到用以上几个包的中类.具体调用类及通信过程对用户来说是透明的。
JNDI API提供了访问不同JNDI服务的一个标准的统一的实现,其具体实现可由不同的 Service Provider来完成。
前面讲的为第一层JNDI API层. 
最下层为JNDI SPI API及其具体实现。 

中间层为命名管理层。其功能应该由JNDI SPI来完成。上层为JNDI API,这个API包在Java 2 SDK 1.3及以上的版本中已经包括。 
前面讲解的只是作为应用程序客户端的架构实现,其服务端是由SPI对应的公司/厂商来实现的,
我们只需将服务端的相关参数传给JNDI API就可以了,具体调用过程由SPI来完成。

### JNDI原理
 
 sun只是提供了JNDI的接口(即规范),IBM, Novell, Sun 和 WebLogic 和JBOSS已经为 JNDI 提供了服务提供程序,

在JNDI中，在目录结构中的每一个结点称为context。每一个JNDI名字都是相对于context的。
这里没有绝对名字的概念存在。对一个应用来说，它可以通过使用 InitialContext 类来得到其第一个context: 

 Context ctx = new InitialContext();

 ctx.bind("name", Object);

 ctx.lookup("name");

Context:上下文,我的理解是相当与文件系统的中的目录(JNDI的Naming Service是可以用操作系统的文件系统的,哈哈).

entry/object:一个节点,相当与文件系统中的目录或文件.

filter:查询/过滤条件是一个字符串表达式如:(&(objectClass=top)(cn=*))查询出objectClass属性为top,cn属性为所有情况的entry.

Attribute:entry/object的属性可以理解成JAVA对象的属性,不同的是这个属性可以多次赋值.

A.将接口分为Context 和 DirContext  

JNDI有两个核心接口Context和DirContext，Context中包含 了基本的名字操作，而DirContext则将这些操作扩展到目录服务。DirContext 对Context进行了扩展，提供了基本的目录服务操作， 对名字对象属性的维护、基于属性的名字查找等等。  

B.上下文列表的多种方法  

一般来说有两种进行上下文列表的应用：上下文浏览应用和对上下文中的对象进行实际操作的应用。  

上下文浏览应用一般只需要显示上下文中包含内容的名字，或者再获取一些诸如对象的类型之类的信息。
这种类型的应用一般都是交互式的，可以允许用户在列举的上下文列表中选择一些进行进一步的显示。  

另外有一些应用需要对上下文中的对象进行实际的操作，比如，一个备份程序需要对目录中所有文件的状态进行操作，
或者某打印机管理员可能需要对大楼中的所有打印机进行复位。为了进行这样的操作，程序需要获取上下文中的实际对象。  

对于这样两种类型的应用，Context接口提供了两种上下文列表方法list()和 listBindings()。
其中list()只返回一系列名字/类映射，而listBindings() 则返回名字、类和对象本身。
显然 list()用于上下文浏览应用而listBindings()用于那些需要对对象进行实际操作的应用。

    
  
 
 可以把它理解为一种将对象和名字捆绑的技术，
对象工厂负责生产出对象，这些对象都和唯一的名字绑在一起，外部资源可以通过名字获得某对象的引用. 

类似于一个全局 map，key保存JNDI名字，value保存你放到里面的资源的引用，比如数据源啊什么的 


<http://haidaoqi3630.iteye.com/blog/2171454>


tomcat 下context.xml中 
```xml
<Resource driverClassName="com.mysql.jdbc.Driver" maxActive="10" 
maxIdle="2" maxWait="50" name="user" password="123456" 
type="javax.sql.DataSource" url="jdbc:mysql://ip:dataBase?characterEncoding=utf-8" 
username="root" />

```
 
同时你需要把你使用的数据驱动jar包放到Tomcat的lib目录下。 
如果你使用其他数据源如DBCP数据源，需要在Resouce 标签多添加一个属性如 
factory="org.apache.commons.dbcp.BasicDataSourceFactory" 
当然你也要把DBCP相关jar包放在tomcat的lib目录下,如果要直接用Tomcat提供的DBCP的Jar包，
需要将factorhy的属性改为 "org.apache.tomcat.dbcp.dbcp.BasicDataSourceFactory"。 

配置c3p0 连接池 
```xml
<Resource auth="Container" description="DB Connection" 
driverClass="com.mysql.jdbc.Driver" maxPoolSize="10" 
minPoolSize="2" acquireIncrement="2" name="jdbc/connPool" 
user="root" password="111111" factory="org.apache.naming.factory.BeanFactory" 
type="com.mchange.v2.c3p0.ComboPooledDataSource"
jdbcUrl="jdbc:mysql://localhost:3306/haixu?autoReconnect=true" /> 

```
配置druid连接池 
```xml

<Resource 
name="jdbc/rsglxt" 
factory="com.alibaba.druid.pool.DruidDataSourceFactory" 
auth="Container" 
type="javax.sql.DataSource" 
username="root" 
password="123456" 
maxActive="100" 
maxWait="10000" 
url="jdbc:mysql://localhost:3306/rsgl" 
/> 
```

<http://haidaoqi3630.iteye.com/blog/2171454>