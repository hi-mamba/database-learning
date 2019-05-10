## [原文](https://www.jianshu.com/p/e8a2c727da66)

## [原文](http://redisbook.com/preview/server/execute_command.html)

# Redis 命令的执行过程


## 服务器端命令执行过程

描述redis server在处理client命令的执行过程，大概包括流程图、源码、以及redis的命令格式说明，
redis的通信协议参考自redis的官网。


### 命令执行过程
 整个redis的server端命令执行过程就如下面这个流程图：

- nio层读取数据
- 解析数据到命令行格式
- 查找命令对应的执行函数执行命令
- 同步数据到slave和aof


![](../../../images/redis/redis_server_command_execute.png)





