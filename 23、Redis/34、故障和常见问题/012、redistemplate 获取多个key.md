
<https://juejin.cn/s/redistemplate%20%E8%8E%B7%E5%8F%96%E5%A4%9A%E4%B8%AAkey>

# redistemplate 获取多个key

multiGet() 方法的参数是一个 List 类型的 keys，返回值是一个 List 类型的 values，
其中 values 的元素顺序与 keys 的元素`顺序一一对应`。
如果某个 key 在 Redis 中不存在，对应的 value 将为 null。
