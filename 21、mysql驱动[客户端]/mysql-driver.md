  
[转载](https://my.oschina.net/xianggao/blog/591482)



## 驱动加载原理全面解析

### 概述       

JDBC（Java Data Base Connectivity,java数据库连接).

JDBC是JAVA与数据的连接。因为ODBC是完全用C语言编写的，而JAVA中实现与C语言程序的通信是比较困难的，
因此就产生了由JAVA语言编写的用于JAVA程序与数据库连接的接口技术。
  
一般情况下，在应用程序中进行数据库连接，调用JDBC接口，首先要将特定厂商的JDBC驱动实现加载到系统内存中，
然后供系统使用。基本结构图如下：

![](./images/jdbc-1.png)


### 驱动加载入内存的过程

这里所谓的驱动，其实就是实现了java.sql.Driver接口的类。
如oracle的驱动类是 oracle.jdbc.driver.OracleDriver.class（此类可以在oracle提供的JDBC jar包中找到），
此类实现了java.sql.Driver接口。

由于驱动本质上还是一个class，将驱动加载到内存和加载普通的class原理是一样的:
使用Class.forName("driverName")。
以下是将常用的数据库驱动加载到内存中的代码：

```java

//加载Oracle数据库驱动  
Class.forName("oracle.jdbc.driver.OracleDriver");  
  
//加载SQL Server数据库驱动  
Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");  
  
//加载MySQL 数据库驱动  
Class.forName("com.mysql.jdbc.Driver");  

```

> 注意：Class.forName()将对应的驱动类加载到内存中，然后执行内存中的static静态代码段，代码段中，
会创建一个驱动Driver的实例，放入DriverManager中，供DriverManager使用。


例如，在使用Class.forName() 加载mysql 的驱动com.mysql.jdbc.Driver时，
会执行Driver中的静态代码段，创建一个Driver实例，
然后调用DriverManager.registerDriver()注册：

```java

public class Driver extends NonRegisteringDriver implements java.sql.Driver {
    //
    // Register ourselves with the DriverManager
    //
    static {
        try {
            java.sql.DriverManager.registerDriver(new Driver());
        } catch (SQLException E) {
            throw new RuntimeException("Can't register driver!");
        }
    }

    /**
     * Construct a new driver and register it with DriverManager
     * 
     * @throws SQLException
     *             if a database error occurs.
     */
    public Driver() throws SQLException {
        // Required for Class.forName().newInstance()
    }
}

```

### Driver的功能

java.sql.Driver接口规定了Driver应该具有以下功能：

![](./images/jdbc-2.png)

1.7 新增方法

```java

    //------------------------- JDBC 4.1 -----------------------------------
    /**
     * @since 1.7
     */
    public Logger getParentLogger() throws SQLFeatureNotSupportedException;

```

其中：

acceptsURL(String url) 方法用来测试对指定的url，该驱动能否打开这个url连接。

driver对自己能够连接的url会制定自己的协议，只有符合自己的协议形式的url才认为自己能够打开这个url，
如果能够打开，返回true，反之，返回false；


例如：mysql 定义自己的url 协议如下:

驱动程序包名：
> mysql-connector-java-x.x.xx-bin.jar

驱动程序类名: 
> com.mysql.cj.jdbc.Driver  \
（com.mysql.jdbc.Driver is deprecated） 

JDBC URL: jdbc:mysql://<host>:<port>/<database_name>

默认端口3306，如果服务器使用默认端口则port可以省略

MySQL Connector/J Driver 
允许在URL中添加额外的连接属性jdbc:mysql://<host>:<port>/<database_name>?property1=value1&property2=value2


例如：oracle定义的自己的url协议如下：

> jdbc:oracle:thin:@//<host>:<port>/ServiceName

> jdbc:oracle:thin:@<host>:<port>:<SID>

oracle自己的acceptsURL(String url)

mysql 方法如下：

```java

public class FabricMySQLDriver extends NonRegisteringDriver implements Driver {
    
    // 省略其他方法
    
   public boolean acceptsURL(String url) throws SQLException {
        return this.parseFabricURL(url, (Properties)null) != null;
    }

    Properties parseFabricURL(String url, Properties defaults) throws SQLException {
        return !url.startsWith("jdbc:mysql:fabric://") ? null : super.parseURL(url.replaceAll("fabric:", ""), defaults);
    }
}
        
    
```

由上可知mysql 定义了自己应该接收什么类型的URL，
自己能打开什么类型的URL连接（注意：这里acceptsURL(url)只会校验url是否符合协议，不会尝试连接判断url是否有效)

拓展阅读： [常用数据库 JDBC URL格式](https://blog.csdn.net/ring0hx/article/details/6152528)


### 手动加载驱动 Driver 并实例化进行数据库操作的例子

```java

public class MysqlDriverDemo {

    public static void main(String[] args) {

        try {
            //1.加载oracle驱动类，并实例化
            Driver driver = (Driver) Class.forName("com.mysql.cj.jdbc.Driver").newInstance();

            //2.判定指定的URL mysql驱动能否接受(符合mysql协议规则)
            boolean flag = driver.acceptsURL("jdbc:mysql://localhost:3306/mysql");
            //标准协议测试
            boolean standardFlag1 = driver.acceptsURL("jdbc:oracle:thin:@//<host>:<port>/ServiceName");
            boolean standardFlag2 = driver.acceptsURL("jdbc:oracle:thin:@<host>:<port>:<SID>");
            System.out.println("协议测试："+flag+"\t"+standardFlag1+"\t"+standardFlag2);

            //3.创建真实的数据库连接：
            String  url = "jdbc:mysql://localhost:3306/mysql";
            Properties props = new Properties();
            props.put("user", "root");
            props.put("password", "root");
            Connection connection = driver.connect(url, props);
            //connection 对象用于数据库交互，代码省略。。。。。

        } catch (Exception e) {
            System.out.println("加载Oracle类失败！");
            e.printStackTrace();
        } finally{

        }
    }
}

```

上述的手动加载Driver并且获取连接的过程稍显笨拙：如果现在我们加载进来了多个驱动Driver，那么手动创建Driver实例，
并根据URL进行创建连接就会显得代码杂乱无章，并且还容易出错，并且不方便管理。
JDBC中提供了一个DriverManager角色，用来管理这些驱动Driver。

### DriverManager角色

事实上，一般我们操作Driver，获取Connection对象都是交给DriverManager统一管理的。
DriverManger可以注册和删除加载的驱动程序，可以根据给定的url获取符合url协议的驱动Driver或者是建立Connection连接，
进行数据库交互。


![](./images/jdbc-3.png)


以下是DriverManager的关键方法摘要：

![](./images/jdbc-4.png)


DriverManager 内部持有这些注册进来的驱动 Driver，由于这些驱动都是 java.sql.Driver 类型，

那么怎样才能获得指定厂商的驱动Driver呢？答案就在于：

java.sql.Driver接口规定了厂商实现该接口，并且定义自己的URL协议。
厂商们实现的Driver接口通过acceptsURL(String url)来判断此url是否符合自己的协议，如果符合自己的协议，
则可以使用本驱动进行数据库连接操作，查询驱动程序是否认为它可以打开到给定 URL 的连接。

#### 使用DriverManager获取指定Driver

对于驱动加载后，如何获取指定的驱动程序呢？这里，DriverManager的静态方法getDriver(String url)可以通过传递给的URL，
返回可以打开此URL连接的Driver。
 
比如，我想获取 mysql 的数据库驱动，
只需要传递形如jdbc:mysql://host:port/database_name 的参数给DriverManager.getDriver(String url)即可：

例子：
```java
Driver mysqlDriver =DriverManager.getDriver("jdbc:mysql://host:port/database_name"); 

```
实际上，DriverManager.getDriver(String url)方法是根据传递过来的URL，遍历它维护的驱动Driver，
依次调用驱动的Driver的acceptsURL(url)，如果返回acceptsURL(url)返回true，则返回对应的Driver：

```java
  @CallerSensitive
 public static Driver getDriver(String url)
     throws SQLException {

     println("DriverManager.getDriver(\"" + url + "\")");

     ensureDriversInitialized();

     Class<?> callerClass = Reflection.getCallerClass();

     // Walk through the loaded registeredDrivers attempting to locate someone
     // who understands the given URL.
     for (DriverInfo aDriver : registeredDrivers) {
         // If the caller does not have permission to load the driver then
         // skip it.
         if (isDriverAllowed(aDriver.driver, callerClass)) {
             try {
                 if (aDriver.driver.acceptsURL(url)) {
                     // Success!
                     println("getDriver returning " + aDriver.driver.getClass().getName());
                 return (aDriver.driver);
                 }

             } catch(SQLException sqe) {
                 // Drop through and try the next driver.
             }
         } else {
             println("    skipping: " + aDriver.driver.getClass().getName());
         }

     }

     println("getDriver: no suitable driver");
     throw new SQLException("No suitable driver", "08001");
 }
     
 ```
   
如果这个url（jdbc:mysql://host:port/database_name） 写错了，在调用 acceptsURL 方法的时候，会做判断.

mysql 为例，验证的过程:

com.mysql.cj.jdbc.NonRegisteringDriver 类实现 java.sql.Driver 接口的 acceptsURL

```java
public class NonRegisteringDriver implements java.sql.Driver {
    
  public boolean acceptsURL(String url) throws SQLException {
        return (ConnectionUrl.acceptsUrl(url));
    }
}

```
mysql驱动的 ConnectionUrl 类调用 ConnectionUrlParser 类的 parseConnectionString 方法做了正则匹配。

```java
    /**
     * Splits the connection string in its main sections.
     */
    private void parseConnectionString() {
        String connString = this.baseConnectionString;
        Matcher matcher = CONNECTION_STRING_PTRN.matcher(connString);
        if (!matcher.matches()) {
            throw ExceptionFactory.createException(WrongArgumentException.class, Messages.getString("ConnectionString.1"));
        }
        this.scheme = decode(matcher.group("scheme"));
        this.authority = matcher.group("authority"); // Don't decode just yet.
        this.path = matcher.group("path") == null ? null : decode(matcher.group("path")).trim();
        this.query = matcher.group("query"); // Don't decode just yet.
    }
    
```

#### 使用DriverManager注册和取消注册驱动Driver

在本博文开始的 驱动加载的过程一节中，讨论了当使用Class.forName("driverName")加载驱动的时候，
会向DriverManager中注册一个Driver实例。以下代码将验证此说法：

```java
public static void defaultDriver(){  
    try {  
          
        String url = "jdbc:mysql://host:port/mysql";  
          
        //1.将Driver加载到内存中，然后执行其static静态代码，创建一个Driver实例注册到DriverManager中  
        Class.forName("com.mysql.cj.jdbc.Driver");  
        //取出对应的 mysql 驱动Driver  
        Driver driver  = DriverManager.getDriver(url);  
        System.out.println("加载类后，获取Driver对象："+driver);  
          
        //将driver从DriverManager中注销掉  
        DriverManager.deregisterDriver(driver);  
        //重新通过url从DriverManager中取Driver  
        driver  = DriverManager.getDriver(url);  
        System.out.println(driver);  
          
    } catch (Exception e) {  
        System.out.println("加载mysql类失败！");  
        e.printStackTrace();  
    } finally{  
          
    }  
}  

```

以上代码主要分以下几步：

1.首先是将  com.mysql.cj.jdbc.Driver 加载到内存中；

2.然后便调用DriverManager.getDriver()去取Driver实例；

3.将driver实例从DriverManager中注销掉；

4.尝试再取 对应url的Driver实例；

上述代码执行的结果如下：

```java

加载类后，获取Driver对象：com.mysql.cj.jdbc.Driver@2c7b84de
加载mysql类失败！
java.sql.SQLException: No suitable driver
	at java.sql.DriverManager.getDriver(DriverManager.java:315)
	at space.pankui.MysqlDriverDemo.defaultDriver(MysqlDriverDemo.java:87)
	at space.pankui.MysqlDriverDemo.main(MysqlDriverDemo.java:27)

Process finished with exit code 0

```

将上述的例子稍作变化，在注销掉了静态块创建的driver后，
往DriverManager注册一个自己创建的Driver对象实例(具体步骤请看注释)：

```java

 public void defaultDriver2() {
        try {

            String url = "jdbc:mysql://host:port/mysql";

            //1.将Driver加载到内存中，然后执行其static静态代码，创建一个OracleDriver实例注册到DriverManager中
            Driver dd = (Driver) Class.forName("com.mysql.cj.jdbc.Driver").newInstance();
            //2.取出对应的mysql 驱动Driver
            Driver driver = DriverManager.getDriver(url);
            System.out.println("加载类后，获取Driver对象：" + driver);

            //3. 将driver从DriverManager中注销掉
            DriverManager.deregisterDriver(driver);

            //4.此时DriverManager中已经没有了驱动Driver实例，将创建的dd注册到DriverManager中
            DriverManager.registerDriver(dd);

            //5.重新通过url从DriverManager中取Driver
            driver = DriverManager.getDriver(url);

            System.out.println("注销掉静态创建的Driver后，重新注册的Driver:    " + driver);
            System.out.println("driver和dd是否是同一对象：" + (driver == dd));
        } catch (Exception e) {
            System.out.println("加载Oracle类失败！");
            e.printStackTrace();
        } finally {

        }
    }
    
```
以下代码运行的结果：

```java
加载类后，获取Driver对象：com.mysql.cj.jdbc.Driver@2c7b84de
注销掉静态创建的Driver后，重新注册的Driver:    com.mysql.cj.jdbc.Driver@445b84c0
driver和dd是否是同一对象：true
```

以上代码先创建了一个Driver对象，在注销了DriverManager中由加载驱动过程中静态创建驱动之后，
注册到系统中，现在DriverManager中对应url返回的Driver 即是在代码中创建的Driver对象。

#### 使用DriverManager创建 Connection 连接对象

创建 Connection 连接对象，可以使用驱动Driver的 connect(url,props)，
也可以使用 DriverManager 提供的getConnection()方法，此方法通过url自动匹配对应的驱动Driver实例，
然后调用对应的connect方法返回Connection对象实例。

```java
Driver driver  = DriverManager.getDriver(url);  
Connection connection = driver.connect(url, props); 

```
上述代码等价于：

```java
Class.forName("com.mysql.cj.jdbc.Driver");  
Connection connection = DriverManager.getConnection(url, props);  
```


### DriverManager 初始化 jdbc 驱动

```java
  /**
     * Load the initial JDBC drivers by checking the System property
     * jdbc.properties and then use the {@code ServiceLoader} mechanism
     */
    static {
        loadInitialDrivers();
        println("JDBC DriverManager initialized");
    }
```

```java
  private static void loadInitialDrivers() {
        String drivers;
        try {
            drivers = AccessController.doPrivileged(new PrivilegedAction<String>() {
                public String run() {
                    return System.getProperty("jdbc.drivers");
                }
            });
        } catch (Exception ex) {
            drivers = null;
        }
      
        // 找到所有的拥有权限的java.sql.Driver的实现
        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {
                
                // 使用SPI的ServiceLoader来加载接口的实现  
                // https://github.com/pankui/study-notes/blob/master/java/java-spi.md
                ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
                //获取迭代器
                Iterator<Driver> driversIterator = loadedDrivers.iterator();

                try{
                    //遍历所有的驱动实现
                    while(driversIterator.hasNext()) {
                        driversIterator.next();
                    }
                } catch(Throwable t) {
                // Do nothing
                }
                return null;
            }
        });

        println("DriverManager.initialize: jdbc.drivers = " + drivers);

        if (drivers == null || drivers.equals("")) {
            return;
        }
        String[] driversList = drivers.split(":");
        println("number of Drivers:" + driversList.length);
        for (String aDriver : driversList) {
            try {
                println("DriverManager.Initialize: loading " + aDriver);
                Class.forName(aDriver, true,
                        ClassLoader.getSystemClassLoader());
            } catch (Exception ex) {
                println("DriverManager.Initialize: load failed: " + ex);
            }
        }
    }


```
jdbc.drivers

DriverManager 作为 Driver 的管理器，它在第一次被使用的过程中（即在代码中第一次用到的时候），
它会被加载到内存中，然后执行其定义的 DriverManager 构造方法，在构造方法中，
有一个 方法，用于加载配置在jdbc.drivers 系统属性内的驱动Driver，
配置在jdbc.drivers 中的驱动driver将会首先被加载

```java
private static final String JDBC_DRIVERS_PROPERTY = "jdbc.drivers";

    @CallerSensitive
    public static Driver getDriver(String url)
        throws SQLException {
    
        println("DriverManager.getDriver(\"" + url + "\")");
    
        // //加载配置在jdbc.drivers系统变量中的驱动driver 
        ensureDriversInitialized();
        
     }   

```
调用下面的方法

```java
 
    /*
     * Load the initial JDBC drivers by checking the System property
     * jdbc.drivers and then use the {@code ServiceLoader} mechanism
     */
    private static void ensureDriversInitialized() {
        if (driversInitialized) {
            return;
        }

        synchronized (lockForInitDrivers) {
            if (driversInitialized) {
                return;
            }
            String drivers;
            try {
                // 得到系统属性jdbc.drivers对应驱动的驱动名称
                drivers = AccessController.doPrivileged(new PrivilegedAction<String>() {
                    public String run() {
                        
                        //返回jdbc.drivers值  
                        return System.getProperty(JDBC_DRIVERS_PROPERTY);
                    }
                });
            } catch (Exception ex) {
                drivers = null;
            }
          
            AccessController.doPrivileged(new PrivilegedAction<Void>() {
                public Void run() {

                    ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
                    Iterator<Driver> driversIterator = loadedDrivers.iterator();

                    try {
                        while (driversIterator.hasNext()) {
                            driversIterator.next();
                        }
                    } catch (Throwable t) {
                        // Do nothing
                    }
                    return null;
                }
            });

            println("DriverManager.initialize: jdbc.drivers = " + drivers);

            if (drivers != null && !drivers.equals("")) {
                String[] driversList = drivers.split(":");
                println("number of Drivers:" + driversList.length);
                for (String aDriver : driversList) {
                    try {
                        
                        //Class.forName加载对应的driver  
                        println("DriverManager.Initialize: loading " + aDriver);
                        Class.forName(aDriver, true,
                                ClassLoader.getSystemClassLoader());
                    } catch (Exception ex) {
                        println("DriverManager.Initialize: load failed: " + ex);
                    }
                }
            }

            driversInitialized = true;
            println("JDBC DriverManager initialized");
        }
    }
  

```

这里面涉及了SPI，这也导致了我们根本就可以不使用Class.forName装载驱动。 哦对了，JDBC4.0以后是这样的。


### 建立与 mysql 服务器连接 

ConnectionImpl 类 创建连接


创建io流，在调用这个方法的时候传的参数是false

```java

/**
 * Creates an IO channel to the server
 * 
 * @param isForReconnect
 *            is this request for a re-connect
 * @throws CommunicationsException
 */
public void createNewIO(boolean isForReconnect) {
    synchronized (getConnectionMutex()) {
        // Synchronization Not needed for *new* connections, but defintely for connections going through fail-over, since we might get the new connection up
        // and running *enough* to start sending cached or still-open server-side prepared statements over to the backend before we get a chance to
        // re-prepare them...

        try {
            if (!this.autoReconnect.getValue()) {
                //调用创建连接
                connectOneTryOnly(isForReconnect);

                return;
            }

            // 调用方法尝试多次链接
            connectWithRetries(isForReconnect);
        } catch (SQLException ex) {
            throw ExceptionFactory.createException(UnableToConnectException.class, ex.getMessage(), ex);
        }
    }
}
    
```

调用ConnectionImpl 类的 connectWithRetries方法进行多次的尝试链接：

```java
private void connectWithRetries(boolean isForReconnect) throws SQLException {
    double timeout = this.propertySet.getIntegerReadableProperty(PropertyDefinitions.PNAME_initialTimeout).getValue();
    boolean connectionGood = false;

    Exception connectionException = null;

    // 在没有获的链接的情况下尝试链接多次，知道最大尝试次数
    for (int attemptCount = 0; (attemptCount < this.propertySet.getIntegerReadableProperty(PropertyDefinitions.PNAME_maxReconnects).getValue())
            && !connectionGood; attemptCount++) {
        try {
            this.session.forceClose();

            JdbcConnection c = getProxy();
            
            // 调用这个方法进行链接获取
            this.session.connect(this.origHostInfo, this.user, this.password, this.database, DriverManager.getLoginTimeout() * 1000, c);
            pingInternal(false, 0);

            boolean oldAutoCommit;
            int oldIsolationLevel;
            boolean oldReadOnly;
            String oldCatalog;

            synchronized (getConnectionMutex()) {
                // save state from old connection
                oldAutoCommit = getAutoCommit();
                oldIsolationLevel = this.isolationLevel;
                oldReadOnly = isReadOnly(false);
                oldCatalog = getCatalog();

                this.session.setQueryInterceptors(this.queryInterceptors);
            }

            // Server properties might be different from previous connection, so initialize again...
            initializePropsFromServer();

            if (isForReconnect) {
                // Restore state from old connection
                setAutoCommit(oldAutoCommit);
                setTransactionIsolation(oldIsolationLevel);
                setCatalog(oldCatalog);
                setReadOnly(oldReadOnly);
            }

            connectionGood = true;

            break;
        } catch (UnableToConnectException rejEx) {
            close();
            this.session.getProtocol().getSocketConnection().forceClose();

        } catch (Exception EEE) {
            connectionException = EEE;
            connectionGood = false;
        }

        if (connectionGood) {
            break;
        }

        if (attemptCount > 0) {
            try {
                Thread.sleep((long) timeout * 1000);
            } catch (InterruptedException IE) {
                // ignore
            }
        }
    } // end attempts for a single host

    if (!connectionGood) {
        // We've really failed!
        SQLException chainedEx = SQLError.createSQLException(
                Messages.getString("Connection.UnableToConnectWithRetries",
                        new Object[] { this.propertySet.getIntegerReadableProperty(PropertyDefinitions.PNAME_maxReconnects).getValue() }),
                MysqlErrorNumbers.SQL_STATE_UNABLE_TO_CONNECT_TO_DATASOURCE, connectionException, getExceptionInterceptor());
        throw chainedEx;
    }

    if (this.propertySet.getBooleanReadableProperty(PropertyDefinitions.PNAME_paranoid).getValue() && !this.autoReconnect.getValue()) {
        this.password = null;
        this.user = null;
    }

    if (isForReconnect) {
        //
        // Retrieve any 'lost' prepared statements if re-connecting
        //
        Iterator<JdbcStatement> statementIter = this.openStatements.iterator();

        //
        // We build a list of these outside the map of open statements, because in the process of re-preparing, we might end up having to close a prepared
        // statement, thus removing it from the map, and generating a ConcurrentModificationException
        //
        Stack<JdbcStatement> serverPreparedStatements = null;

        while (statementIter.hasNext()) {
            JdbcStatement statementObj = statementIter.next();

            if (statementObj instanceof ServerPreparedStatement) {
                if (serverPreparedStatements == null) {
                    serverPreparedStatements = new Stack<>();
                }

                serverPreparedStatements.add(statementObj);
            }
        }

        if (serverPreparedStatements != null) {
            while (!serverPreparedStatements.isEmpty()) {
                ((ServerPreparedStatement) serverPreparedStatements.pop()).rePrepare();
            }
        }
    }
}

```
ConnectionImpl类中获取链接I/O流的核心代码：

connectOneTryOnly 方法（简化版）

```java
 private void connectOneTryOnly(boolean isForReconnect) throws SQLException {
        Exception connectionNotEstablishedBecause = null;

            JdbcConnection c = getProxy();
            
            // 这里很重要!!!
            // 去创建 socket 连接
            this.session.connect(this.origHostInfo, this.user, this.password, this.database, DriverManager.getLoginTimeout() * 1000, c);

            // save state from old connection
            boolean oldAutoCommit = getAutoCommit();
            int oldIsolationLevel = this.isolationLevel;
            boolean oldReadOnly = isReadOnly(false);
            String oldCatalog = getCatalog();

            this.session.setQueryInterceptors(this.queryInterceptors);

            // Server properties might be different from previous connection, so initialize again...
            initializePropsFromServer();

            if (isForReconnect) {
                // Restore state from old connection
                setAutoCommit(oldAutoCommit);
                setTransactionIsolation(oldIsolationLevel);
                setCatalog(oldCatalog);
                setReadOnly(oldReadOnly);
            }
            return;
    }
```
NativeSession 类的方法  connect
```java

public void connect(HostInfo hi, String user, String password, String database, int loginTimeout, TransactionEventHandler transactionManager)
            throws IOException {

        this.hostInfo = hi;

        // reset max-rows to default value
        this.setSessionMaxRows(-1);

        // TODO do we need different types of physical connections?
        SocketConnection socketConnection = new NativeSocketConnection();
        
        // 调用 socket 连接
        socketConnection.connect(this.hostInfo.getHost(), this.hostInfo.getPort(), this.propertySet, getExceptionInterceptor(), this.log, loginTimeout);

        // we use physical connection to create a -> protocol
        // this configuration places no knowledge of protocol or session on physical connection.
        // physical connection is responsible *only* for I/O streams
        if (this.protocol == null) {
            this.protocol = NativeProtocol.getInstance(this, socketConnection, this.propertySet, this.log, transactionManager);
        } else {
            this.protocol.init(this, socketConnection, this.propertySet, transactionManager);
        }

        // use protocol to create a -> session
        // protocol is responsible for building a session and authenticating (using AuthenticationProvider) internally
        this.protocol.connect(user, password, database);

        // error messages are returned according to character_set_results which, at this point, is set from the response packet
        this.protocol.getServerSession().setErrorMessageEncoding(this.protocol.getAuthenticationProvider().getEncodingForHandshake());

        this.isClosed = false;
    }
    
```

NativeSocketConnection 类

```java
public class NativeSocketConnection extends AbstractSocketConnection implements SocketConnection {

    @Override
    public void connect(String hostName, int portNumber, PropertySet propSet, ExceptionInterceptor excInterceptor, Log log, int loginTimeout) {

        // TODO we don't need both Properties and PropertySet in method params

        try {
            this.port = portNumber;
            this.host = hostName;
            this.propertySet = propSet;
            this.exceptionInterceptor = excInterceptor;

            // 创建工厂
            this.socketFactory = createSocketFactory(propSet.getStringReadableProperty(PropertyDefinitions.PNAME_socketFactory).getStringValue());
            // 获取连接
            //  驱动使用SocketFactory接口完成Socket的创建与连接， 实现是com.mysql.jdbc.StandardSocketFactory.
            this.mysqlSocket = this.socketFactory.connect(this.host, this.port, propSet.exposeAsProperties(), loginTimeout);

            int socketTimeout = propSet.getIntegerReadableProperty(PropertyDefinitions.PNAME_socketTimeout).getValue();
            if (socketTimeout != 0) {
                try {
                    this.mysqlSocket.setSoTimeout(socketTimeout);
                } catch (Exception ex) {
                    /* Ignore if the platform does not support it */
                }
            }

            this.socketFactory.beforeHandshake();

            InputStream rawInputStream;
            if (propSet.getBooleanReadableProperty(PropertyDefinitions.PNAME_useReadAheadInput).getValue()) {
                rawInputStream = new ReadAheadInputStream(this.mysqlSocket.getInputStream(), 16384,
                        propSet.getBooleanReadableProperty(PropertyDefinitions.PNAME_traceProtocol).getValue(), log);
            } else if (propSet.getBooleanReadableProperty(PropertyDefinitions.PNAME_useUnbufferedInput).getValue()) {
                rawInputStream = this.mysqlSocket.getInputStream();
            } else {
                rawInputStream = new BufferedInputStream(this.mysqlSocket.getInputStream(), 16384);
            }

            this.mysqlInput = new FullReadInputStream(rawInputStream);
            this.mysqlOutput = new BufferedOutputStream(this.mysqlSocket.getOutputStream(), 16384);
        } catch (IOException ioEx) {
            throw ExceptionFactory.createCommunicationsException(propSet, null, 0, 0, ioEx, getExceptionInterceptor());
        }
    }

```
StandardSocketFactory 类

connect方法实现 创建Socket，并将连接到给定的地址。

```java

public <T extends Closeable> T connect(String hostname, int portNumber, Properties props, int loginTimeout) throws IOException {

        this.loginTimeoutCountdown = loginTimeout;

        if (props != null) {
            this.host = hostname;

            this.port = portNumber;

            String localSocketHostname = props.getProperty(PropertyDefinitions.PNAME_localSocketAddress);
            InetSocketAddress localSockAddr = null;
            if (localSocketHostname != null && localSocketHostname.length() > 0) {
                localSockAddr = new InetSocketAddress(InetAddress.getByName(localSocketHostname), 0);
            }

            String connectTimeoutStr = props.getProperty(PropertyDefinitions.PNAME_connectTimeout);

            int connectTimeout = 0;

            if (connectTimeoutStr != null) {
                try {
                    connectTimeout = Integer.parseInt(connectTimeoutStr);
                } catch (NumberFormatException nfe) {
                    throw new SocketException("Illegal value '" + connectTimeoutStr + "' for connectTimeout");
                }
            }

            // InetAddress.getAllByName方法将会返回给定的hostname的所有的IP地址
            if (this.host != null) {
                InetAddress[] possibleAddresses = InetAddress.getAllByName(this.host);

                if (possibleAddresses.length == 0) {
                    throw new SocketException("No addresses for host");
                }

                // save last exception to propagate to caller if connection fails
                SocketException lastException = null;

                // Need to loop through all possible addresses. Name lookup may return multiple addresses including IPv4 and IPv6 addresses. Some versions of
                // MySQL don't listen on the IPv6 address so we try all addresses.
                // 遍历所有可能的地址，找到就直接停止
                for (int i = 0; i < possibleAddresses.length; i++) {
                    try {
                        
                        // 创建一个人socket 
                        this.rawSocket = createSocket(props);

                        configureSocket(this.rawSocket, props);

                        InetSocketAddress sockAddr = new InetSocketAddress(possibleAddresses[i], this.port);
                        // bind to the local port if not using the ephemeral port
                        if (localSockAddr != null) {
                            this.rawSocket.bind(localSockAddr);
                        }

                        this.rawSocket.connect(sockAddr, getRealTimeout(connectTimeout));
                        // 找到了就直接停止，否则抛异常，这里抓取 直接处理了。
                        break;
                    } catch (SocketException ex) {
                        lastException = ex;
                        resetLoginTimeCountdown();
                        this.rawSocket = null;
                    }
                }

                if (this.rawSocket == null && lastException != null) {
                    throw lastException;
                }

                resetLoginTimeCountdown();

                this.sslSocket = this.rawSocket;
                return (T) this.rawSocket;
            }
        }

        throw new SocketException("Unable to create socket");
    }
    
    
```
socket 工厂使用 创建 socket 连接使用 SOCK 代理.

```java
/**
 * A socket factory used to create sockets connecting through a SOCKS proxy. The socket still supports all the same TCP features as the "standard" socket.
 */
public class SocksProxySocketFactory extends StandardSocketFactory {
    public static int SOCKS_DEFAULT_PORT = 1080;

    @Override
    protected Socket createSocket(Properties props) {
        String socksProxyHost = props.getProperty(PropertyDefinitions.PNAME_socksProxyHost);
        String socksProxyPortString = props.getProperty(PropertyDefinitions.PNAME_socksProxyPort, String.valueOf(SOCKS_DEFAULT_PORT));
        int socksProxyPort = SOCKS_DEFAULT_PORT;
        try {
            socksProxyPort = Integer.valueOf(socksProxyPortString);
        } catch (NumberFormatException ex) {
            // ignore. fall back to default
        }

        return new Socket(new Proxy(Proxy.Type.SOCKS, new InetSocketAddress(socksProxyHost, socksProxyPort)));
    }
}

到这里发现通过mysql 实现驱动的加载获取 驱动类实例后通过各种判断最终就是获取了指定IP,PORT的socket 的获取。
获得Socket链接后我们也就获的了和mysql server的链接。

```

[参考](https://blog.csdn.net/QH_JAVA/article/details/50390038)
[参考](https://github.com/seaswalker/mysql-driver/blob/master/note/connect.md#toc13)


mysql 驱动与mysql 服务器建立连接就完了。


---


以下是通过jdbc.drivers加载驱动driver的方式：

```java

 String url = "jdbc:mysql://host:port/mysql";

//设置值系统变量jdbc.drivers  
System.setProperty("jdbc.drivers", "com.mysql.cj.jdbc.Driver");  
//2.通过特定的url获取driver  
Driver driver = DriverManager.getDriver(url);  
//打印是否存在  
System.out.println(driver);  

```

DriverManager同时管理着oracle和mysql两个驱动。
那我们会产生疑问DriverManager到底是如果多个管理驱动的，
怎么样根据我们的连接配置信息（url，密码...)获取到对应的连接？

驱动的管理或者说记录是封装成DriverInfo后放到CopyOnWriteArrayList，
是一个线程安全的ArrayList。
 
```java
private final static CopyOnWriteArrayList<DriverInfo> registeredDrivers = new CopyOnWriteArrayList<>();
```

当我们要获取连接的时候，再遍历registeredDrivers这个列表，然后使用列表中的驱动尝试连接，
当获取到连接以后就停止遍历，然后返回connection
 

```java

    //  Worker method called by the public getConnection() methods.
    private static Connection getConnection(
        String url, java.util.Properties info, Class<?> caller) throws SQLException {
        
        ClassLoader callerCL = caller != null ? caller.getClassLoader() : null;
        if (callerCL == null) {
            callerCL = Thread.currentThread().getContextClassLoader();
        }

        if (url == null) {
            throw new SQLException("The url cannot be null", "08001");
        }

        println("DriverManager.getConnection(\"" + url + "\")");

        ensureDriversInitialized();

        // Walk through the loaded registeredDrivers attempting to make a connection.
        // Remember the first exception that gets raised so we can reraise it.
        SQLException reason = null;

        // 遍历驱动注册列表
        for (DriverInfo aDriver : registeredDrivers) {
            // If the caller does not have permission to load the driver then
            // skip it.
             
            // 判断是否能使用该驱动
            if (isDriverAllowed(aDriver.driver, callerCL)) {
                try {
                    println("    trying " + aDriver.driver.getClass().getName());
                    //得到连接
                    Connection con = aDriver.driver.connect(url, info);
                    if (con != null) {
                        // Success!
                        println("getConnection returning " + aDriver.driver.getClass().getName());
                        return (con);
                    }
                } catch (SQLException ex) {
                    if (reason == null) {
                        reason = ex;
                    }
                }

            } else {
                println("    skipping: " + aDriver.getClass().getName());
            }

        }

        // if we got here nobody could connect.
        if (reason != null)    {
            println("getConnection failed: " + reason);
            throw reason;
        }

        println("getConnection: no suitable driver found for "+ url);
        throw new SQLException("No suitable driver found for "+ url, "08001");
    }

``` 



### mysql 驱动 执行 SQL 语句，参数，返回结果 

 

2.驱动怎么传输数据与接收数据



3.数据库服务器验证客户端