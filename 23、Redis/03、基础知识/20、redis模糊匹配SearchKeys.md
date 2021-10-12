
## [原文](http://www.cnblogs.com/zhangyu1024/p/5229887.html)

# Redis 模糊匹配 SearchKeys

语法：KEYS pattern
说明：返回与指定模式相匹配的所用的keys。

该命令所支持的匹配模式如下：

1. ?：用于匹配单个字符。
 > 例如，h?llo可以匹配hello、hallo和hxllo等；

2. *：用于匹配零个或者多个字符。
>   例如，h*llo可以匹配hllo和heeeello等；

3. []：可以用来指定模式的选择区间。
> 例如h[ae]llo可以匹配hello和hallo，但是不能匹配hillo。

同时，可以使用“/”符号来转义特殊的字符

