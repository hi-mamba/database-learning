
<https://www.cnblogs.com/zhuiluoyu/p/8127129.html>

<https://dev.mysql.com/doc/refman/5.7/en/limit-optimization.html>

[MySQL · 答疑解惑 · MySQL Sort 分页](http://mysql.taobao.org/monthly/2015/06/04/)

# MySQL 分页数据错乱重复 

## mysql5.7 : LIMIT Query Optimization

![image](https://github.com/hi-mamba/database-learning/assets/7867225/2af4bcf9-8f46-4134-9404-0b36f2a77488)

机器翻译： 如果多行在 ORDER BY 列中具有相同的值，则服务器可以自由地以任何顺序返回这些行，并且可能会根据整体执行计划以不同的方式返回这些行。
换句话说，这些行的排序顺序相对于无序列来说是不确定的。

> 影响执行计划的因素之一是 LIMIT，因此带有和不带有 LIMIT 的 ORDER BY 查询可能会以不同的顺序返回行

### 解决方案：
![image](https://github.com/hi-mamba/database-learning/assets/7867225/8d598f48-f44a-442a-9cc0-f6c39e6eacc0)

如果在使用和不使用 LIMIT 的情况下确保相同的行顺序很重要，请在 ORDER BY 子句中包含其他列以使顺序`具有​​确定性`。
 > 例如，如果 id 值是唯一的，则可以通过如下排序使给定类别值的行按 id 顺序显示

## 原因调查
在MySQL 5.6的版本上，优化器在遇到order by limit语句的时候，做了一个优化，
即使用了`priority queue`


使用 `priority queue` 的目的，就是在不能使用索引有序性的时候，如果要排序，
并且使用了limit n，那么只需要在排序的过程中，保留n条记录即可，
这样虽然不能解决所有记录都需要排序的开销，但是只需要 `sort buffer` 少量的内存就可以完成排序。

之所以5.6出现了`第二页数据重复`的问题，是因为 priority queue 使用了`堆排序`的排序方法，
而`堆排序是一个不稳定`的`排序方法`，也就是`相同的值`可能排序出来的`结果`和`读出来`的数据顺序不一致。

5.5 没有这个优化，所以也就不会出现这个问题。

## 解决方法

1. 索引排序字段

利用`索引的有序性`，如果用户在字段添加上索引，就直接按照索引的有序性进行读取并分页，从而可以规避遇到的这个问题

2. 正确理解分页()
> 确定排序字段唯一性，可以多 排序字段+主键 一起排序

页是建立在排序的基础上，进行了数量范围分割.




