
#### [参考](https://www.cnblogs.com/easonbook/p/11005967.html)

# centOS 源码安装 postgreSQL

## 开始..

[下载地址](https://www.postgresql.org/ftp/source/)


创建目录
```shell script
  mkdir -p /tol/soft/postgresql  

  mkdir -p /tol/soft/postgresql/data  

  mkdir -p /tol/soft/postgresql/logs

  cd /tol/soft/postgresql
```

创建postgres用户
```shell script
useradd postgres
passwd postgres
```
更改目录权限
```shell script
$ cd /tol/soft/postgresql

$ chown -R postgres:postgres tol/soft/postgresql

$ chmod -R 700 tol/soft/postgresql
```

下载
> wget https://ftp.postgresql.org/pub/source/v13.0/postgresql-13.0.tar.gz

解压
> tar -zxvf postgresql-13.0.tar.gz

编译
```shell script
$ cd /tol/soft/postgresql/postgresql-13.0

指定安装目录
$ ./configure --prefix=/tol/soft/postgresql

> 遇到异常详情见下面解决方案
```

```shell script
make && make install
```

配置环境变量
```shell script
vim ~/.bash_profile
```

```shell script
export PG_HOME=/tol/soft/postgresql/postgresql
export PG_DATA=/tol/soft/postgresql/data
export PATH=$PATH:$PG_HOME/bin
```

初始化数据库
```shell script
$ cd /tol/soft/postgresql

$ ./postgresql/bin/initdb -D /tol/soft/postgresql/data
```
输出以下内容则表明成功。
```
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /data/pgdata ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    pg_ctl -D /data/pgdata/ -l logfile start

```

修改配置文件,远程访问

```shell script
cd /tol/soft/postgresql/data
vi postgresql.conf
```

```
# 将该条配置反注释，将localhost改成*
listen_addresses = '*'
```

修改访问控制文件
```
vi pg_hba.conf
# IPv4 local connections:
host    all             all             0.0.0.0/0            md5
```
说明：
```
# METHOD can be "trust", "reject", "md5", "password", "gss", "sspi",
# "ident", "peer", "pam", "ldap", "radius" or "cert".  Note that
# "password" sends passwords in clear text; "md5" is preferred since
# it sends encrypted passwords.
```

关闭防火墙
```
systemctl stop firewalld
systemctl disable firewalld
```
启动数据库
```shell script
[postgres@pgDatabase ~]$ pg_ctl -D /tol/soft/postgresql/data -l /tol/soft/postgresql/log/logfile.log start
server starting
```


进入数据库修改postgres密码
```shell script
$ psql
```
```shell script
postgres=# ALTER USER postgres WITH PASSWORD 'postgres';
ALTER ROLE
```
这样就算全部完成了，远程也可以连接数据库了。


## 遇到问题


### [安装postgreSQL出现configure:error:readline library not found解决方法及pg安装全过程](https://blog.csdn.net/wypblog/article/details/6863342)

```
[root@HK81-107 postgresql-9.0.0]# ./configure

configure: error: readline library not found
If you have readline already installed, see config.log for details on the
failure.  It is possible the compiler isnt looking in the proper directory.
Use --without-readline to disable readline support.

     根据提示，应该是没有安装 readline包。

3 检查系统是否安装 readline 包
[root@HK81-107 postgresql-9.0.0]# rpm -qa | grep readline
readline-5.1-3.el5

   说明系统已经安装了 readline包。

4 通过 yum 搜索相关的 readline 包
[root@HK81-107 postgresql-9.0.0]# yum search readline
lftp.i386 : A sophisticated file transfer program
lftp.i386 : A sophisticated file transfer program
php-readline.i386 : Standard PHP module provides readline library support
lftp.i386 : A sophisticated file transfer program
readline.i386 : A library for editing typed command lines.
compat-readline43.i386 : The readline 4.3 library for compatibility with older software.
readline-devel.i386 : Files needed to develop programs which use the readline library.
readline.i386 : A library for editing typed command lines.

 根据提示，有一个包引起了注意 "readline-devel", 猜想可能与这个包有关。
 
5 安装 readline-devel 包
[root@HK81-107 postgresql-9.0.0]# yum -y install -y readline-devel
```

### [failure.  It is possible the compiler isn't looking in the proper directory.]()
```
checking for inflate in -lz... no
configure: error: zlib library not found
If you have zlib already installed, see config.log for details on the
failure. It is possible the compiler isn't looking in the proper directory.
Use --without-zlib to disable zlib support.
```
出现这种错误，说明你的系统缺少zlib库，输入： rpm -qa | grep zlib，如果出现如下提示：
```
zlib-1.2.3-29.el6.x86_64
zlib-1.2.3-29.el6.i686
jzlib-1.0.7-7.5.el6.x86_64
```
则说明，你的电脑缺少 zlib-devel库，安装一下即可
```shell
[root@HK81-107 postgresql-9.0.0]# yum -y install -y zlib-devel
```


### 参考

[修改postgres密码](https://www.cnblogs.com/kaituorensheng/p/4735191.html)

[Postgresql: password authentication failed for user “postgres”](https://stackoverflow.com/questions/7695962/postgresql-password-authentication-failed-for-user-postgres)

[postgresql安装及常见错误处理](https://blog.csdn.net/zhu_xun/article/details/21234663)

