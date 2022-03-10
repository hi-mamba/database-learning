
##### [原文](https://www.jianshu.com/p/cca59b515e20)

# AUTO_INCREMENT 原理

## 引言
MySQL中auto_increment字段估计大家都经常用到，特别是innodb引擎。
我也经常用，只知道`mysql可以保证这个字段在多进程操作时的原子性`，具体原理又是什么，
后来查阅了MySQL手册以及相关资料，了解了个大概。

本文只探究了mysql5.5中innodb引擎auto_increment的问题。

## 定义
- 使用auto_increment的字段可能生成唯一的标识。

## 如何使用
- 可在建表时可用“AUTO_INCREMENT=n”选项来指定一个自增的初始值。

- 可用`alter table table_name AUTO_INCREMENT=n`命令来重设自增的起始值。

## 使用规范

- AUTO_INCREMENT是数据列的一种属性，只`适用`于`整数类型`数据列。

- 设置AUTO_INCREMENT属性的数据列应该是一个`正数序列`，所以应该把该数据列声明为`UNSIGNED`，这样序列的编号个可增加一倍。

- AUTO_INCREMENT数据列必须有`唯一索引`，以避免序号重复(即是主键或者主键的一部分)。

- AUTO_INCREMENT数据列必须具备`NOT NULL`属性。

- AUTO_INCREMENT数据列序号的`最大值`受该列的`数据类型约束`，
如TINYINT数据列的最大编号是127,如加上UNSIGNED，则最大为255。`一旦达到上限，AUTO_INCREMENT就会失效`。

- 当`进行全表删除时`，MySQL AUTO_INCREMENT会`从1重新开始`编号。全表删除的意思是发出以下两条语句时：
```mysql
delete from table_name;
或者
truncate table table_name
```
## 自增字值保存在哪里

不同的表引擎对于`auto_incrment`处理是不同的

- MyIsam表是保存在`数据结构`中（保存在文件里）
- Innodb表是保存在`内存`中的
  - 5.7以及之前的版本是保存在`内存`中，每次`数据库启动`时候会查找表的`max(id)`，然后`+1`。
  如果这时候有`auto_incrment=11,id=10,`如果这条id=10的数据被删除后从起mysql，Auto_incrment的`值又变成10`
  - 在Mysql 8.0中auto_incrment的值保存在`redolog`中，依靠`redolog来恢复`
  
### 传统auto_increment原理

> innodb引擎的表中的auto_increment字段是通过在`内存`中维护一个`auto-increment计数器`,
且每次访问auto-increment计数器的时候, 
INNODB都会加上一个名为`AUTO-INC锁`直到该语句结束(注意锁只持有到语句结束,不是事务结束).
`AUTO-INC锁`是一个`特殊的表级别的锁`

传统的auto_increment实现机制：mysql innodb引擎的表中的auto_increment字段是通过在`内存`中维护一个`auto-increment计数器`，
来实现该字段的赋值，注意`自增字段必须是索引`,而且是`索引的第一列`,不一定要是主键。
例如我现在在我的数据库test中创建一个表t，语句如下:
```mysql
CREATE TABLE t (a bigint unsigned auto_increment primary key) ENGINE=InnoDB;
```
则字段a为auto_increment类型，在mysql服务器启动后，第一次插入数据到表t时，InnoDB引擎会执行等价于下面的语句:
```mysql
SELECT MAX(id) FROM t FOR UPDATE;
```
Innodb获取到当前表中a字段的最大值并将增加1(默认是增加1，如果要调整为增加其他数目，
可以设置auto_increment_increment这个配置的设置)然后赋值给该列以及内存中该表对应的计数器。

如果表t为空，则InnoDB用来设置的值为为1.当然这个默认值夜可以通过 auto_increment_offset这个配置项来修改。

auto-increment计数器初始化以后，如果插入数据没有指定auto_increment列的值，
则Innodb直接增加auto-increment计数器的值并将增加后的值赋给新的列。
如果插入数据指定了auto_increment列的值且这个值大于该表当前计数器的值，则该表计数器的值会被设置为该值。

插入数据时如果指定auto_increment列的值为`NULL或者0`,则和你没有指定这个列的值一样,mysql会`从计数器中分配`一个值给该列.
而如果指定auto_increment列的值为`负数`或者`超过该列所能存储的最大数值`,则该行为在mysql中没有定义,
可能会出现问题.根据我的测试来看,插入负值会有`警告`,不过最终存储的数据还是正确的.
如果是超过了比如上面定义的表t的bigint类型的最大值,同样会有警告,而且插入的数值是bigint类型所能存储的最大值18446744073709551615.

在传统的auto_increment设置中,每次访问auto-increment计数器的时候, 
INNODB都会加上一个名为`AUTO-INC锁`直到该语句结束(注意`锁只持有到语句结束,不是事务结束`).`AUTO-INC锁`是一个`特殊的表级别的锁`,
用来提升包含auto_increment列的并发插入性能.因此,两个事务不能同时获取同一个表上面的AUTO-INC锁,
如果持有AUTO-INC锁太长时间可能会影响到数据库性能(比如INSERT INTO t1... SELECT ... FROM t2这类语句).

### 改进后

> innodb_autoinc_lock_mode=1: bulk inserts采用`AUTO-INC锁`这种方式，
simple inserts，采用了一种新的`轻量级的互斥锁
> innodb_autoinc_lock_mode=2：则模式下任何类型都不会采用锁

鉴于传统auto_increment机制要加AUTO-INC这种`特殊的表级锁`,`性能还是太差`,于是在mysql5.1开始,
`新增`加了一个配置项`innodb_autoinc_lock_mode`来设定auto_increment方式,可以设置的值为0,1,2，
其中0`就是第一节中描述的传统auto_increment机制`,而1和2则是`新增加的模式`,`默认该值`为1,
可以中mysql配置文件中修改该值，这里主要来看看这两种新的方式的差别，在描述差别前需要先明确`几个插入类型`：

- 1）simple inserts

simple inserts指的是那种能够事先`确定插入行数`的语句，比如INSERT/REPLACE INTO 等插入`单行`或者`多行`的语句，
语句中不包括`嵌套子查询`。此外，INSERT INTO ... ON DUPLICATE KEY UPDATE这类语句也要`除外`。

- 2）bulk inserts

bulk inserts指的是事先`无法确定插入行`数的语句，比如INSERT/REPLACE INTO ... SELECT, LOAD DATA等。

- 3）mixed-mode inserts

指的是simple inserts类型中有些行指定了auto_increment列的值`有些没有指定`(会分配过多的id，而导致“浪费)，比如：
> INSERT INTO t1 (c1,c2) VALUES (1,'a'), (NULL,'b'), (5,'c'), (NULL,'d');

另外一种mixed-mode inserts是 INSERT ... ON DUPLICATE KEY UPDATE这种语句，可能导致分配的auto_increment值没有被使用。
(会分配过多的id，而导致“浪费)


#### 下面看看设置innodb_autoinc_lock_mode为不同值时的情况：

- innodb_autoinc_lock_mode=0（traditional lock mode `传统模式` ）

传统的auto_increment机制，这种模式下所有针对auto_increment列的插入操作都会加`AUTO-INC锁`，
分配的值也是一个个分配，是连续的，正常情况下也不会有空洞（当然如果`事务rollback了这个auto_increment值就会浪费掉`，从而造成空洞）。

- innodb_autoinc_lock_mode=1（consecutive lock mode `连续模式` ）

这种情况下，针对bulk inserts才会采用`AUTO-INC锁`这种方式，而针对simple inserts，
则采用了一种新的`轻量级的互斥锁`来分配auto_increment列的值。当然，如果其`他事务已经持有了AUTO-INC锁`，则`simple inserts需要等待`.

需要注意的是，在innodb_autoinc_lock_mode=1时，语句之间是可能出现`auto_increment值的间隔`的。
比如`mixed-mode inserts`以及`bulk inserts`中都有可能导致一些分配的auto_increment值被浪费掉从而导致空洞。后面会有例子。

- innodb_autoinc_lock_mode=2（interleaved lock mode `交叉模式` ）

这种模式下任何类型的inserts都不会采用AUTO-INC锁，性能最好，但是在`同一条语句内部产生auto_increment值空洞`。
此外，这种模式对`statement-based replication也不安全`。


## 可能产生空洞原因总结

经过上面的文档分析，下面总结下针对auto_increment字段的各种类型的inserts语句可能出现空洞问题的原因：

- simple inserts

针对innodb_autoinc_lock_mode=0,1,2，只有在一个有auto_increment列操作的事务出现回滚时，
分配的auto_increment的值会丢弃不再使用，从而造成空洞。

- bulk inserts（这里就不考虑事务回滚的情况了，事务回滚是会造成空洞的）

  - innodb_autoinc_lock_mode=0,由于一直会持有AUTO-INC锁直到语句结束，生成的值都是连续的，不会产生空洞。  
  - innodb_autoinc_lock_mode=1，这时候一条语句内不会产生空洞，但是`语句之间可能会产生空洞`。后面会有例子说明。  
  - innodb_autoinc_lock_mode=2，如果有并发的insert操作，那么同一条语句内都可能`产生空洞`。

- mixed-mode inserts

这种模式下针对innodb_autoinc_lock_mode的值配置不同，结果也会不同，当然innodb_autoinc_lock_mode=0时时不会产生空洞的，
而innodb_autoinc_lock_mode=1以及innodb_autoinc_lock_mode=2是会`产生空洞`的。后面例子说明。

`另外注意的一点是，在master-slave这种架构中，复制如果采用statement-based replication这种方式，
则innodb_autoinc_lock_mode=0或1才是安全的。而如果是采用row-based replication或者mixed-based replication，
则innodb_autoinc_lock_mode=0,1,2都是安全的`



## 例子省略



