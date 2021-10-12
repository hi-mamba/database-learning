
## [原文](https://www.jianshu.com/p/0ed7e88325dd)

# 06、redis cluster配置远程访问


通常来说，生产环境下的Redis服务器只设置为仅本机访问（Redis默认也只允许本机访问）。
有时候我们也许需要使Redis能被远程访问。此文介绍配置Redis允许远程访问。

## 配置
修改Redis配置文件 redis.conf，找到bind那行配置：
```bash
vim redis.conf
```
去掉 bind 127.0.0.1 改为：
```
bind 0.0.0.0
```

指定配置文件然后重启Redis服务即可：
```bash
sudo redis-server redis.conf
```

重启 redis 服务
```bash
sudo service redis-server restart

关于bind配置的含义，配置文件里的注释是这样说的：
# By default Redis listens for connections from all the network interfaces
# available on the server. It is possible to listen to just one or multiple
# interfaces using the "bind" configuration directive, followed by one or
# more IP addresses.
#
# Examples:
#
# bind 192.168.1.100 10.0.0.1
# bind 127.0.0.1
```

## 远程连接
配置好Redis服务并重启服务后。就可以使用客户端远程连接Redis服务了。命令格式如下：
```bash
$ redis-cli -h {redis_host} -p {redis_port}
```

其中{redis_host}就是远程的Redis服务所在服务器地址，{redis_port}就是Redis服务端口（Redis默认端口是6379）。例如：

```bash
$ redis-cli -h 120.120.10.10 -p 6379
redis>ping
PONG
```


## 集群配置远程访问

修改 redis.conf 与上面都一样

创建集群的时候需要修改

## ### 创建集群
 
```bash
redis-cli --cluster create 机器IP:7000 机器IP:7001 机器IP:7002 机器IP:7003 机器IP:7004 机器IP:7005 --cluster-replicas 1
```

## 推荐阅读

[redis cluster 集群 重启 关闭](07、redis%20cluster%20集群%20重启%20关闭.md)



