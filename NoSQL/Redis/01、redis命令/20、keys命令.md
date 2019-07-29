

# 20、keys命令

在redis 集群中，通过 redis-cli命令来执行  keys * 不能全部获取匹配的key,
你可以在所有的redis 节点通过 redis-cli 连接之后,通过redis命令实现性能监控 `monitor`，
可以试用monitor命令来查看，他能清楚的看到客户端在什么时间点执行了那些命令。
因此如果使用 
> redis-cli -c -h 127.0.0.1 -p 7001    
> KEYS *   

只能获取这个节点的key ,无法获取及其节点,如果想获取怎么办？
1、通过客户端 jedis 获取Lettuce,这些会帮我们请求多个master节点来获取key，然后返回

2、[keys和scan居然都只能查看到当前节点的匹配到的key，what the fuck!!
  想到之前工作中也碰到过同样的问题，于是折腾了会儿写了个脚本：](https://www.jianshu.com/p/965e2c18e814)
```bash
#!/bin/sh
redis-cli -c -p PORT -h IP cluster nodes | awk '{if($3=="master" || $3=="myself,master") print $2}' | awk -v var_pattern="$1" -F[:@] '{system("redis-cli -c -p "$2" -h "$1" keys "var_pattern)}'
```  

[About command "keys * " in cluster--How can I get all keys in redis cluster? ](https://github.com/antirez/redis/issues/1962)

[redis-cli in cluster mode: keys command does not return all keys ](https://github.com/antirez/redis/issues/5379)


