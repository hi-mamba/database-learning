package space.pankui;

import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Enumeration;
import java.util.Properties;

/**
 * @author pankui
 * @date 12/05/2018
 * <pre>
 *
 *     ConnectionImpl
 *
 *  SocketFactory  与 socket 连接
 *
 * </pre>
 */
public class MysqlDriverDemo {

    public static void main(String[] args) throws Exception {

        MysqlDriverDemo mysqlDriverDemo = new MysqlDriverDemo();
        mysqlDriverDemo.mysqlDriverDemo001();
        mysqlDriverDemo.driverManager();


        System.out.println("===============");

     //   mysqlDriverDemo.defaultDriver();

        System.out.println("##########");
        mysqlDriverDemo.defaultDriver2();

        System.out.println("############## ");

        mysqlDriverDemo.getConnect();

    }

    private void mysqlDriverDemo001() {

        try {
            //1.加载oracle驱动类，并实例化
            // 1、加载驱动，不加载驱动依然正常可以连接  见 driverManager() 方法
            Driver driver = (Driver) Class.forName("com.mysql.cj.jdbc.Driver").newInstance();

            //2.判定指定的URL mysql驱动能否接受(符合mysql协议规则)
            boolean flag = driver.acceptsURL("jdbc:mysql://localhost:3306/mysql");
            //标准协议测试
            boolean standardFlag1 = driver.acceptsURL("jdbc:oracle:thin:@//<host>:<port>/ServiceName");
            boolean standardFlag2 = driver.acceptsURL("jdbc:oracle:thin:@<host>:<port>:<SID>");
            System.out.println("协议测试：" + flag + "\t" + standardFlag1 + "\t" + standardFlag2);

            //3.创建真实的数据库连接：
            String url = "jdbc:mysql://localhost:3306/mysql";
            Properties props = new Properties();
            props.put("user", "root");
            props.put("password", "root");
            Connection connection = driver.connect(url, props);
            //connection 对象用于数据库交互，代码省略。。。。。

        } catch (Exception e) {
            System.out.println("加载Oracle类失败！");
            e.printStackTrace();
        } finally {

        }
    }

    private void driverManager() throws SQLException {
        /**
         * ps:如果这个url 写错了，在调用 acceptsURL 方法的时候，会做判断.
         *
         * mysql  ConnectionUrlParser 类 parseConnectionString 做了正则匹配
         *
         * */
        Driver mysqlDriver = (Driver) DriverManager.getDriver("jdbc:mysql://localhost:3306/mysql");

        System.out.println(" mysqlDriver: " + mysqlDriver);
    }


    public void defaultDriver() {
        try {

            String url = "jdbc:mysql://host:port/mysql";

            //1.将Driver加载到内存中，然后执行其static静态代码，创建一个Driver实例注册到DriverManager中
            // 1、加载驱动，不加载驱动依然正常可以连接  见 driverManager() 方法
            Class.forName("com.mysql.cj.jdbc.Driver");
            //取出对应的 mysql 驱动Driver
            Driver driver = DriverManager.getDriver(url);
            System.out.println("加载类后，获取Driver对象：" + driver);

            //将driver从DriverManager中注销掉
            DriverManager.deregisterDriver(driver);
            //重新通过url从DriverManager中取Driver
            driver = DriverManager.getDriver(url);
            System.out.println(driver);

        } catch (Exception e) {
            System.out.println("加载mysql类失败！");
            e.printStackTrace();
        } finally {

        }
    }

    /**
     * 将上述的例子稍作变化，在注销掉了静态块创建的driver后，
     * 往DriverManager注册一个自己创建的Driver对象实例(具体步骤请看注释)：
     */
    public void defaultDriver2() {
        try {

            String url = "jdbc:mysql://host:port/mysql";

            //1.将Driver加载到内存中，然后执行其static静态代码，创建一个OracleDriver实例注册到DriverManager中
            // 1、加载驱动，不加载驱动依然正常可以连接  见 driverManager() 方法
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

    private void getConnect () {

        // 查看已经加载的driver
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        System.out.println("------加载的diver--------");
        while(drivers.hasMoreElements()) {
            System.out.println(drivers.nextElement().getClass().getName());
        }

    }

}
