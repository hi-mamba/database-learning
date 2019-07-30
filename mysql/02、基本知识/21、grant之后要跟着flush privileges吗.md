

# 21、grant之后要跟着flush privileges吗

因此，正常情况下，grant命令之后，没有必要跟着执行flush privileges命令。

## flush privileges使用场景
那么，flush privileges是在什么时候使用呢？
显然，当数据表中的权限数据跟内存中的权限数据不一致的时候，
flush privileges语句可以用来重建内存数据，达到一致状态。

这种不一致往往是由不规范的操作导致的，比如直接用DML语句操作系统权限表。
我们来看一下下面这个场景：

![](../../images/mysql/flush_privileges.png)

可以看到，T3时刻虽然已经用delete语句删除了用户ua，但是在T4时刻，仍然可以用ua连接成功。
原因就是，这时候内存中acl_users数组中还有这个用户，因此系统判断时认为用户还正常存在。

在T5时刻执行过flush命令后，内存更新，T6时刻再要用ua来登录的话，就会报错“无法访问”了。

直接操作系统表是不规范的操作，这个不一致状态也会导致一些更“诡异”的现象发生。
