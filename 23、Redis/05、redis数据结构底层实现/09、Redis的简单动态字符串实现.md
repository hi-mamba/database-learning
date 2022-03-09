
## [原文](https://www.cnblogs.com/chengxuyuancc/p/3984741.html)

# Redis的简单动态字符串实现

Redis 没有直接使用 C 语言传统的字符串表示（以空字符结尾的字符数组，以下简称 C 字符串）， 
而是自己构建了一种名为`简单动态字符串（simple dynamic string，sds）`的抽象类型， 
并将sds用作 Redis 的默认字符串表示。

sds简单动态字符串数据结构如下：

```c
1 typedef char *sds;
2 
3 struct sdshdr {
4     int len;
5     int free;
6     char buf[];
7 };
```
len记录字符串的长度，free记录sds还剩余的空间，buf指向存储字符的空间。

对应的内存空间如下图：

![](../../../../images/redis/sds/redis_sds_1.png)


例如最开始要存放字符串“chenrancc”:

![](../../../../images/redis/sds/redis_sds_2.png)


一般开始的时候会比初始字符串多申请一个长度的空间放\0，如上图所示，对应的函数是sdsnewlen。
删除后面的cc字符后：


![](../../../../images/redis/sds/redis_sds_3.png)


删除后面的cc字符后，空出两个字符空间并不会回收，而是用free来记录。如果要回收者两个空闲的空间，
必须重新分配一个新的sds，做法是将原来的sds通过`realloc重新分配`成新的sds，对应的函数为sdsRemoveFreeSpace。
如果要增加sds的空间，也是用同样的方法通过realloc重新分配一个新的sds，对应的函数是sdsMakeRoomFor。

要回收sds所在的内存空间，可以通过函数sdsfree，它实际调用的是free函数。

除了上面提到的函数，sds中还定义了很多其它的函数来方便上层使用：


```c
 1 sds sdsnewlen(const void *init, size_t initlen);  //用长度为initlen的字符串创建sds
 2 sds sdsempty(void);  //创建一个长度为0的sds
 3 sds sdsnew(const char *init);  //用null结尾的字符串创建sds
 4 sds sdsdup(const sds s);  //拷贝一个sds
 5 void sdsfree(sds s);  //释放sds所占的内存空间
 6 void sdsupdatelen(sds s);  //更新sds中的len为实际的字符串长度
 7 void sdsclear(sds s);  //将sds中的字符串为空串
 8 sds sdsMakeRoomFor(sds s, size_t addlen);  //sds字符串所占空间增加addlen个字符（包括free所占的字符）
 9 sds sdsRemoveFreeSpace(sds s);  //去除sds中空闲的空间
10 size_t sdsAllocSize(sds s);  //获取sds实际占用空间的大小
11 void sdsIncrLen(sds s, int incr);  //sds实际字符串的长度增加incr
12 sds sdsgrowzero(sds s, size_t len);  //将sds所占的空间增加到len,增加的空间都清零
13 sds sdscatlen(sds s, const void *t, size_t len);  //sds末尾连接一个长度为len的字符串
14 sds sdscat(sds s, const char *t);  //sds末尾连接一个以null结尾的字符串
15 sds sdscatsds(sds s, const sds t);  //sds末尾连接另一个sds
16 sds sdscpylen(sds s, const char *t, size_t len);  //拷贝长度为len的字符串到sds中
17 sds sdscpy(sds s, const char *t);  //拷贝以null结尾的字符串到sds中
18 sds sdscatvprintf(sds s, const char *fmt, va_list ap);  //sds末尾连接一个由可变参数形成的字符串
19 sds sdscatprintf(sds s, const char *fmt, ...);  //sds末尾连接一个由可变参数形成的字符串
20 sds sdstrim(sds s, const char *cset);  //去除sds字符串的前后字符，这些字符都是在cset中出现过的
21 void sdsrange(sds s, int start, int end);  //获取sds字符串的一个字串，start和end可以为负数，负数表示从后面往前面索引
22 void sdstolower(sds s);  //将sds字符串中的字符设置为小写
23 void sdstoupper(sds s);  //将sds字符串中的字符设置为大写
24 int sdscmp(const sds s1, const sds s2);  //比较两个字符串的大小
25 sds *sdssplitlen(const char *s, int len, const char *sep, int seplen, int *count);  //用字符串sdp分割一个sds为多个sds
26 void sdsfreesplitres(sds *tokens, int count);  //释放由函数sdssplitlen返回的sds数组空间
27 sds sdsfromlonglong(long long value);  //将long long类型的数字转化为一个sds
28 sds sdscatrepr(sds s, const char *p, size_t len);  //sds末尾连接一个长度为len的字符串，并且将其中的不可打印字符显示出来
29 int is_hex_digit(char c);  //判断一个字符释放为16进制数字
30 int hex_digit_to_int(char c);  //将一个16进制数字转化为整数
31 sds *sdssplitargs(const char *line, int *argc);  //将一行文本分割成多个参数，每个参数可以用类编程语言 REPL格式，如果空格，\n\r\t\0等作为分隔符
32 sds sdsmapchars(sds s, const char *from, const char *to, size_t setlen) //将sds中出现在from中的字符替换为to对应的字符
33 sds sdsjoin(char **argv, int argc, char *sep);  //将多个字符串用分割符连接起来组成一个sds
```

sds和c++中的vector很类似，唯一不同的是vector在空间不够的时候可以自动增加2倍的空间。

了解了sds的实现，想想为什么redis非要自己实现一个字符串，而不是使用c所支持的字符串和相关的操作呢？

## 相比c语言中的字符串，sds有如下的好处：

- 记录了字符串的长度，用O(1)的时间复杂度可以获得字符串的长度。

- 有效的管理字符串所占用的空间，`自动扩展空间`等。

- 有效的`防止内存越界`，因为如果空间不够，sds的相关函数会`自动扩展空间`。
