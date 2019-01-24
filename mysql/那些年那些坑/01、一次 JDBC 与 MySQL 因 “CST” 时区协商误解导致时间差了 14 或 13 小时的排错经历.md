

## [原文](https://juejin.im/post/5902e087da2f60005df05c3d)

# 一次 JDBC 与 MySQL 因 “CST” 时区协商误解导致时间差了 14 或 13 小时的排错经历

## 摘要
名为 CST 的时区是一个很混乱的时区，在与 MySQL 协商会话时区时，
Java 会误以为是 CST -0500，而非 CST +0800。

## CST 时区
名为 CST 的时区是一个很混乱的时区，有四种含义：
```

美国中部时间 Central Standard Time (USA) UTC-06:00 
澳大利亚中部时间 Central Standard Time (Australia) UTC+09:30 
中国标准时 China Standard Time UTC+08:00 
古巴标准时 Cuba Standard Time UTC-04:00

```

今天是“4月28日”。为什么提到日期？因为美国从“3月11日”至“11月7日”实行夏令时，
美国中部时间改为 UTC-05:00，与 UTC+08:00 相差 13 小时。

## 排错过程
在项目中，偶然发现数据库中存储的 Timestamp 字段的 unix_timestamp() 值比真实值少了 13 个小时。
通过调试追踪，发现了 com.mysql.cj.jdbc 里的时区协商有问题。

当 JDBC 与 MySQL 开始建立连接时，会调用 com.mysql.cj.jdbc.ConnectionImpl.initializePropsFromServer() 获取服务器参数，
其中我们看到调用 this.session.configureTimezone() 函数，它负责配置时区。
```java
public void configureTimezone() {
    String configuredTimeZoneOnServer = getServerVariable("time_zone");

    if ("SYSTEM".equalsIgnoreCase(configuredTimeZoneOnServer)) {
        configuredTimeZoneOnServer = getServerVariable("system_time_zone");
    }

    String canonicalTimezone = getPropertySet().getStringReadableProperty(PropertyDefinitions.PNAME_serverTimezone).getValue();

    if (configuredTimeZoneOnServer != null) {
        // user can override this with driver properties, so don't detect if that's the case
        if (canonicalTimezone == null || StringUtils.isEmptyOrWhitespaceOnly(canonicalTimezone)) {
            try {
                canonicalTimezone = TimeUtil.getCanonicalTimezone(configuredTimeZoneOnServer, getExceptionInterceptor());
            } catch (IllegalArgumentException iae) {
                throw ExceptionFactory.createException(WrongArgumentException.class, iae.getMessage(), getExceptionInterceptor());
            }
        }
    }

    if (canonicalTimezone != null && canonicalTimezone.length() > 0) {
        this.serverTimezoneTZ = TimeZone.getTimeZone(canonicalTimezone);

        // The Calendar class has the behavior of mapping unknown timezones to 'GMT' instead of throwing an exception, so we must check for this...
        if (!canonicalTimezone.equalsIgnoreCase("GMT")
            && this.serverTimezoneTZ.getID().equals("GMT")) {
            throw ...
        }
    }

    this.defaultTimeZone = this.serverTimezoneTZ;
}
```
追踪代码可知，当 MySQL 的 time_zone 值为 SYSTEM 时，会取 system_time_zone 值作为协调时区。

让我们登录到 MySQL 服务器验证这两个值：
```mysql
mysql> show variables like '%time_zone%';
+------------------+--------+
| Variable_name    | Value  |
+------------------+--------+
| system_time_zone | CST    |
| time_zone        | SYSTEM |
+------------------+--------+
2 rows in set (0.00 sec)
```

重点在这里！若 String configuredTimeZoneOnServer 得到的是 CST 那么 Java 会误以为这是 CST -0500，
因此 TimeZone.getTimeZone(canonicalTimezone) 会给出错误的时区信息。

[](../../images/mysql/jdbc/timezone_qa.png)

如图所示，本机默认时区是 Asia/Shanghai +0800，误认为服务器时区为 CST -0500，实际上服务器是 CST +0800。

我们会想到，即便时区有误解，如果 Timestamp 是以 long 表示的时间戳传输，也不会出现问题，

下面让我们追踪到 com.mysql.cj.jdbc.PreparedStatement.setTimestamp()。
```java
public void setTimestamp(int parameterIndex, Timestamp x) throws java.sql.SQLException {
    synchronized (checkClosed().getConnectionMutex()) {
        setTimestampInternal(parameterIndex, x, this.session.getDefaultTimeZone());
    }
}

```

注意到这里 this.session.getDefaultTimeZone() 得到的是刚才那个 CST -0500。
```java
private void setTimestampInternal(int parameterIndex, Timestamp x, TimeZone tz) throws SQLException {
    if (x == null) {
        setNull(parameterIndex, MysqlType.TIMESTAMP);
    } else {
        if (!this.sendFractionalSeconds.getValue()) {
            x = TimeUtil.truncateFractionalSeconds(x);
        }

        this.parameterTypes[parameterIndex - 1 + getParameterIndexOffset()] = MysqlType.TIMESTAMP;

        if (this.tsdf == null) {
            this.tsdf = new SimpleDateFormat("''yyyy-MM-dd HH:mm:ss", Locale.US);
        }

        this.tsdf.setTimeZone(tz);

        StringBuffer buf = new StringBuffer();
        buf.append(this.tsdf.format(x));
        if (this.session.serverSupportsFracSecs()) {
            buf.append('.');
            buf.append(TimeUtil.formatNanos(x.getNanos(), true));
        }
        buf.append('\'');

        setInternal(parameterIndex, buf.toString());
    }
}

```
原来 Timestamp 被转换为会话时区的时间字符串了。问题到此已然明晰：
```
JDBC 误认为会话时区在 CST-5
JBDC 把 Timestamp+0 转为 CST-5 的 String-5
MySQL 认为会话时区在 CST+8，将 String-5 转为 Timestamp-13
```
最终结果相差 13 个小时！如果处在冬令时还会相差 14 个小时！

## 解决方案

### 解决办法一
解决办法也很简单，明确指定 MySQL 数据库的时区，不使用引发误解的 CST：
```mysql
mysql> set global time_zone = '+08:00';
Query OK, 0 rows affected (0.00 sec)

mysql> set time_zone = '+08:00';
Query OK, 0 rows affected (0.00 sec)
```
或者修改 my.cnf 文件，在 [mysqld] 节下增加 default-time-zone = '+08:00'。
修改时区操作影响深远，需要重启 MySQL 服务器，建议在维护时间进行。

### 解决办法二

把mysql 驱动降级

经测试这个在 mysql-connect-java版本 6.0.6以上有此问题.

在5.1.37/5.1.38/5.1.39中没有这个问题.

如上,修改有问题版本的驱动为上面所说的没有问题的版本.

### 解决办法三  
在 JDBC 的连接串中添加配置:
> &serverTimezone=Asia/Shanghai 
(这里的时区需要与服务器的真实时区相同,我们是中国当然真实时区就是上面的了)

或者
添加格式：

> ?serverTimezone=GMT%2B8&amp;

综上:如果不是 DB 管理员,第三种办法是最好最保险的办法.

 