
<https://redisbook.readthedocs.io/en/latest/feature/scripting.html>

# redis lua脚本实现原理

- 初始化 Lua 脚本环境需要一系列步骤，其中最重要的包括：
    - 创建 Lua 环境。
    - 载入 Lua 库，比如字符串库、数学库、表格库，等等。
    - 创建 redis 全局表格，包含各种对 Redis 进行操作的函数，比如 redis.call 和 redis.log ，等等。
    - 创建一个无网络连接的伪客户端，专门用于执行 Lua 脚本中的 Redis 命令。
- Reids 通过一系列措施保证被执行的 Lua 脚本无副作用，也没有有害的写随机性：对于同样的输入参数和数据集，总是产生相同的写入命令。
- EVAL 命令为输入脚本定义一个 Lua 函数，然后通过执行这个函数来执行脚本。
- EVALSHA 通过构建函数名，直接调用 Lua 中已定义的函数，从而执行相应的脚本。
