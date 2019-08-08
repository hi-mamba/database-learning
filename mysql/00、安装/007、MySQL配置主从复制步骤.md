## ☑️  [CentOS 7 配置 MySQL 5.7 主从复制](https://qizhanming.com/blog/2017/06/20/how-to-config-mysql-57-master-slave-replication-on-centos-7)

## [Centos7下Mysql5.7配置主从复制步骤](https://www.zybuluo.com/lgh-dev/note/1455533)

## [Mysql 8 主从配置(Master-Slave)](https://blog.csdn.net/jessDL/article/details/82720091)

# 007、MySQL配置主从复制步骤


> 注意设置位点，
> 在从库停止 mysql> stop slave; 然后执行 CHANGE 这个，然后开启 start slave; 
> 查看  mysql> show slave status\G; 

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
CHANGE MASTER TO MASTER_HOST='localhost',MASTER_USER='repl', MASTER_PASSWORD='123456', MASTER_LOG_FILE='binlog.000003', MASTER_LOG_POS=7144;
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
