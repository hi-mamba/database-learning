## [原文](https://my.oschina.net/u/3255899/blog/1163032)

# redis 基本配置

随着redis的发展，越来越多的架构用它取代了memcached作为缓存服务器的角色， 几个很突出的特点：

- Hash， Sorted Set, List等数据结构
- 可以持久化到磁盘
- 支持cluster (3.0)
##  配置 

### Redis配置
作为缓存服务器，如果不加以限制内存的话，
就很有可能出现将整台服务器内存都耗光的情况，可以在redis的配置文件里面设置：

- 限定最多使用1.5GB内存
```
maxmemory 1536mb

```
如果内存到达了指定的上限，还要往redis里面添加更多的缓存内容，
需要设置清理内容的策略：

- 设置策略为清理最少使用的key对应的数据
```
maxmemory-policy allkeys-lru
```

