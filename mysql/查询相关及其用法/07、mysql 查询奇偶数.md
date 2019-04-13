
## [原文](https://blog.csdn.net/zhazhagu/article/details/80452473)

# mysql 查询奇偶数



## 按位与
```mysql
select * from cinema WHERE id&1; 

```
## id先除以2然后乘2 如果与原来的相等就是偶数
```mysql
select * from cinema WHERE id=(id>>1)<<1; 
```
## 正则匹配最后一位
```mysql
select * from cinema WHERE id regexp '[13579]$';
select * from cinema WHERE id regexp '[02468]$';

```
## id计算
```mysql
select * from cinema WHERE id%2 = 1;
select * from cinema WHERE id%2 = 0;

```
## 与上面的一样
```mysql
select * from cinema WHERE mod(id, 2) = 1;
select * from cinema WHERE mod(id, 2) = 0;

```
## -1的奇数次方和偶数次方
```mysql
select * from cinema WHERE POWER(-1, id) = -1;
select * from cinema WHERE POWER(-1, id) = 1; 

```