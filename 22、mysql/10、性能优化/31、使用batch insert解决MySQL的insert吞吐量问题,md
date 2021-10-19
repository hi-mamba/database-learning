
 原文：<https://www.cnblogs.com/billyxp/p/3631242.html>

# 使用batch insert解决MySQL的insert吞吐量问题

>  insert into table values ($values),($values)...($values);

是否values积攒的越多，效率越高吗？ 答案自然是`否定`的，任何优化方案都不会是纯线性的，肯定会在某个条件下出现拐点。

我们按照不同的values number进行测试，分别为1、10、50、100、200、500、1000、5000、10000.

从下图我们可以看出，随着values number的增加，耗时先是急剧下降，从1777s变成53s，
然后在增加values number就不会有太大的变化，直到values number超过200，最后的10000个values number耗时达到了2分钟


从下图我们可以看到随着values numbers的增加，QPS（蓝线）先是猛增，然后下降，最终小于1/s。而RPS（绿线）随着增加猛增到一个高level，
然后随着增加逐步下降，超过5000个values number之后开始急剧下降。


另，最关键的是，QPS最高峰和RPS的最高峰并不在同一个values number下，也就是说QPS最高的时候并不代表着insert的吞吐量就最高。



在我这个简单测试场景中，values number最合适的值是50，和单values对比，耗时减少97%，insert吞吐量提升36倍。

而这个值和表结构和字段类型及大小都有关系。需要根据不同的场景进行测试之后才可以得出，但是普遍来说，50-100是比较推荐的考虑值。
