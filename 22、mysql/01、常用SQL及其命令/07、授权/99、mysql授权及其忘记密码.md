

## mysql授权及其忘记密码

刚安装的 MySQL 是没有密码的，这时如果出现：
```mysql
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)，解决如下：
```
① 停止 MySQL 服务：systemctl stop mysqld 

② 以不检查权限的方式启动 MySQL: 
```mysql
mysqld --user=root --skip-grant-tables &
```
③ 再次输入 
```mysql
mysql -u root 
```
或者 
```mysql
mysql
```
这次就可以进来了。

④ 更新密码：

MySQL 5.7 以下版本：
```mysql
UPDATE mysql.user SET Password=PASSWORD('123456') where USER='root';
```
MySQL 5.7 版本：
```mysql
UPDATE mysql.user SET authentication_string=PASSWORD('123456') where USER='root';
```
mysql 8.x.x 版本
```mysql
UPDATE user SET authentication_string='root' WHERE user='root';
```

⑤ 刷新：
```mysql
flush privileges;
```
⑥ 退出：
```mysql
exit
```

设置完之后，输入 
```mysql
mysql -u root -p
```
这时输入刚设置的密码，就可以登进数据库了。
 
