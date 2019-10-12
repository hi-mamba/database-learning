

# Redis Ping 命令


Redis Ping 命令使用客户端向 Redis 服务器发送一个 PING ，如果服务器运作正常的话，会返回一个 PONG 。

通常用于测试与服务器的连接是否仍然生效，或者用于测量延迟值。

## 语法
redis Ping 命令基本语法如下：

### 返回值
如果连接正常就返回一个 PONG ，否则返回一个连接错误。

```bash
# 客户端和服务器连接正常

127.0.0.1:6379> ping
PONG

# 客户端和服务器连接不正常(网络不正常或服务器未能正常运行)
127.0.0.1:6379> ping
Could not connect to Redis at 127.0.0.1:6379: Connection refused
not connected>
```
