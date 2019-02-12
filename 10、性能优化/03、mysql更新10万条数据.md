
## [原文](https://segmentfault.com/q/1010000010462241)

# mysql更新10万条数据

mysql 10万条数据 更新一个字段 需要很长时间

## 答案

先给 publish_date 分组 将同一个日期的 Id 汇总到一起
这样你的sql数量将会大大减少

优化之后会是类似这样
```mysql
update yamaxunnew set publish_date = '2016年1月1日' where id in (1182323,1182324,...)
```

## 思路
> 分组更新



