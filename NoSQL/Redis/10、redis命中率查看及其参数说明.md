
## [原文](https://blog.csdn.net/lanbingkafei/article/details/42425705)

## [原文](https://my.oschina.net/u/3255899/blog/1163032)


# redis命中率查看及其参数说明


- 查询命中数： 查询的命中个数，对应 keyspace_hits 字段。

- 查询未命中数： 查询的未命中个数，对应 keyspace_misses 字段。

- 查询命中率： 查询命中率，对应 keyspace_hits / ( keyspace_hits + keyspace_misses )。

- 总Key个数： 缓存中总的 key 个数，所有 db 的 key 个数总和。

- 已过期Key个数： 缓存中已过期 Key 个数，对应 expired_keys 字段。

- 被拒绝Key个数： 缓存中被拒绝 Key 个数，对应 evicted_keys 字段。当缓存内存不足时，会根据用户配置的 maxmemory-policy 来选择性地删除一些 key 来保护内存不溢出


 
redis 127.0.0.1:6381> info

```
redis_version:2.4.16                                  # Redis 的版本
redis_git_sha1:00000000
redis_git_dirty:0
arch_bits:64
multiplexing_api:epoll
gcc_version:4.1.2                                         #gcc版本号
process_id:10629                                        # 当前 Redis 服务器进程id
uptime_in_seconds:145830                      # 运行时间(秒)
uptime_in_days:1                                        # 运行时间(天)
lru_clock:947459                                        
used_cpu_sys:0.02
used_cpu_user:0.02
used_cpu_sys_children:0.00
used_cpu_user_children:0.00
connected_clients:1                                  # 连接的客户端数量
connected_slaves:0                                  # slave的数量
client_longest_output_list:0
client_biggest_input_buf:0
blocked_clients:0
used_memory:832784                               # Redis 分配的内存总量
used_memory_human:813.27K
used_memory_rss:1896448                     # Redis 分配的内存总量(包括内存碎片)
used_memory_peak:832760                
used_memory_peak_human:813.24K    #Redis所用内存的高峰值
mem_fragmentation_ratio:2.28                 # 内存碎片比率
mem_allocator:jemalloc-3.0.0                 

loading:0
aof_enabled:0                                                  #redis是否开启了aof
changes_since_last_save:0                         # 上次保存数据库之后，执行命令的次数
bgsave_in_progress:0                                   # 后台进行中的 save 操作的数量
last_save_time:1351506041                        # 最后一次成功保存的时间点，以 UNIX 时间戳格式显示
bgrewriteaof_in_progress:0                         # 后台进行中的 aof 文件修改操作的数量
total_connections_received:1                      # 运行以来连接过的客户端的总数量
total_commands_processed:1                    # 运行以来执行过的命令的总数量
expired_keys:0                                                # 运行以来过期的 key 的数量
evicted_keys:0                                                #运行以来删除过的key的数量
keyspace_hits:0                                            # 命中 key 的次数
keyspace_misses:0                                     # 不命中 key 的次数
pubsub_channels:0                                     # 当前使用中的频道数量
pubsub_patterns:0                                      # 当前使用的模式的数量
latest_fork_usec:0                                      
vm_enabled:0                                                # 是否开启了 vm (1开启  0不开启)
role:master                                                     #当前实例的角色master还是slave
db0:keys=183,expires=0                             # 各个数据库的 key 的数量，以及带有生存期的 key 的数量
```

## 命中率查看 

INFO  命令，能够随时监控服务器的状态，只用telnet到对应服务器的端口，执行命令即可：
```bash

telnet localhost 6379  
info 

```
在输出的信息里面有这几项和缓存的状态比较有关系：
 
```
keyspace_hits:14414110  
keyspace_misses:3228654  
used_memory:433264648  
expired_keys:1333536  
evicted_keys:1547380 
```

通过计算hits和miss， 得到缓存的命中率：14414110 / (14414110 + 3228654) = 81%  