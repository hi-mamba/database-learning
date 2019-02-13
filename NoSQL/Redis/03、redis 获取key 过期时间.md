

# redis 获取key 过期时间

Redis TTL命令用于获取键到期的剩余时间(秒)。
 
返回值

以毫秒为单位的整数值TTL或负值
 
TTL以毫秒为单位。
 
-1, 如果key没有到期超时。
 
-2, 如果键不存在

> ttl redis_key