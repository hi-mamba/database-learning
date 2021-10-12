
## [原文](https://www.jianshu.com/p/257afa87d30d)

# centOS7.0安装Redis及客户端连接

> 下载地址：https://redis.io/download

## 下载安装
下载源码，解压缩到 /usr/local/ 重命名成 redis，编译安装
```
wget http://download.redis.io/releases/redis-4.0.1.tar.gz
```
或者这样来安装
> sudo yum install redis 

```bash

cd /usr/local
tar xzf /root/redis-4.0.1.tar.gz
mv redis-4.0.1 redis
cd redis
make && make install

```
复制配置文件到  /etc

```bash
cp redis.conf /etc/

```
参数查看

```bash
redis-server --help

```





参数

版本参看

```bash
redis-server -v

```
启动Redis服务器

```bash
redis-server /etc/redis.conf


```

注：此命令仅有一个启动参数，指定/path/to/redis.conf目录下的配置文件，不加参数执行默认配置。

如下图





## Redis

退出关闭按 ctlr+z

设置后台运行，进入etc

```bash
vim /etc/redis.conf

```

修改 daemonize no 为 daemonize yes，这样就可以默认启动就后台运行

测试启动，返回PONG，启动成功。

```bash
redis-server /etc/redis.conf
redis-cli ping

```

 
redis-cli ping

[root@localhost redis-4.0.1]# netstat -tulnp | grep 6379 
tcp        0      0 127.0.0.1:6379              0.0.0.0:*                   LISTEN      7949/redis-server 1 

停止Redis

## 关闭服务

```bash
redis-cli shutdown
netstat -tulnp | grep 6379

redis-cli ping

```
Could not connect to Redis at 127.0.0.1:6379: Connection refused

注:可指定端口:redis-cli -p <port> shutdown

## 连接Redis
两种链接redis的方法：

### 方法一、

```bash
redis-cli      #也可以指定ip，端口号启动redis（redis-cli -h 192.168.1.2 -p 6379） 
127.0.0.1:6379>  
127.0.0.1:6379> quit

```
### 方法二、

```bash
telnet 192.168.1.2 6379 
Trying 192.168.1.2... 
Connected to 192.168.1.2. 
Escape character is '^]'. 
quit 
+OK 
Connection closed by foreign host

```
设置开机启动请阅读：<http://www.jianshu.com/p/dbc4bd77f37c>
 