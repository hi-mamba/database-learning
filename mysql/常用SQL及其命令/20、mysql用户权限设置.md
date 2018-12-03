
## [原文](http://www.cnblogs.com/candle806/p/4048651.html)

# mysql用户权限设置

关于mysql的用户管理，笔记

 

## 1、创建新用户

通过root用户登录之后创建

```mysql
#　　创建新用户，用户名为testuser，密码为123456 ；
grant all privileges on *.* to testuser@localhost identified by "123456" ;

#　　设置用户testuser，可以在本地访问mysql
grant all privileges on *.* to testuser@localhost identified by "123456" ;

#　　设置用户testuser，可以在远程访问mysql
grant all privileges on *.* to testuser@"%" identified by "123456" ;

# 如果你想允许用户jack从ip为10.10.50.127的主机连接到mysql服务器，并使用654321作为密码
 GRANT ALL PRIVILEGES ON *.* TO 'jack'@’10.10.50.127’ IDENTIFIED BY '654321' WITH GRANT OPTION;
 

#    mysql 新设置用户或更改密码后需用flush privileges刷新MySQL的系统权限相关表，
#    否则会出现拒绝访问，还有一种方法，就是重新启动mysql服务器，来使新设置生效
flush privileges ;

```
　　

## 2、设置用户访问数据库权限


```mysql

# 　 设置用户testuser，只能访问数据库test_db，其他数据库均不能访问 ；
grant all privileges on test_db.* to testuser@localhost identified by "123456" ;

# 　设置用户testuser，可以访问mysql上的所有数据库 ；
grant all privileges on *.* to testuser@localhost identified by "123456" ;

# 　 设置用户testuser，只能访问数据库test_db的表user_infor，数据库中的其他表均不能访问 ；
grant all privileges on test_db.user_infor to testuser@localhost identified by "123456" ;

```
　　

## 3、设置用户操作权限

```mysql

# 　　设置用户testuser，拥有所有的操作权限，也就是管理员 ；
grant all privileges on *.* to testuser@localhost identified by "123456" WITH GRANT OPTION ;

# 　　设置用户testuser，只拥有【查询】操作权限 ；
grant select on *.* to testuser@localhost identified by "123456" WITH GRANT OPTION ;

# 　　设置用户testuser，只拥有【查询\插入】操作权限 ；
grant select,insert on *.* to testuser@localhost identified by "123456"  ;

# 　　设置用户testuser，只拥有【查询\插入】操作权限 ；
grant select,insert,update,delete on *.* to testuser@localhost identified by "123456"  ;

# 　　取消用户testuser的【查询\插入】操作权限 ；
REVOKE select,insert ON what FROM testuser;

```
　　

## 4、设置用户远程访问权限

```mysql
# 　　设置用户testuser，只能在客户端IP为192.168.1.100上才能远程访问mysql ；
grant all privileges on *.* to testuser@“192.168.1.100” identified by "123456" ;

```
　　

## 5、关于root用户的访问设置

设置所有用户可以远程访问mysql，修改my.cnf配置文件，
将bind-address = 127.0.0.1前面加“#”注释掉，这样就可以允许其他机器远程访问本机mysql了；

```mysql

# 　　 设置用户root，可以在远程访问mysql
grant all privileges on *.* to root@"%" identified by "123456" ;

#   查询mysql中所有用户权限
select host,user from user;


```
## 关闭root用户远程访问权限


```mysql

# 　 禁止root用户在远程机器上访问mysql
delete from user where user="root" and host="%" ;

#   修改权限之后，刷新MySQL的系统权限相关表方可生效
flush privileges ;

```



