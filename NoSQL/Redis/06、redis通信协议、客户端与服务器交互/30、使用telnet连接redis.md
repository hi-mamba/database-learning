## [23、redis通信协议.md](23、redis通信协议.md)

## [22、通信协议（protocol）.md](22、通信协议（protocol）.md)

## [使用telnet连接redis](https://www.jianshu.com/p/b5617c901fb7)

# 使用telnet连接redis

平时连接redis用的是官方客户端redis-cli, 使用redis-cli最常用的几个参数如下：
```bash
-h <hostname>      Server hostname (default: 127.0.0.1).
-p <port>          Server port (default: 6379).
-a <password>      Password to use when connecting to the server.

```
比如连接本地redis：

```bash
redis-cli -h 127.0.0.1 -p 6379 -a 12345

```
如果没有redis-cli，还可以用telnet，连接方式为：

```bash
telnet <hostname> <port>

```
连接成功后，如果redis设置了密码，则还需要密码认证，这个时候其实已经和redis建立了通信，使用redis命令auth认证即可：

```bash
auth <password>

```

其实用redis-cli连接redis的时候-a 12345不是必须的，可以之后通过auth命名输入密码获得认证。

```bash
> telnet 127.0.0.1 6379

Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
set test 6
+OK
get test
$6
valule
gett
-ERR unknown command `gett`, with args beginning with:
set k1 1
+OK
get k1
$1
1
del k1
:1
get k1
$-1
```

至于为什么返回又 `-` 、`+` 、`$` 和 `：` 这些符合你需要去了解  [23、redis通信协议.md](23、redis通信协议.md)


- [协议说明](http://redis.cn/topics/protocol)