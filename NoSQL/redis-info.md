
#  OOM command not allowed when used memory > 'maxmemory'.

也就是说，这个实例已经没有可用内存了。
在这个实例上执行
```redshift
 $ flushall
```
操作，
清除所有的缓存(其实直接重启该redis实例更快一点)。

