
原文：<http://www.xuanyimao.com/softarticle/mysql100.html>

# mysql百万级数据查询优化实践

### 结论
如果分页查询，多条件过滤，那么可以先多条件查询出主键id ，然后在in 去查询
