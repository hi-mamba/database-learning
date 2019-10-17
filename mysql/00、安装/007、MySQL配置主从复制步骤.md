## ☑️  [CentOS 7 配置 MySQL 5.7 主从复制](https://qizhanming.com/blog/2017/06/20/how-to-config-mysql-57-master-slave-replication-on-centos-7)

## [Centos7下Mysql5.7配置主从复制步骤](https://www.zybuluo.com/lgh-dev/note/1455533)

## [Mysql 8 主从配置(Master-Slave)](https://blog.csdn.net/jessDL/article/details/82720091)

# 007、MySQL配置主从复制步骤

## 主数据 master 配置

### 1、修改主节点的配置文件
```shell script
[mamba@localhost mysql_master_3306]$ vi /home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf
```
在文件中[mysqld]节点下加入以下配置
```shell script
server-id=1
log-bin=master-bin
log-bin-index=master-bin.index
```

### 2、重启mysql 服务
自定义安装的【如果启动不成功，看下是否需要删除 mysql_master_3306/data 文件】
```shell script
[mamba@localhost mysql_master_3306]$ kill pid
[mamba@localhost mysql_master_3306]$ ./bin/mysqld_safe --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf &
```

### 3、连接数据库，，检验是否配置成功
```mysql
mysql> show master status;
+-------------------+----------+--------------+------------------+-------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+-------------------+----------+--------------+------------------+-------------------+
| master-bin.000002 |      641 |              |                  |                   |
+-------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```


可以看到这些信息，说明前面我们的master配置成功了

### 4、创建用于复制操作的用户

```mysql
mysql> CREATE USER 'repl'@'localhost' IDENTIFIED WITH mysql_native_password BY 'repl9527';
Query OK, 0 rows affected (0.01 sec)

#授权
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'localhost';

#刷新授权信息
flush privileges;
```

## 二，从数据库配置

### 1. 修改从节点的配置文件
```shell script
[mamba@localhost mysql_slave_3307]$ vi /home/mamba/soft/mysql/mysql_slave_3307/etc/my.cnf
```

加入以下内容
```mysql
server-id=2
relay-log=slave-relay-log
relay-log-index=slave-relay-bin.index
```

### 2 重启mysql服务
```mysql
[mamba@localhost mysql_slave_3307]$ ./bin/mysqld restart
```

### 3.在从节点上设置主节点参数

- 账号是主库上执行创建的
- MASTER_LOG_FILE 文件是主库执行  show master status; 获取的
- MASTER_LOG_POS 位点也是执行 主库执行  show master status; 获取的
```mysql
mysql> CHANGE MASTER TO
    ->     MASTER_HOST='localhost',master_port=3306,master_user='repl',
    ->     master_password='repl9527',MASTER_LOG_FILE='master-bin.000002',
    ->     MASTER_LOG_POS=1327;

Query OK, 0 rows affected, 2 warnings (0.03 sec)
```


### 4. 开启主从同步
```mysql
mysql> start slave;
Query OK, 0 rows affected (0.01 sec)
```
### 5.查看同步状态
```mysql
mysql> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: localhost
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: master-bin.000002
          Read_Master_Log_Pos: 1327
               Relay_Log_File: localhost-relay-bin.000002
                Relay_Log_Pos: 323
        Relay_Master_Log_File: master-bin.000002
             # 注意这里
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1327
              Relay_Log_Space: 535
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: 2e42c32a-efd5-11e9-8a37-c85b768fcda6
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
       Master_public_key_path:
        Get_master_public_key: 0
            Network_Namespace:
1 row in set (0.00 sec)

ERROR:
No query specified

mysql>
```

说明们的主从同步配置成功了，接下来测试看看，在主库中创建数据库 test_master_slave,从库不做任何操作。

注意：如果如果从库宕机，重新启动，要连接上mysql服务，执行 start slave 这个命令，开启主从同步

- 主库执行
```mysql
mysql> create database test_master_slave;
Query OK, 1 row affected (0.01 sec)
```

- 从库执行
```mysql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test_master_slave  |
+--------------------+
5 rows in set (0.00 sec)
```

## 注意设置位点
- 在从库停止 
> mysql> stop slave; 

- 然后执行 CHANGE 这个，然后开启
>  start slave; 

- 查看  mysql
> show slave status\G; 

```mysql
    Slave_IO_State: Waiting for master to send event
                  Master_Host: localhost  //注意这里
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: binlog.000003
          Read_Master_Log_Pos: 7144
               Relay_Log_File: mysql3307-relay-bin.000002
                Relay_Log_Pos: 319
        Relay_Master_Log_File: binlog.000003
             Slave_IO_Running: Yes //注意这里
            Slave_SQL_Running: Yes //注意这里
```
```mysql
mysql> CHANGE MASTER TO MASTER_HOST='localhost',MASTER_USER='repl', MASTER_PASSWORD='123456', MASTER_LOG_FILE='binlog.000003', MASTER_LOG_POS=7144;
```


## 遇到问题

- 账号repl 没有权限，需要赋予权限.  
mysql8.X.X 赋予权限需要注意
```mysql
2019-08-08T07:07:07.045553Z 9 [Warning] [MY-013120] [Repl] Slave I/O for channel '': Master command COM_REGISTER_SLAVE failed: failed registering on master, reconnecting to try again, log 'binlog.000003' at position 4, Error_code: MY-013120
2019-08-08T07:07:07.045716Z 9 [Warning] [MY-010897] [Repl] Storing MySQL user name or password information in the master info repository is not secure and is therefore not recommended. Please consider using the USER and PASSWORD connection options for START SLAVE; see the 'START SLAVE Syntax' in the MySQL Manual for more information.
2019-08-08T07:07:07.052026Z 9 [ERROR] [MY-013120] [Repl] Slave I/O for channel '': Master command COM_REGISTER_SLAVE failed: Access denied for user 'repl'@'localhost' (using password: YES) (Errno: 1045), Error_code: MY-013120
2019-08-08T07:07:07.052141Z 9 [ERROR] [MY-010564] [Repl] Slave I/O thread couldn't register on master
```

- 从库设置连接主库账号的数据库密码不对

```mysql
2019-08-08T07:14:07.094170Z 9 [Warning] [MY-010897] [Repl] Storing MySQL user name or password information in the master info repository is not secure and is therefore not recommended. Please consider using the USER and PASSWORD connection options for START SLAVE; see the 'START SLAVE Syntax' in the MySQL Manual for more information.
2019-08-08T07:14:07.098991Z 9 [ERROR] [MY-013120] [Repl] Slave I/O for channel '': Master command COM_REGISTER_SLAVE failed: Access denied for user 'repl'@'localhost' (using password: YES) (Errno: 1045), Error_code: MY-013120
2019-08-08T07:14:07.099098Z 9 [ERROR] [MY-010564] [Repl] Slave I/O thread couldn't register on master
```
