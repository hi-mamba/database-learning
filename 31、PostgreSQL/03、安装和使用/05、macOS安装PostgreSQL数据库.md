
## [原文](https://www.jianshu.com/p/10ced5145d39)

# Mac安装PostgreSQL

## 安装及初始化
这里使用homebrew安装
```bash
brew install postgresql

```
等待安装完成后，初始化：

```bash
initdb /usr/local/var/postgres
```
启动服务：

```bash
pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
```
设置开机启动

```bash
ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
```

## 创建数据库和账户

mac安装postgresql后不会创建用户名数据库，执行命令：

```postgresql
createdb

```
然后登录PostgreSQL控制台：

```postgresql
psql

```

使用\l命令列出所有的数据库，看到已存在用户同名数据库、postgres数据库，但是postgres数据库的所有者是当前用户，没有postgres用户。按:q退出查看
之后需要做以下几件事：


创建postgres用户
```postgresql
 CREATE USER postgres WITH PASSWORD 'password';
```


删除默认生成的postgres数据库
```postgresql
 DROP DATABASE postgres;
```


创建属于postgres用户的postgres数据库
```postgresql
 CREATE DATABASE postgres OWNER postgres;
```


将数据库所有权限赋予postgres用户
```postgresql
 GRANT ALL PRIVILEGES ON DATABASE postgres to postgres;
```


给postgres用户添加创建数据库的属性
```postgresql
 ALTER ROLE postgres CREATEDB;
```

这样就可以使用postgres作为数据库的登录用户了，并可以使用该用户管理数据库

## 登录控制台指令
```postgresql
psql -U [user] -d [database] -h [host] -p [post]
```
> 例子 psql -Uroot -dtest

-U指定用户，-d指定数据库，-h指定服务器，-p指定端口
上方直接使用psql登录控制台，实际上使用的是缺省数据
```
user：当前mac用户
database：用户同名数据库
主机：localhost
端口号：5432，postgresql的默认端口是5432
```

完整的登录命令，比如使用postgres用户登录
```postgresql
psql -U postgres -d postgres
```

## 常用控制台命令
```
\password：设置当前登录用户的密码
\h：查看SQL命令的解释，比如\h select。
\?：查看psql命令列表。
\l：列出所有数据库。
\c [database_name]：连接其他数据库。
\d：列出当前数据库的所有表格。
\d [table_name]：列出某一张表格的结构。
\du：列出所有用户。
\e：打开文本编辑器。
\conninfo：列出当前数据库和连接的信息。
\password [user]: 修改用户密码
\q：退出
```

