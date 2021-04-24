

# redis zset 多字段排序

## 题目：考试根据分数 和 交卷时间排名，分数一样，交卷早的排面在前

考试时间：9：00 - 11：00

    分数, 交卷时间, 排名
    90    11:00   2
    90    11:00   2
    90    10:30   1
    90    10:20   3
    80    10:20   5
    80    10:10   4
    

解决方案：

字符串拼接 然后转换成整数，交卷时间 可以使用 24：00 去减法

参考项目：
/mamba-forever-lakers/mamba-out/mamba-training-camp/src/main/java/kobe/mamba/example/redis/SortExampleService.java

