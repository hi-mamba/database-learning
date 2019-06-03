## [Redis使用量暴增，快速定位有哪些大key在作怪](https://blog.csdn.net/chinawangfei/article/details/85787142)


## [探寻 Redis 内存诡异增长的元凶](https://mp.weixin.qq.com/s/6P3IfxIIAkYuquiZetGMAg)

# Redis使用量暴增，快速定位有哪些大key在作怪

发现redis使用量突然暴增，于是紧急扩容redis，不能影响服务运行。扩容之后，赶紧查找原因，突破口就是寻找存在哪些大key。

1. 将redis的dump.rdb文件下载到本地（一般redis的持久化文件以rdb的方式存储，在redis配置文件可以找到dump.rdb的存储路径）。

2. 用rdbtools工具生产内存报告，命令是 rdb -c memory，例子：
```bash
sudo rdb -c memory  /redisfile/dump.rdb >test.csv

```
注意：rdb文件越大，生成时间越长。

Rdbtools是以python语言开发的。

GITHUP地址：https://github.com/sripathikrishnan/redis-rdb-tools/

3. 内存报告生成后，结合用linux sort命令排序，根据內存列排序，找出最高的key有哪些。例子：

```bash
sudo sort -k4nr -t , test.csv > sort.txt

```

4. 查看前1000个排序最高的数据

```bash
awk -F ',' '{print substr($3, 0,18)}' sort.txt | head -1000 | sort -k1 | uniq
```
5. 查看sort.txt的结果，一般能得出类似‘my_rank_top’开头的集合占用最高，排在了前面。若要查看类似‘my_rank_top’开头的key总共占用了多少内存，可以用命令：

```bash
sudo cat sort.txt | grep ‘my_rank_top’ | awk -F ',' '{sum += $4};END {print sum}'

```
6. 得知了my_rank_top这样的key占用最多内存，而且很可能是业务已经不再需要，但是长期在内存中没清理的，我们可以删除了这些集合。可以用模糊匹配key来删除，命令如下：

```bash
redis-cli -h 127.0.0.1 -p 6379  keys 'my_ranking_list*' | xargs redis-cli -h 127.0.0.1 -p 6379 del

```
另附：在本地启动redis加载dump.rdb文件时，一直load失败。搞了很长时间，终于找到原因：redis配置文件里databases要修改为256，本地默认是16，而产生原始dump.rdb的redis的databases就是25。

参考资料：

1. FAQ：https://github.com/sripathikrishnan/redis-rdb-tools/wiki/FAQs
2. redis dump文件规范： https://github.com/sripathikrishnan/redis-rdb-tools/wiki/Redis-RDB-Dump-File-Format
3. redis RDB历史版本： https://github.com/sripathikrishnan/redis-rdb-tools/blob/master/docs/RDB_Version_History.textile
4. redis-rdb-tools：https://github.com/sripathikrishnan/redis-rdb-tools
5.https://blog.csdn.net/jiangsanfeng1111/article/details/53523581
 