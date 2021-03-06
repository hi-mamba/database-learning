
[toc]

# 数据库

## MySQL数据类型char与varchar中数字代表的究竟是字节数还是字符数?

存的是字符，所以varchar(n)  n是多少就能存多少个汉字或者多少字母.

比如varchar(10) 就可以存十个汉字，或者 对于非中文字符串，可以插入包含12个字符以及小于12个字符的字符串.



## Mysql int(n) ,varchar(n)的意义？

第一个 n 只是显示多少数字，而不是长度!

第二个 n 是最大保存的字符个数.不是字节(一个汉字一个字符，一个字母也是一个字符)

---

## 数据库插入和删除一条数据的过程在底层是如何执行 ？

mysql是目前市面上应用非常广泛的关系型数据库.

当插入,更新,删除等sql语句运行后,mysql为何总能高效,快速的执行,而且不管是断电,mysql进程崩溃,
还是一些其它非正常因素,mysql总能保持数据完整,

本文将带着这些问题探秘mysql底层默认存储引擎InnoDB(Mysql5.5之后)的执行过程.

#### 问题: InnoDB事务提交后在底层都干了什么?
当提交一个事务时,实际上它干了如下2件事:

> 一:  InnoDB存储引擎把事务写入日志缓冲(log buffer),日志缓冲把事务刷新到事务日志.

> 二:  InnoDB存储引擎把事务写入缓冲池(Buffer pool).

做完上面2件事,整个事务提交就完成了.

InnoDB通过事务日志把随机IO变成顺序IO,这大大的提高了InnoDB写入时的性能.

因为把缓冲池的脏页数据刷新到磁盘可能会涉及大量随机IO,这些随机IO会非常慢,通过事务日志,避开随机IO,用顺序IO替代它.

但如果此时机器断电或者意外崩溃,那脏页数据没刷新到磁盘,岂不是数据会丢失? 

答案是否定的, mysql意外崩溃后,重启时.会根据事务日志重做事务,恢复所有buffer pool中丢失的脏页.

上面的过程是在未开启binlog的情况下的执行过程,binlog的基本配置如下: 

#【开启二进制日志】 
```
log_bin = mysql-bin
server_id = 2 
#【中继日志的位置和命名】 
relay_log = mysql-relay-bin
# 【允许备库将其重放的事件也记录到自身的二进制文件中】
log_slave_updates = 1
#【sync_binlog 实时刷新】
sync_binlog = 1
```
binlog的相关情况不再本文的介绍范围内,不再展开说明.


让我们来看看InnoDB的缓存和文件关系,
如图1:
![](https://img-blog.csdn.net/20150808203621428?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

图1


这里面有几个核心的组件:


 ##### 1, 缓冲池(buffer pool).
 
事务提交后,InnoDB首先在缓冲池中找到对应的页,把事务更新到缓冲区中.
当刷新脏页到磁盘时,缓冲区都干了什么?

缓冲区把脏页拷贝到double write buffer,double wirte buffer把脏页刷新到double write磁盘(这也是一次顺序IO),再把脏页刷新到数据文件中.

当然缓冲池中还有其他组件,也非常重要,如插入缓冲,该缓冲区是为了高效维护二级非唯一索引所做的优化,把多次IO转化为一次IO来达到快速更新的目的.这里不再展开说明.

##### 2, 日志缓冲(log buffer)
InnoDB使用日志来减少事务提交时的开销.因为日志记录了事务,就无须在每个事务提交时把缓冲池中的脏块刷新到磁盘.因为刷新缓冲池到磁盘一般是随机IO.

InnoDB的日志缓冲有两个重要的参数需要介绍下:

innodb_log_buffer_size 日志缓冲区大小(5.6 默认8M,一般不需要设置太大,除非有BLOB字段)

innodb_flush_log_at_trx_commit  这是InnoDB刷新事务日志的策略参数,默认为1. 

刷新策略值: 
```
      0,  一秒钟刷新一次,事务提交时,不做任何操作.(可能丢失1秒钟事务数据)
      1,  每次事务都提交刷新到持久化存储(默认&最安全)
      2,  每次提交时把日志缓冲写到日志文件,但并不刷新.  
```
1和3的区别是: mysql进程挂了,3不会丢事务. 服务器断电或者挂了, 都丢失事务. 把缓冲写到日志是简单的把数据从INNODB的内存缓冲转移到操作系统缓冲.

##### 3, 事务日志 
这里面有2个重要的配置参数需要说明下.

2.1)  innodb_log_file_size mysql 5.6默认的大小是50M

2.2)  innodb_log_files_in_group  mysql5.6默认是2,如下图:

![](https://img-blog.csdn.net/20150808204842068?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)


也就是说,InnoDB默认的事务日志文件大小总和是100M。这对高性能工作来说可能太小了,有时需要几百兆甚至几个G的事务日志空间.

linux可通过/etc/my.cnf 来修改事务日志文件的大小, windows是my.ini配置文件

innodb日志是环行方式写的:当写到日志的尾部,会重新跳转到开头继续写,但不会覆盖还没应用到数据文件的日志记录,因为这样会清理掉已提交事务的唯一持久化记录.

日志文件太小,InnoDB将必须做更多的检查点,导致更多的日志写,在日志没有空间继续写入前,必须等待变更被应用到数据文件,写语句可能会被拖累.

但日志文件太大,在崩溃恢复时InnoDB可能不得不做大量的工作,增加恢复时间. 应该在这之间找到平衡,设置合适的日志大小.

##### 4, 双写缓冲
缓冲池刷新脏页面到磁盘时,首先把它们写到双写缓冲,然后再把它们写到所属的数据区域中.

那岂不是所有的脏页都需要写2遍？对,就是写2遍. 但双写缓冲是顺序的,对写冲击比较小.

有些备库上可以禁止双写缓冲,另外一些文件系统(ZFS)做了同样的事，所以没必要让InnoDB做2次, innodb_doublewirte 来关闭。

InnoDb用双写缓冲来避免页没写完整所导致的数据损坏.


双写缓冲的架构如下图：
![](https://img-blog.csdn.net/20150808213620334?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)
 

从缓冲池中拷贝页到double_write_buffer,double_write_buffer刷新到double_write(共享表空间),再调fsync()同步磁盘

###     总结:
```  
 1, InnoDB提交事务过程如下:

     1.1):  把事务写入日志缓冲(log buffer),日志缓冲把事务刷新到事务日志.

     1.2):  把事务写入缓冲池(Buffer pool).

 2,  Innodb存储引擎在事务提交后,是把随机IO转化为顺序IO来达到快速提交事务的目的.

 3,  每次刷新脏页到磁盘,实际上是2次写页到磁盘. 

     3.1):  刷新脏页到双写缓冲,顺序IO

     3.2):  调用一次fsync()刷新到磁盘,随机IO

 4,  宕机或者意外崩溃重启mysql时,根据事务日志来重做日志恢复缓冲池未来得及刷新到磁盘的脏页,保证数据完整性.
```

##### 最后给大家提一个问题:

Q:  如果发生写失效(页16KB数据,只写了8Kb),可以通过重做日志进行恢复,为什么还需要double_write?

  重做日志中记录的是对页的物理操作,如果页本身已经发生了毁坏,再对其重做是没有意义的,会发生数据丢失的情况 
  
  
  
## mysql数据表引擎InnoDB和MyISAM的特点？

### 1、MyISAM表引擎特点

（1）MyISAM 是MySQL缺省存贮引擎

（2）具有检查和修复表格的大多数工具. 

（3）表格可以被压缩

（4）支持全文搜索.

（5）不是事务安全的.如果事物回滚将造成不完全回滚，不具有原子性。

（6）不支持外键。

（7）如果执行大量的SELECT，MyISAM是更好的选择。

（8）每张MyISAM 表被存放在三个文件 ：frm 文件存放表格定义，数据文件是MYD (MYData)，索引文件是MYI (MYIndex) 引伸。

（9）表是保存成文件的形式,在跨平台的数据转移中使用MyISAM存储会省去不少的麻烦

（10）较好的键统计分布

（11）较好的auto_increment处理
总结：

读取操作在效率上要优于InnoDB.小型应用使用MyISAM是不错的选择.并发性弱于InnoDB。

### 2、innodb表引擎特点

（1）提供了具有事务提交、回滚和崩溃修复能力的事务安全型表。

（2）提供了行锁，提供与 Oracle 类型一致的不加锁读取。

（3）表中不需要扩大锁定，因为 InnoDB 的列锁定适宜非常小的空间。

（4）提供外键约束。

（5）设计目标是处理大容量数据库系统，它的 CPU 利用率是其它基于磁盘的关系数据库引擎所不能比的。

（6）在主内存中建立其专用的缓冲池用于高速缓冲数据和索引。 

（7）把数据和索引存放在表空间里，可能包含多个文件，这与其它的不一样，举例来说，在MyISAM 中，表被存放在单独的文件中。

（8）表的大小只受限于操作系统的文件大小，一般为 2 GB。

（9）所有的表都保存在同一个数据文件 ibdata1 中(也可能是使用独立的表空间文件的多个文件,使用共享表空间时比较不好备份单独的表)，免费的方案可以是拷贝数据文件、备份 binlog，或者用 mysqldump。

### 总结：

这些特性均提高了多用户并发操作的性能表现。

注意：

对于支持事物的InnoDB类型的表，影响速度的主要原因是AUTOCOMMIT默认设置是打开的，而且程序没有显式调用BEGIN 开始事务，导致每插入一条都自动Commit，严重影响了速度。即使autocommit打开也可以,可以在执行sql前调用begin，多条sql形成一个事务;
或者不打开AUTOCOMMIT配置，将大大提高性能。

## 主键设计原则

总原则：根据数据库表的具体使用范围来决定采用不同的表主键定义。


2.1 确保主键的无意义性
     在开发过程中，有意义的字段例如“用户登录信息表”将“登录名”（英文名）作为主键，
     “订单表”中将“订单编号”作为主键，如此设计主键一般都是没什么问题，因为将这些主键基本不具有“意义更改”的可能性。

但是，也有一些例外的情况，例如“订单表”需要支持需求“订单可以作废，并重新生成订单，
而且订单号要保持原订单号一致”，那将“订单编号”作为主键就满足不了要求了。

因此在使用具有实际意义的字段作为主键时，需要考虑是否存在这种可能性。

要用代理主键，不要使用业务主键。任何一张表，强烈建议不要使用有业务含义的字段充当主键。
我们通常都是在表中单独添加一个整型的编号充当主键字段。



2.2 采用整型主键

主键通常都是整数，不建议使用字符串当主键。（如果主键是用于集群式服务，可以采用字符串类型）

2.3 减少主键的变动
       主键的值通常都不允许修改，除非本记录被删除。

2.4 避免重复使用主键
       主键的值通常不重用，意味着记录被删除后，该主键值不再使用。

2.5 主键字段定义区分
主键不要直接定义成【id】，而要加上前缀，定义成【表名id】或者【表名_id】


### 3、MyISAM表和InnoDB表差别

（1）InnoDB类型支持事务处理,MyISAM类型不支持

（2）InnoDB不支持FULLTEXT类型的索引，MyISAM支持。

（3）InnoDB提供了行锁,MyISAM写入时锁表。

InnoDB表的行锁也不是绝对的，如果在执行一个SQL语句时MySQL不能确定要扫描的范围，InnoDB表同样会锁全表，例如 update table set num=1 where name like “%aaa%”


（4）InnoDB 中不保存表的具体行数，也就是说，执行select count(*) from table时，InnoDB要扫描一遍整个表来计算有多少行；
但是MyISAM只要简单的读出保存好的行数即可。
当count(*)语句包含 where条件时，两种表的操作是一样的。

（5）DELETE FROM table时，InnoDB不会重新建立表，而是一行一行的删除，MyISAM重建表。(重新建表是什么意思?)


（6）InnoDB不支持LOAD TABLE FROM MASTER操作（表的拷贝从主服务器转移到从属服务器）；MyISAM表支持。

解决方法是首先把InnoDB表改成MyISAM表，导入数据后再改成InnoDB表，但是对于使用的额外的InnoDB特性(例如外键)的表不适用。

（7）对于AUTO_INCREMENT类型的字段，InnoDB中必须包含只有该字段的索引；但是在MyISAM表中，可以和其他字段一起建立联合索引。

### 4、事务测试

(1）事务表创建

使用启动mysql命令如下，只影响到create语句
> mysqld-max-nt --standalone --default-table-type=InnoDB

创建表命令如下：
```
use test;
drop table if exists tn;
create table tn (a varchar(10));
```

查看表的类型
> show create table tn;


(2）事务表切换

临时改变默认表类型可以用：
```
set table_type=InnoDB;
show variables like 'table_type';
```

可以执行以下命令来切换非事务表到事务表(数据不会丢失)：

> alter table tablename type=innodb;

（3）事务使用

创建表默认是 myisam表类型。

对不支持事务的表做start/commit操作没有任何效果，在执行commit前已经提交，测试：

执行一个msyql：
```
use test;
drop table if exists tm;
create table tn (a varchar(10)) type=myisam;
drop table if exists tn;
create table ty (a varchar(10)) type=innodb;
begin;
insert into tm values('a');
insert into tn values('a');
select * from tm;
select * from tn;
```
都能看到一条tm表的记录


执行另一个mysql：
```
use test;
select * from tm;
select * from tn;
```
只有tm能看到一条记录
只有在原来那边 commit tn表;
才都能看到tn表的记录。

5、性能测试
针对业务类型来选择使用恰当的数据引擎，才能最大的发挥MySQL的性能优势.

【分析】
（1）innodb_flush_log_at_trx_commit  （日志提交，这个选项很管用） 
抱怨Innodb比MyISAM慢 100倍？那么你大概是忘了调整这个值。默认值1的意思是每一次事务提交或事务外的指令都需要把日志写入（flush）硬盘，这是很费时的。特别是使用电 池供电缓存（Battery backed up cache）时。设成2对于很多运用，
特别是从MyISAM表转过来的是可以的，它的意思是不写入硬盘而是写入系统缓存。日志仍然会每秒flush到硬 盘，所以你一般不会丢失超过1-2秒的更新。设成0会更快一点，但安全方面比较差，如果MySQL挂了可能会丢失事务的数据。而值2只会在整个操作系统 挂了时才可能丢数据。 
可以看出在MySQL 5.0里面，MyISAM和InnoDB存储引擎性能差别并不是很大，针对InnoDB来说，影响性能的主要是 innodb_flush_log_at_trx_commit 这个选项，如果设置为1的话，那么每次插入数据的时候都会自动提交，导致性能急剧下降，应该是跟刷新日志有关系，设置为0效率能够看到明显提升，当然，同样你可以SQL中提交“SET AUTOCOMMIT = 0”来设置达到好的性能。

（2）innodb_buffer_pool_size（作用是缓存表的索引（主要是innodb表）和数据，插入数据时的缓冲）
如果用Innodb，那么这是一个重要变量。相对于MyISAM来说，Innodb对于buffer size更敏感。MyISAM可能对于大数据量使用默认的key_buffer_size也还好，但Innodb在大数据量时用默认值就感觉在爬了。 Innodb的缓冲池会缓存数据和索引，所以不需要给系统的缓存留空间，如果只用Innodb，可以把这个值设为内存的70%-80%。和 key_buffer相同，如果数据量比较小也不怎么增加，那么不要把这个值设太高也可以提高内存的使用率。
配置修改如下（操作系统内存的70%-80%最佳，如果系统内存8G）：
innodb_buffer_pool_size = 6G
此外，这个参数是非动态的，要修改这个值，需要重启mysqld服务。所以设置的时候要非常谨慎。并不是设置的越大越好。设置的过大，会导致system的swap空间被占用，导致操作系统变慢，从而减低sql查询的效率。
另外，还听说通过设置innodb_buffer_pool_size能够提升InnoDB的性能，但是测试发现没有特别明显的提升。

### 6、总结
InnoDB自身很多良好的特点，比如事务支持、存储过程、视图、行级锁定等等。

在并发很多的情况下，InnoDB的表现要比MyISAM强很多。

InnoDB 和 MyISAM之间的区别： 

1>.InnoDB支持事物，而MyISAM不支持事物

2>.InnoDB支持行级锁，而MyISAM支持表级锁

3>.InnoDB支持MVCC, 而MyISAM不支持

4>.InnoDB支持外键，而MyISAM不支持

5>.InnoDB不支持全文索引，而MyISAM支持


--- 


####  MySQL 体系架构和存储引擎
 
![](https://upload-images.jianshu.io/upload_images/4914401-c223c6578a6564b6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

mysql是数据库也是数据库实例

mysql  是一个单进程多线程架构的数据库  daemon 守护进程

当启动实例时，MySQL数据库会去读取配置文件，根据配置文件的参数来启动数据库实例。

用以下命令可以查看当Mysql 数据库实例启动时，会在哪些位置查找配置文件。

> mysql —help | grep my.cnf

![](https://upload-images.jianshu.io/upload_images/4914401-a6831009f0706e83.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

#### mysql由一下几部分组成：

- 连接池组件

- 管理服务和工具组件

- sql接口组件

- 查询分析器组件

- 优化器组件

- 缓冲（cache）组件

- 插件式存储引擎

- 物理文件

![](https://upload-images.jianshu.io/upload_images/4914401-27c140d22f47ebd7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)



最大的特点就是其插件式的表存储引擎。存储引擎是基于表的，而不是数据库。

mysql独有的插件式体系架构，存储引擎的是mysql区别于其他数据库的一个重要的特性。存储引擎的好处是，每个存储引擎都有各自的特点，能够根据具体的应用建立不同存储引擎表。

MySql 存储引擎的改进http:/code.google.com.p/mysql-heap-dynamic-rows/

MySQL 数据库开源特性，存储引擎可以分为MySql官方存储引擎和第三方存储引擎。Inno存储引擎，是mysql 数据库OLTP（online transaction Processing在线事务处理）应用中使用最广泛的存储引擎。

#### 1.3.1 InnoDB存储引擎

InnoDB存储引擎支持事务，其设计目标主要面向在线事务OLTP的应用。其特点是行级锁设计、支持外键，并支持类似于Oracle的非锁定读，从5.5.8开始InnoDB存储引擎是默认的存储引擎。

InnoDB通过使用多版本并发控制MVCC来获得高并发性，并且实现了SQL标准的四种隔离级别，默认的为REPEATABLE级别，同时使用一种被称为next-key locking的策略来避免幻读（phantom）现象的产生。除此之外，InnoDB存储引擎还提供了插入缓冲（Insert buffer）、二次写（double write）、自适应哈希索引（adaptive hash index）、预读（read ahead）等高性能和高可用的功能。

对于表中的数据存储，InnoDB存储引擎采用聚集（cluster）的方式，因此每张表的存储都是按主键的顺序进行存放。如果没有显式地在表定义时指定主键，InnoDB存储引擎会为每一行生成一个6个字节的ROWID ，并以此作为主键。

#### 1.3.2 MyISAM存储引擎

MyISAM存储引擎不支持事务、表锁设计，支持全文索引，主要面向一些OLAP数据库应用。

1.3.3 NDB 存储引擎是一个集群存储引擎，类似于oracle的RAC集群，不过Oracle，Oracle RAC share everything 架构不同是，器结构是share nothing的集群架构，因此能够提供更高的可用性。NDB的特点是数据全部放在内存中，因此主键查询（primary key lookups）的速度极快，并且通过添加NDB数据存储节点（data Node）可以线性地提高数据库性能，是高可用、高性能的集群系统。

关于NDB存储引擎有一个问题值得注意，那就是NDB存储引擎的链接操作JOIN时在MySQL数据库层完成的，而不是在存储引擎层完成的，这意味着复杂的链接操作需要巨大的网络开销，因此查询速度很慢，如果解决了这个问题，NDB存储引擎的市场应该是非常大的。

#### 1.3.4 Memory存储引擎

Memory存储引擎（之前称之为HEAP存储引擎）将表中的数据存放在内存中，如果数据库重启或者发生奔溃，表中的数据将消失。它非常适合用于存储临时数据的临时表，以及数据仓库中的维度表。Memory存储引擎默认使用hash索引，而不是我们熟悉的B+树索引。

Memory存储引擎速度快，但只支持表锁，并发性能较差，并且不支持TEXT和BLOB列类型，最重要的是，村粗变长字段varchar时是按照定常字段方式进行的，因此会浪费内存。

#### 1.3.5 Archive 存储引擎

Archve 存储引擎只支持INSERT 和SELECT操作，从MySQL开始支持索引。

#### 1.3.6 Federated 存储引擎

#### 1.3.7 Maria 存储引擎

Maria存储引擎是新开发的引擎，设计目标主要是用来取代原有的MyISAM存储殷勤，从而成为MySQL的默认存储引擎。Maria存储引擎的开发者是MySQL的创始人之一。Maria存储引擎的特点是：支持缓存数据和索引文件，应用了行锁设计，提供了MVCC功能，支持事务和非事务安全的选项，以及更好的BLOB字符类型的处理性能。

总结： MySQL 的InnoDB 存储引擎的效率在OLTP中效率更好，对于ETL MyISAM存储引擎更具有优势。


 
转载
<https://blog.csdn.net/chenjiayi_yun/article/details/45746989>\
<https://www.jianshu.com/p/60f03b16e7ff>

参考：

<https://github.com/jaywcjlove/mysql-tutorial/blob/master/chapter3/3.5.md>

--- 



## 乐观锁和悲观锁的区别？

#### 悲观锁

悲观锁（Pessimistic Lock），顾名思义，就是很悲观，每次去拿数据的时候都认为别人会修改，所以每次在拿数据的时候都会上锁，这样别人想拿这个数据就会block直到它拿到锁。

悲观锁：假定会发生并发冲突，屏蔽一切可能违反数据完整性的操作。

Java synchronized 就属于悲观锁的一种实现，每次线程要修改数据时都先获得锁，保证同一时刻只有一个线程能操作数据，其他线程则会被block。

#### 乐观锁

乐观锁（Optimistic Lock），顾名思义，就是很乐观，每次去拿数据的时候都认为别人不会修改，所以不会上锁，但是在提交更新的时候会判断一下在此期间别人有没有去更新这个数据。乐观锁适用于读多写少的应用场景，这样可以提高吞吐量。

乐观锁：假设不会发生并发冲突，只在提交操作时检查是否违反数据完整性。

乐观锁一般来说有以下2种方式：

- 使用数据版本（Version）记录机制实现，这是乐观锁最常用的一种实现方式。何谓数据版本？即为数据增加一个版本标识，一般是通过为数据库表增加一个数字类型的 “version” 字段来实现。当读取数据时，将version字段的值一同读出，数据每更新一次，对此version值加一。当我们提交更新的时候，判断数据库表对应记录的当前版本信息与第一次取出来的version值进行比对，如果数据库表当前版本号与第一次取出来的version值相等，则予以更新，否则认为是过期数据。

> 乐观锁就在更新的那一瞬间锁了下，悲观锁从准备开始更新操作时就加锁，锁的时间比乐观锁长。

- 使用时间戳（timestamp）。乐观锁定的第二种实现方式和第一种差不多，同样是在需要乐观锁控制的table中增加一个字段，名称无所谓，字段类型使用时间戳（timestamp）, 和上面的version类似，也是在更新提交的时候检查当前数据库中数据的时间戳和自己更新前取到的时间戳进行对比，如果一致则OK，否则就是版本冲突。

具体可通过给表加一个版本号或时间戳字段实现，当读取数据时，将version字段的值一同读出，数据每更新一次，对此version值加一。
当我们提交更新的时候，判断当前版本信息与第一次取出来的版本值大小，如果数据库表当前版本号与第一次取出来的version值相等，则予以更新，否则认为是过期数据，拒绝更新，让用户重新操作。
 
 
Java JUC中的atomic包就是乐观锁的一种实现，AtomicInteger 通过CAS（Compare And Set）操作实现线程安全的自增。
 
 
<https://www.jianshu.com/p/f5ff017db62a> \
<https://blog.csdn.net/daybreak1209/article/details/51606939>


## 数据库隔离级别是什么？有什么作用？
 
隔离级别 | 脏读 | 不可重复读 | 幻读
---|---|---|---
未提交读（Read uncommitted）| 可能    |  可能 | 可能
已提交读（Read committed）  | 不可能  | 可能   | 可能
可重复读（Repeatable read） | 不可能  | 不可能 | 可能
可串行化（Serializable ）   | 不可能  |  不可能 | 不可能
 

- 未提交读(Read Uncommitted)：允许脏读，也就是可能读取到其他会话中未提交事务修改的数据

- 提交读(Read Committed)：只能读取到已经提交的数据。Oracle等多数数据库默认都是该级别 (不重复读)

- 可重复读(Repeated Read)：可重复读。在同一个事务内的查询都是事务开始时刻一致的，InnoDB默认级别。在SQL标准中，该隔离级别消除了不可重复读，但是还存在幻象读

- 串行读(Serializable)：完全串行化的读，每次读都需要获得表级共享锁，读写相互都会阻塞


<https://tech.meituan.com/innodb-lock.html> \
<http://www.cnblogs.com/zhoujinyi/p/3437475.html>


## MySQL主备同步的基本原理。

#### (3) 用途和条件
##### 1)、mysql主从复制用途
 - ●实时灾备，用于故障切换
 - ●读写分离，提供查询服务
 -  ●备份，避免影响业务

##### 2)、主从部署必要条件：
 - ●主库开启binlog日志（设置log-bin参数）
 - ●主从server-id不同
 - ●从库服务器能连通主库

### 二、主从同步的粒度、原理和形式：

#### (1)、 三种主要实现粒度
详细的主从同步主要有三种形式：statement、row、mixed
-　1)、statement: 会将对数据库操作的sql语句写道binlog中
-　2)、row: 会将每一条数据的变化写道binlog中。
-   3)、mixed: statement与row的混合。Mysql决定何时写statement格式的binlog, 何时写row格式的binlog。

#### (2)、主要的实现原理、具体操作、示意图

#### 1)、在master机器上的操作：
当master上的数据发生变化时，该事件变化会按照顺序写入bin-log中。
当slave链接到master的时候，master机器会为slave开启binlog dump线程。
当master的binlog发生变化的时候，bin-log dump线程会通知slave，并将相应的binlog内容发送给slave。

#### 2)、在slave机器上操作：
当主从同步开启的时候，slave上会创建两个线程：I\O线程。

该线程连接到master机器，master机器上的binlog dump 线程会将binlog的内容发送给该I\O线程。
　  该I/O线程接收到binlog内容后，再将内容写入到本地的relay log；

sql线程。该线程读取到I/O线程写入的ralay log。
并且根据relay log 的内容对slave数据库做相应的操作。

#### 3)、MySQL主从复制原理图如下:


![image](https://img-blog.csdn.net/20180313225542529)

- 从库生成两个线程，一个I/O线程，一个SQL线程；
- i/o线程去请求主库 的binlog，并将得到的binlog日志写到relay log（中继日志） 文件中；
- 主库会生成一个 log dump 线程，用来给从库 i/o线程传binlog；
- SQL 线程，会读取relay log文件中的日志，并解析成具体操作，来实现主从的操作一致，
而最终数据一致；


#### MySQL数据库主从同步过程解析。
复制的基本过程如下：

- Slave上面的IO进程连接上Master，并请求从指定日志文件的指定位置（或者从最开始的日志）之后的日志内容；

- Master接收到来自Slave的IO进程的请求后，通过负责复制的IO进程根据请求信息读取制定日志指定位置之后的日志信息，返回给Slave 的IO进程。返回信息中除了日志所包含的信息之外，还包括本次返回的信息已经到
Master端的bin-log文件的名称以及bin-log的位置；

- Slave的IO进程接收到信息后，将接收到的日志内容依次添加到Slave端的relay-log文件的最末端，并将读取到的Master端的 bin-log的文件名和位置记录到master-info文件中，以便在下一次读取的时候能够清楚的告诉Master“我需要从某个bin-log的哪个位置开始往后的日志内容，请发给我”；

- Slave的Sql进程检测到relay-log中新增加了内容后，会马上解析relay-log的内容成为在Master端真实执行时候的那些可执行的内容，并在自身执行。


### MySQL数据库主从同步延迟原理。

要说延时原理，得从mysql的数据库主从复制原理说起，mysql的主从复制都是单线程的操作，
主库对所有DDL和DML产生binlog，binlog是顺序写，所以效率很高，
slave的Slave_IO_Running线程到主库取日志，效率很比较高，下一步，问题来了，slave的Slave_SQL_Running线程将主库的DDL和DML操作在slave实施。
DML和DDL的IO操作是随即的，不是顺序的，成本高很多，还可能可slave上的其他查询产生lock争用，由于Slave_SQL_Running也是单线程的，所以一个DDL卡主了，需要执行10分钟，那么所有之后的DDL会等待这个DDL执行完才会继续执行，这就导致了延时。有朋友会问：“主库上那个相同的DDL也需要执行10分，为什么slave会延时？”，答案是master可以并发，Slave_SQL_Running线程却不可以。

### MySQL数据库主从同步延迟是怎么产生的。

当主库的TPS并发较高时，产生的DDL数量超过slave一个sql线程所能承受的范围，那么延时就产生了，当然还有就是可能与slave的大型query语句产生了锁等待


### MySQL数据库主从同步延迟解决方案。

1)、架构方面

1.业务的持久化层的实现采用分库架构，mysql服务可平行扩展，分散压力。

2.单个库读写分离，一主多从，主写从读，分散压力。这样从库压力比主库高，保护主库。

3.服务的基础架构在业务和mysql之间加入memcache或者redis的cache层。降低mysql的读压力。

4.不同业务的mysql物理上放在不同机器，分散压力。

5.使用比主库更好的硬件设备作为slave总结，mysql压力小，延迟自然会变小。

2)、硬件方面

1.采用好服务器，比如4u比2u性能明显好，2u比1u性能明显好。

2.存储用ssd或者盘阵或者san，提升随机写的性能。

3.主从间保证处在同一个交换机下面，并且是万兆环境。

总结，硬件强劲，延迟自然会变小。一句话，缩小延迟的解决方案就是花钱和花时间。

3)、mysql主从同步加速

1、sync_binlog在slave端设置为0

2、–logs-slave-updates 从服务器从主服务器接收到的更新不记入它的二进制日志。

3、直接禁用slave端的binlog

4、slave端，如果使用的存储引擎是innodb，innodb_flush_log_at_trx_commit =2

4)、从文件系统本身属性角度优化 


<https://blog.csdn.net/helloxiaozhe/article/details/79548186>
<https://blog.csdn.net/clh604/article/details/19680291>

--- 


## 如何从一张表中查出name字段包含“XYZ”的所有行？

like 前后匹配
> select * from temp where str like '%XYZ%'

find_in_set() 函数 好像匹配 完整字符串


## 索引数据结构（字典+BitTree）

### 索引本质
MySQL官方解释：索引是为MySQL提高获取数据效率的数据结构，为了快速查询数据。索引是满足某种特定查找算法的数据结构，而这些数据结构会以某种方式指向数据，从而实现高效查找数据。

### B+树
MySQL一般以B+树作为其索引结构，那么B+树有什么特点呢？

树度为n的话，每个节点指针上限为2n+1
非叶子节点不存储数据，只存储指针索引；叶子节点存储所有数据，不存储指针
在经典B+树基础上增加了顺序访问指针，每个叶子节点都有指向相邻下一个叶子节点的指针，如图所示。主要为了提高区间访问的性能，例如要找key为20到50的所有数据，只要按着顺序访问路线一次性访问所有数据节点。

 ![](https://upload-images.jianshu.io/upload_images/787365-a979aa05bf72eed5.png?imageMogr2/auto-orient/)
 
 
 
 
### MySQL索引原理 （美团）
#### 索引目的
索引的目的在于提高查询效率，可以类比字典，如果要查“mysql”这个单词，我们肯定需要定位到m字母，然后从下往下找到y字母，再找到剩下的sql。如果没有索引，那么你可能需要把所有单词看一遍才能找到你想要的，如果我想找到m开头的单词呢？或者ze开头的单词呢？是不是觉得如果没有索引，这个事情根本无法完成？

#### 索引原理
除了词典，生活中随处可见索引的例子，如火车站的车次表、图书的目录等。它们的原理都是一样的，通过不断的缩小想要获得数据的范围来筛选出最终想要的结果，同时把随机的事件变成顺序的事件，也就是我们总是通过同一种查找方式来锁定数据。
数据库也是一样，但显然要复杂许多，因为不仅面临着等值查询，还有范围查询(>、<、between、in)、模糊查询(like)、并集查询(or)等等。数据库应该选择怎么样的方式来应对所有的问题呢？我们回想字典的例子，能不能把数据分成段，然后分段查询呢？最简单的如果1000条数据，1到100分成第一段，101到200分成第二段，201到300分成第三段......这样查第250条数据，只要找第三段就可以了，一下子去除了90%的无效数据。但如果是1千万的记录呢，分成几段比较好？稍有算法基础的同学会想到搜索树，其平均复杂度是lgN，具有不错的查询性能。但这里我们忽略了一个关键的问题，复杂度模型是基于每次相同的操作成本来考虑的，数据库实现比较复杂，数据保存在磁盘上，而为了提高性能，每次又可以把部分数据读入内存来计算，因为我们知道访问磁盘的成本大概是访问内存的十万倍左右，所以简单的搜索树难以满足复杂的应用场景。

#### 磁盘IO与预读
前面提到了访问磁盘，那么这里先简单介绍一下磁盘IO和预读，磁盘读取数据靠的是机械运动，每次读取数据花费的时间可以分为寻道时间、旋转延迟、传输时间三个部分，寻道时间指的是磁臂移动到指定磁道所需要的时间，主流磁盘一般在5ms以下；旋转延迟就是我们经常听说的磁盘转速，比如一个磁盘7200转，表示每分钟能转7200次，也就是说1秒钟能转120次，旋转延迟就是1/120/2 = 4.17ms；传输时间指的是从磁盘读出或将数据写入磁盘的时间，一般在零点几毫秒，相对于前两个时间可以忽略不计。那么访问一次磁盘的时间，即一次磁盘IO的时间约等于5+4.17 = 9ms左右，听起来还挺不错的，但要知道一台500 -MIPS的机器每秒可以执行5亿条指令，因为指令依靠的是电的性质，换句话说执行一次IO的时间可以执行40万条指令，数据库动辄十万百万乃至千万级数据，每次9毫秒的时间，显然是个灾难。下图是计算机硬件延迟的对比图，供大家参考：
various-system-software-hardware-latencies
考虑到磁盘IO是非常高昂的操作，计算机操作系统做了一些优化，当一次IO时，不光把当前磁盘地址的数据，而是把相邻的数据也都读取到内存缓冲区内，因为局部预读性原理告诉我们，当计算机访问一个地址的数据的时候，与其相邻的数据也会很快被访问到。每一次IO读取的数据我们称之为一页(page)。具体一页有多大数据跟操作系统有关，一般为4k或8k，也就是我们读取一页内的数据时候，实际上才发生了一次IO，这个理论对于索引的数据结构设计非常有帮助。

### 索引的数据结构
前面讲了生活中索引的例子，索引的基本原理，数据库的复杂性，又讲了操作系统的相关知识，目的就是让大家了解，任何一种数据结构都不是凭空产生的，一定会有它的背景和使用场景，我们现在总结一下，我们需要这种数据结构能够做些什么，其实很简单，那就是：每次查找数据时把磁盘IO次数控制在一个很小的数量级，最好是常数数量级。那么我们就想到如果一个高度可控的多路搜索树是否能满足需求呢？就这样，b+树应运而生。


#### 详解b+树
b+树

![](https://tech.meituan.com/img/mysql_index/btree.jpg)

如上图，是一颗b+树，关于b+树的定义可以参见B+树，这里只说一些重点，浅蓝色的块我们称之为一个磁盘块，可以看到每个磁盘块包含几个数据项（深蓝色所示）和指针（黄色所示），如磁盘块1包含数据项17和35，包含指针P1、P2、P3，P1表示小于17的磁盘块，P2表示在17和35之间的磁盘块，P3表示大于35的磁盘块。真实的数据存在于叶子节点即3、5、9、10、13、15、28、29、36、60、75、79、90、99。非叶子节点只不存储真实的数据，只存储指引搜索方向的数据项，如17、35并不真实存在于数据表中。

### b+树的查找过程
如图所示，如果要查找数据项29，那么首先会把磁盘块1由磁盘加载到内存，此时发生一次IO，在内存中用二分查找确定29在17和35之间，锁定磁盘块1的P2指针，内存时间因为非常短（相比磁盘的IO）可以忽略不计，通过磁盘块1的P2指针的磁盘地址把磁盘块3由磁盘加载到内存，发生第二次IO，29在26和30之间，锁定磁盘块3的P2指针，通过指针加载磁盘块8到内存，发生第三次IO，同时内存中做二分查找找到29，结束查询，总计三次IO。真实的情况是，3层的b+树可以表示上百万的数据，如果上百万的数据查找只需要三次IO，性能提高将是巨大的，如果没有索引，每个数据项都要发生一次IO，那么总共需要百万次的IO，显然成本非常非常高。

#### b+树性质
1.通过上面的分析，我们知道IO次数取决于b+数的高度h，假设当前数据表的数据为N，每个磁盘块的数据项的数量是m，则有h=㏒(m+1)N，当数据量N一定的情况下，m越大，h越小；而m = 磁盘块的大小 / 数据项的大小，磁盘块的大小也就是一个数据页的大小，是固定的，如果数据项占的空间越小，数据项的数量越多，树的高度越低。这就是为什么每个数据项，即索引字段要尽量的小，比如int占4字节，要比bigint8字节少一半。这也是为什么b+树要求把真实的数据放到叶子节点而不是内层节点，一旦放到内层节点，磁盘块的数据项会大幅度下降，导致树增高。当数据项等于1时将会退化成线性表。
2.当b+树的数据项是复合的数据结构，比如(name,age,sex)的时候，b+数是按照从左到右的顺序来建立搜索树的，比如当(张三,20,F)这样的数据来检索的时候，b+树会优先比较name来确定下一步的所搜方向，如果name相同再依次比较age和sex，最后得到检索的数据；但当(20,F)这样的没有name的数据来的时候，b+树就不知道下一步该查哪个节点，因为建立搜索树的时候name就是第一个比较因子，必须要先根据name来搜索才能知道下一步去哪里查询。比如当(张三,F)这样的数据来检索时，b+树可以用name来指定搜索方向，但下一个字段age的缺失，所以只能把名字等于张三的数据都找到，然后再匹配性别是F的数据了， 这个是非常重要的性质，即索引的最左匹配特性。


 <https://tech.meituan.com/mysql-index.html>
 
 
### 一、为什么mysql innodb索引是B+树数据结构？

言简意赅，就是因为：
- 1.文件很大，不可能全部存储在内存中，故要存储到磁盘上
- 2.索引的结构组织要尽量减少查找过程中磁盘I/O的存取次数（为什么使用B-/+Tree，还跟磁盘存取原理有关。）
- 3、B+树所有的Data域在叶子节点，一般来说都会进行一个优化，就是将所有的叶子节点用指针串起来，这样遍历叶子节点就能获得全部数据。


### 二、什么是聚簇索引？
像innodb中,主键的索引结构中,既存储了主键值,又存储了行数据,这种结构称为”聚簇索引”

### 三、为什么MongoDB采用B树索引，而Mysql用B+树做索引

#### 先从数据结构的角度来答。
题主应该知道B-树和B+树最重要的一个区别就是B+树只有叶节点存放数据，其余节点用来索引，\
&nbsp;&nbsp;而B-树是每个索引节点都会有Data域。
这就决定了B+树更适合用来存储外部数据，也就是所谓的磁盘数据。

从Mysql（Inoodb）的角度来看，B+树是用来充当索引的，一般来说索引非常大，尤其是关系性数据库这种数据量大的索引能达到亿级别，所以为了减少内存的占用，索引也会被存储在磁盘上。

那么Mysql如何衡量查询效率呢？磁盘IO次数，B-树（B类树）的特定就是每层节点数目非常多，层数很少，目的就是为了就少磁盘IO次数，当查询数据的时候，最好的情况就是很快找到目标索引，然后读取数据，

使用B+树就能很好的完成这个目的，但是B-树的每个节点都有data域（指针），这无疑增大了节点大小，说白了增加了磁盘IO次数（磁盘IO一次读出的数据量大小是固定的，单个数据变大，每次读出的就少，IO次数增多，一次IO多耗时啊！），

- 原因1：B+树除了叶子节点其它节点并不存储数据，节点小，磁盘IO次数就少。
- 原因2：B+树所有的Data域在叶子节点，一般来说都会进行一个优化，就是将所有的叶子节点用指针串起来。这样遍历叶子节点就能获得全部数据。


至于MongoDB为什么使用B-树而不是B+树，可以从它的设计角度来考虑，它并不是传统的关系性数据库，而是以Json格式作为存储的nosql，目的就是高性能，高可用，易扩展。首先它摆脱了关系模型，上面所述的优点2需求就没那么强烈了，其次Mysql由于使用B+树，数据都在叶节点上，每次查询都需要访问到叶节点，而MongoDB使用B-树，所有节点都有Data域，只要找到指定索引就可以进行访问，无疑单次查询平均快于Mysql（但侧面来看Mysql至少平均查询耗时差不多）。


总体来说，Mysql选用B+树和MongoDB选用B-树还是以自己的需求来选择的。


<https://blog.csdn.net/xuehuagongzi000/article/details/78985844>

<http://blog.codinglabs.org/articles/theory-of-mysql-index.html>


---

## 如何优化数据库性能（索引、分库分表、批量操作、分页算法、升级硬盘SSD、业务优化、主从部署）



## SQL什么情况下不会使用索引（不包含，不等于，函数）

### 建索引的几大原则

- 1.最左前缀匹配原则，非常重要的原则，mysql会一直向右匹配直到遇到范围查询(>、<、between、like)就停止匹配，比如a = 1 and b = 2 and c > 3 and d = 4 如果建立(a,b,c,d)顺序的索引，d是用不到索引的，如果建立(a,b,d,c)的索引则都可以用到，a,b,d的顺序可以任意调整。

- 2.=和in可以乱序，比如a = 1 and b = 2 and c = 3 建立(a,b,c)索引可以任意顺序，mysql的查询优化器会帮你优化成索引可以识别的形式

- 3.尽量选择区分度高的列作为索引,区分度的公式是count(distinct col)/count(*)，表示字段不重复的比例，比例越大我们扫描的记录数越少，唯一键的区分度是1，而一些状态、性别字段可能在大数据面前区分度就是0，那可能有人会问，这个比例有什么经验值吗？使用场景不同，这个值也很难确定，一般需要join的字段我们都要求是0.1以上，即平均1条扫描10条记录

- 4.索引列不能参与计算，保持列“干净”，比如from_unixtime(create_time) = ’2014-05-29’就不能使用到索引，原因很简单，b+树中存的都是数据表中的字段值，但进行检索时，需要把所有元素都应用函数才能比较，显然成本太大。所以语句应该写成create_time = unix_timestamp(’2014-05-29’);

- 5.尽量的扩展索引，不要新建索引。比如表中已经有a的索引，现在要加(a,b)的索引，那么只需要修改原来的索引即可


### mysql不使用索引情况（附加示例）：

示例建立的索引：

1 如果MySQL估计使用索引比全表扫描更慢，则不使用索引。例如，如果列key均匀分布在1和100之间，下面的查询使用索引就不是很好：select * from table_name where key>1 and key<90;
 
2，用or分隔开的条件，如果or前的条件中的列有索引，而后面的列没有索引，那么涉及到的索引都不会被用到，例如：select * from table_name where key1='a' or key2='b';如果在key1上有索引而在key2上没有索引，则该查询也不会走索引

3，复合索引，如果索引列不是复合索引的第一部分，则不使用索引（即不符合最左前缀），例如，复合索引为(key1,key2),则查询select * from table_name where key2='b';将不会使用索引

4，如果like是以‘%’开始的，则该列上的索引不会被使用。例如select * from table_name where key1 like '%a'；该查询即使key1上存在索引，也不会被使用

5，如果列为字符串，则where条件中必须将字符常量值加引号，否则即使该列上存在索引，也不会被使用。例如,select * from table_name where key1=1;如果key1列保存的是字符串，即使key1上有索引，也不会被使用。

6，WHERE字句的查询条件里有不等于号（WHERE column!=...）,或<>操作符，否则将引擎放弃使用索引而进行全表扫描。 

7 where 子句中对字段进行 null 值判断 where mobile = null 此查询 不会走索引

8，in
 和 not in 也要慎用，否则会导致全表扫描 

9，不要在
 where 子句中的“=”左边进行函数、算术运算或其他表达式运算，否则系统将可能无法正确使用索引。


从上面可以看出，即使我们建立了索引，也不一定会被使用，那么我们如何知道我们索引的使用情况呢？？在MySQL中，有Handler_read_key和Handler_read_rnd_key两个变量，如果Handler_read_key值很高而Handler_read_rnd_key的值很低，则表明索引经常不被使用，应该重新考虑建立索引。可以通过:show status like 'Handler_read%'来查看着连个参数的值。


### MySQL中优化sql语句查询常用的方法

1.对查询进行优化，应尽量避免全表扫描，首先应考虑在 where 及 order by 涉及的列上建立索引。 

2.应尽量避免在 where 子句中使用!=或<>操作符，否则将引擎放弃使用索引而进行全表扫描。 

3.应尽量避免在 where 子句中对字段进行 null 值判断，否则将导致引擎放弃使用索引而进行全表扫描，如： 
select id from t where num is null 
可以在num上设置默认值0，确保表中num列没有null值，然后这样查询： 
select id from t where num=0 

4.应尽量避免在 where 子句中使用 or 来连接条件，否则将导致引擎放弃使用索引而进行全表扫描，如： 
select id from t where num=10 or num=20 
可以这样查询： 
select id from t where num=10 
union all 
select id from t where num=20 

5.下面的查询也将导致全表扫描： 
select id from t where name like '%abc%' 
若要提高效率，可以考虑全文检索。 

6.in 和 not in 也要慎用，否则会导致全表扫描，如： 
select id from t where num in(1,2,3) 
对于连续的数值，能用 between 就不要用 in 了： 
select id from t where num between 1 and 3 

7.如果在 where 子句中使用参数，也会导致全表扫描。因为SQL只有在运行时才会解析局部变量，但优化程序不能将访问计划的选择推迟到运行时；它必须在编译时进行选择。然而，如果在编译时建立访问计划，变量的值还是未知的，因而无法作为索引选择的输入项。如下面语句将进行全表扫描： 
select id from t where num=@num 
可以改为强制查询使用索引： 
select id from t with(index(索引名)) where num=@num 

8.应尽量避免在 where 子句中对字段进行表达式操作，这将导致引擎放弃使用索引而进行全表扫描。如： 
select id from t where num/2=100 
应改为: 
select id from t where num=100*2 

9.应尽量避免在where子句中对字段进行函数操作，这将导致引擎放弃使用索引而进行全表扫描。如： 
select id from t where substring(name,1,3)='abc'--name以abc开头的id 
select id from t where datediff(day,createdate,'2005-11-30')=0--'2005-11-30'生成的id 
应改为: 
select id from t where name like 'abc%' 
select id from t where createdate>='2005-11-30' and createdate<'2005-12-1' 

10.不要在 where 子句中的“=”左边进行函数、算术运算或其他表达式运算，否则系统将可能无法正确使用索引。 

11.在使用索引字段作为条件时，如果该索引是复合索引，那么必须使用到该索引中的第一个字段作为条件时才能保证系统使用该索引，否则该索引将不会被使用，并且应尽可能的让字段顺序与索引顺序相一致。 

12.不要写一些没有意义的查询，如需要生成一个空表结构： 
select col1,col2 into #t from t where 1=0 
这类代码不会返回任何结果集，但是会消耗系统资源的，应改成这样： 
create table #t(...) 

13.很多时候用 exists 代替 in 是一个好的选择： 
select num from a where num in(select num from b) 
用下面的语句替换： 
select num from a where exists(select 1 from b where num=a.num) 

14.并不是所有索引对查询都有效，SQL是根据表中数据来进行查询优化的，当索引列有大量数据重复时，SQL查询可能不会去利用索引，如一表中有字段sex，male、female几乎各一半，那么即使在sex上建了索引也对查询效率起不了作用。 

15.索引并不是越多越好，索引固然可以提高相应的 select 的效率，但同时也降低了 insert 及 update 的效率，因为 insert 或 update 时有可能会重建索引，所以怎样建索引需要慎重考虑，视具体情况而定。一个表的索引数最好不要超过6个，若太多则应考虑一些不常使用到的列上建的索引是否有必要。 

16.应尽可能的避免更新 clustered 索引数据列，因为 clustered 索引数据列的顺序就是表记录的物理存储顺序，一旦该列值改变将导致整个表记录的顺序的调整，会耗费相当大的资源。若应用系统需要频繁更新 clustered 索引数据列，那么需要考虑是否应将该索引建为 clustered 索引。 

17.尽量使用数字型字段，若只含数值信息的字段尽量不要设计为字符型，这会降低查询和连接的性能，并会增加存储开销。这是因为引擎在处理查询和连接时会逐个比较字符串中每一个字符，而对于数字型而言只需要比较一次就够了。 

18.尽可能的使用 varchar/nvarchar 代替 char/nchar ，因为首先变长字段存储空间小，可以节省存储空间，其次对于查询来说，在一个相对较小的字段内搜索效率显然要高些。 

19.任何地方都不要使用 select * from t ，用具体的字段列表代替“*”，不要返回用不到的任何字段。 

20.尽量使用表变量来代替临时表。如果表变量包含大量数据，请注意索引非常有限（只有主键索引）。 

21.避免频繁创建和删除临时表，以减少系统表资源的消耗。 

22.临时表并不是不可使用，适当地使用它们可以使某些例程更有效，例如，当需要重复引用大型表或常用表中的某个数据集时。但是，对于一次性事件，最好使用导出表。 

23.在新建临时表时，如果一次性插入数据量很大，那么可以使用 select into 代替 create table，避免造成大量 log ，以提高速度；如果数据量不大，为了缓和系统表的资源，应先create table，然后insert。 

24.如果使用到了临时表，在存储过程的最后务必将所有的临时表显式删除，先 truncate table ，然后 drop table ，这样可以避免系统表的较长时间锁定。 

25.尽量避免使用游标，因为游标的效率较差，如果游标操作的数据超过1万行，那么就应该考虑改写。 

26.使用基于游标的方法或临时表方法之前，应先寻找基于集的解决方案来解决问题，基于集的方法通常更有效。 

27.与临时表一样，游标并不是不可使用。对小型数据集使用 FAST_FORWARD 游标通常要优于其他逐行处理方法，尤其是在必须引用几个表才能获得所需的数据时。在结果集中包括“合计”的例程通常要比使用游标执行的速度快。如果开发时间允许，基于游标的方法和基于集的方法都可以尝试一下，看哪一种方法的效果更好。 

28.在所有的存储过程和触发器的开始处设置 SET NOCOUNT ON ，在结束时设置 SET NOCOUNT OFF 。无需在执行存储过程和触发器的每个语句后向客户端发送 DONE_IN_PROC 消息。 

29.尽量避免向客户端返回大数据量，若数据量过大，应该考虑相应需求是否合理。 

30.尽量避免大事务操作，提高系统并发能力。



### Explain 
首先解释说明一下Explain命令，Explain命令在解决数据库性能上是第一推荐使用命令，

大部分的性能问题可以通过此命令来简单的解决，Explain可以用来查看 SQL 语句的执行效 果，

可以帮助选择更好的索引和优化查询语句，写出更好的优化语句。

Explain语法：explain select … from … [where ...]

例如：explain select * from news;

输出：
+----+-------------+-------+-------+-------------------+---------+---------+-------+------+-------+
| id | select_type | table | type | possible_keys | key | key_len | ref | rows | Extra |
+----+-------------+-------+-------+-------------------+---------+---------+-------+------+-------+

下面对各个属性进行了解：

1、id：这是SELECT的查询序列号

2、select_type：select_type就是select的类型，可以有以下几种：

SIMPLE：简单SELECT(不使用UNION或子查询等)

PRIMARY：最外面的SELECT

UNION：UNION中的第二个或后面的SELECT语句

DEPENDENT UNION：UNION中的第二个或后面的SELECT语句，取决于外面的查询

UNION RESULT：UNION的结果。

SUBQUERY：子查询中的第一个SELECT

DEPENDENT SUBQUERY：子查询中的第一个SELECT，取决于外面的查询

DERIVED：导出表的SELECT(FROM子句的子查询)


3、table：显示这一行的数据是关于哪张表的

4、type：这列最重要，显示了连接使用了哪种类别,有无使用索引，是使用Explain命令分析性能瓶颈的关键项之一。

结果值从好到坏依次是：

> system > const > eq_ref > ref > fulltext > ref_or_null > index_merge > unique_subquery > index_subquery > range > index > ALL

一般来说，得保证查询至少达到range级别，最好能达到ref，否则就可能会出现性能问题。

5、possible_keys：列指出MySQL能使用哪个索引在该表中找到行

6、key：显示MySQL实际决定使用的键（索引）。如果没有选择索引，键是NULL

7、key_len：显示MySQL决定使用的键长度。如果键是NULL，则长度为NULL。使用的索引的长度。在不损失精确性的情况下，长度越短越好

8、ref：显示使用哪个列或常数与key一起从表中选择行。

9、rows：显示MySQL认为它执行查询时必须检查的行数。

10、Extra：包含MySQL解决查询的详细信息，也是关键参考项之一。

Distinct
一旦MYSQL找到了与行相联合匹配的行，就不再搜索了

Not exists
MYSQL 优化了LEFT JOIN，一旦它找到了匹配LEFT JOIN标准的行，

就不再搜索了

Range checked for each

Record（index map:#）
没有找到理想的索引，因此对于从前面表中来的每一 个行组合，MYSQL检查使用哪个索引，并用它来从表中返回行。这是使用索引的最慢的连接之一

Using filesort
看 到这个的时候，查询就需要优化了。MYSQL需要进行额外的步骤来发现如何对返回的行排序。它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来 排序全部行

Using index
列数据是从仅仅使用了索引中的信息而没有读取实际的行动的表返回的，这发生在对表 的全部的请求列都是同一个索引的部分的时候

Using temporary
看到这个的时候，查询需要优化了。这 里，MYSQL需要创建一个临时表来存储结果，这通常发生在对不同的列集进行ORDER BY上，而不是GROUP BY上

Using where
使用了WHERE从句来限制哪些行将与下一张表匹配或者是返回给用户。如果不想返回表中的全部行，并且连接类型ALL或index， 这就会发生，或者是查询有问题


<https://blog.csdn.net/lr131425/article/details/61918741>


## 一般在什么字段上建索引

（过滤数据最多的字段）
经常需要查询的字段。

## MySQL 行锁实现 

Mysql 行锁实现:
> 只有通过索引条件检索数据，InnoDB才使用行级锁，否则，InnoDB将使用表锁！

- innodb行锁实现方式\
InnoDB行锁是通过给索引上的索引项加锁来实现的，这一点MySQL与Oracle不同，后者是通过在数据块中对相应数据行加锁来实现的。 InnoDB这种行锁实现特点意味着：只有通过索引条件检索数据，InnoDB才使用行级锁，否则，InnoDB将使用表锁！
在实际应用中，要特别注意InnoDB行锁的这一特性，不然的话，可能导致大量的锁冲突，从而影响并发性能。下面通过一些实际例子来加以说明.

(1)、在不通过索引条件查询的时候，InnoDB确实使用的是表锁，而不是行锁

```
mysql> create table tab_no_index(id int,name varchar(10)) engine=innodb;
Query OK, 0 rows affected (0.15 sec)
mysql> insert into tab_no_index values(1,'1'),(2,'2'),(3,'3'),(4,'4');
Query OK, 4 rows affected (0.00 sec)
Records: 4  Duplicates: 0  Warnings: 0
```

（2）由于MySQL的行锁是针对索引加的锁，不是针对记录加的锁，所以虽然是访问不同行的记录，但是如果是使用相同的索引键，是会出现锁冲突的。应用设计的时候要注意这一点。

（3）当表有多个索引的时候，不同的事务可以使用不同的索引锁定不同的行，另外，不论是使用主键索引、唯一索引或普通索引，InnoDB都会使用行锁来对数据加锁。

（4）即便在条件中使用了索引字段，但是否使用索引来检索数据是由MySQL通过判断不同执行计划的代价来决定的，如果MySQL认为全表扫描效率更高，比如对一些很小的表，它就不会使用索引，这种情况下InnoDB将使用表锁，而不是行锁。因此，在分析锁冲突时，别忘了检查SQL的执行计划，以确认是否真正使用了索引。





<http://book.51cto.com/art/200803/68127.htm> \
<https://lanjingling.github.io/2015/10/10/mysql-hangsuo/>


## MYSQL性能优化的最佳20+条经验

1. 为查询缓存优化你的查询
```
// 查询缓存不开启
$r = mysql_query("SELECT username FROM user WHERE signup_date >= CURDATE()");
 
// 开启查询缓存
$today = date("Y-m-d");
$r = mysql_query("SELECT username FROM user WHERE signup_date >= '$today'");
```

上面两条SQL语句的差别就是 CURDATE() ，MySQL的查询缓存对这个函数不起作用。所以，像 NOW() 和 RAND() 或是其它的诸如此类的SQL函数都不会开启查询缓存，因为这些函数的返回是会不定的易变的。所以，你所需要的就是用一个变量来代替MySQL的函数，从而开启缓存


2. EXPLAIN 你的 SELECT 查询

使用 EXPLAIN 关键字可以让你知道MySQL是如何处理你的SQL语句的。
这可以帮你分析你的查询语句或是表结构的性能瓶颈。

EXPLAIN 的查询结果还会告诉你你的索引主键被如何利用的，你的数据表是如何被搜索和排序的……等等，等等。


3. 当只要一行数据时使用 LIMIT 1
4.为搜索字段建索引
5. 在Join表的时候使用相当类型的例，并将其索引
6. 千万不要 ORDER BY RAND()
7. 避免 SELECT *
8. 永远为每张表设置一个ID
9. 使用 ENUM 而不是 VARCHAR
10. 从 PROCEDURE ANALYSE() 取得建议
11. 尽可能的使用 NOT NULL
12. Prepared Statements (预编译)
13. 无缓冲的查询
14. 把IP地址存成 UNSIGNED INT
15. 固定长度的表会更快
16. 垂直分割
17. 拆分大的 DELETE 或 INSERT 语句
18. 越小的列会越快
19. 选择正确的存储引擎
20. 使用一个对象关系映射器（Object Relational Mapper）
21. 小心“永久链接”
22. 


<https://coolshell.cn/articles/1846.html>

## 如何解决高并发减库存问题

(秒杀核心设计(减库存部分)-防超卖与高并发)

 把被用户大量访问的静态资源缓存在CDN中

#### 使用一级缓存，减少nosql服务器压力
一级缓存使用站点服务器缓存去存储数据，注意只存储部分请求量大的数据，并且缓存的数据量要控制，不能过分的使用站点服务器的内存而影响了站点应用程序的正常运行。

#### 善用原子计数器
 在秒杀系统中，热点商品会有大量用户参与进来，然后就产生了大量减库存竞争。所以当执行秒杀的时候系统会做一个原子计数器(可以通过redis/nosql实现)，它记录的是商品的库存。
 当用户执行秒杀的时候，就会去减库存，也就是减原子计数器，保证原子性。当减库存成功之后就回去记录行为消息(谁去减了库存)，减了会后作为一个消息当到一个分布的MQ(消息队列)中，然后后端的服务器会把其落地到MySQL中。
 
 
#### 善用redis的消息队列
使用redis的list，当用户参与到高并发活动时，将参与用户的信息添加到消息队列中，然后再写个多线程程序去消耗队列(pop数据)，这样能避免服务器宕机的危险。\
通过消息队列可以做很多的服务，比如定时短信发送服务，使用sorted set(sset)，发送时间戳作为排序依据，短信数据队列根据时间升序，然后写个程序定时循环去读取sset队列中的第一条，当前时间是否超过发送时间，如果超过就进行短信发送。
 
 
 <https://www.jianshu.com/p/cf950af25711>


redis 锁。



## mysql存储引擎中索引的实现机制；

### 索引本质
MySQL官方解释：索引是为MySQL提高获取数据效率的数据结构，为了快速查询数据。索引是满足某种特定查找算法的数据结构，而这些数据结构会以某种方式指向数据，从而实现高效查找数据。

B+树
MySQL一般以B+树作为其索引结构，那么B+树有什么特点呢？

- 树度为n的话，每个节点指针上限为2n+1
- 非叶子节点不存储数据，只存储指针索引；叶子节点存储所有数据，不存储指针
- 在经典B+树基础上增加了顺序访问指针，每个叶子节点都有指向相邻下一个叶子节点的指针，如图所示。主要为了提高区间访问的性能，例如要找key为20到50的所有数据，只要按着顺序访问路线一次性访问所有数据节点。

![](https://upload-images.jianshu.io/upload_images/787365-a979aa05bf72eed5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/355)

带顺序访问的B+树简图


### 局部性原理和磁盘预读
那么为什么数据库系统普遍使用B+树作为索引结构，而不选例如红黑树其他结构呢？首先要先来介绍下局部性原理和磁盘预读的概念。
一般来说，索引本身较大，不会全部存储在内存中，会以索引文件的形式存储在磁盘上。所以索引查找数据过程中就会产生磁盘IO操作，而磁盘IO相对于内存存取非常缓慢，因此索引结构要尽量减少磁盘IO的存取次数。
为了减少磁盘IO，磁盘往往会进行数据预读，会从某位置开始，预先向后读取一定长度的数据放入内存，即局部性原理。因为磁盘顺序读取的效率较高，不需要寻道时间，因此可以提高IO效率。
预读长度一般为页的整数倍，主存和磁盘以页作为单位交换数据。当需要读取的数据不在内存时，触发缺页中断，系统会向磁盘发出读取磁盘数据的请求，磁盘找到数据的起始位置并向后连续读取一页或几页数据载入内存，然后中断返回，系统继续运行。而一般数据库系统设计时会将B+树节点的大小设置为一页，这样每个节点的载入只需要一次IO。

### MySQL索引实现
MySQL存在多种存储引擎的选择，不同存储引擎对索引的实现是不同的，本章着重对常见存储引擎InnoDB和MyISAM存储引擎的索引实现进行讨论。

### InnoDB索引实现
使用B+树作为索引结构，数据文件本身就是索引文件。数据文件按照B+树的结构进行组织，叶节点的data域存储完整的数据记录，索引的key即为表的主键。下图为主键索引示意图（盗图一波）。聚集索引使得搜索主键非常高效。


![](https://upload-images.jianshu.io/upload_images/787365-0d38936d841ce846.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)


数据文件本身按主键索引，因此InnoDB必须要有主键。没有主键怎么指定主键？

下图为辅助索引示意图，InnoDB辅助索引的data域存储的是主键的值。搜索辅助索引需要先根据辅助索引获取到主键值，再根据主键到主索引中获取到对应的数据记录。


![](https://upload-images.jianshu.io/upload_images/787365-dd1e321179a11c84.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)


MyISAM索引实现
同样也是使用B+树作为索引结构，叶子节点data域存储的是数据记录的地址。数据文件和索引文件是分别存储在xxx.MYD和xxx.MYI（xxx表示数据表名），索引文件xxx.MYI保存数据记录的地址，具体可参考MySQL存储引擎简介。如图所示（盗了个图），为主索引的示意图。MyISAM中检索索引算法为：首先按照B+树搜索算法搜索，如果找到指定的key，取出其data域的值，再以data域值为地址查找对应的数据记录。因此MyISAM的索引方式也称为非聚集索引。

![](https://upload-images.jianshu.io/upload_images/787365-90868e026e65c9fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)


<https://www.jianshu.com/p/3a1377883742>



## 数据库事务的几种粒度；

### 锁的粒度
所谓粒度，即细化的程度。锁的粒度越大，则并发性越低且开销大；锁的粒度越小，则并发性高且开销小。

锁的粒度主要有以下几种类型：

（1）行锁，行锁是粒度中最小的资源。行锁就是指事务在操作数据的过程中，锁定一行或多行的数据，其他事务不能同时处理这些行的数据。行级锁占用的数据资源最小，所以在事务的处理过程中，允许其它事务操作同一表的其他数据。

（2）页锁，一次锁定一页。25个行锁可升级为一个页锁。

（3）表锁，锁定整个表。当整个数据表被锁定后，其他事务就不能够使用此表中的其他数据。使用表锁可以使事务处理的数据量大，并且使用较少的系统资源。但是在使用表锁时，会延迟其他事务的等待时间，降低系统并发性。

（4）数据库锁，防止任何事务和用户对此数据库进行访问。可控制整个数据库的操作。



用锁效率会降低，可通过使用表锁来减少锁的使用从而保证效率。




## 行锁，表锁；乐观锁，悲观锁

### 乐观锁
乐观锁不是数据库自带的，需要我们自己去实现。乐观锁是指操作数据库时(更新操作)，想法很乐观，认为这次的操作不会导致冲突，在操作数据时，并不进行任何其他的特殊处理（也就是不加锁），而在进行更新后，再去判断是否有冲突了。

通常实现是这样的：在表中的数据进行操作时(更新)，先给数据表加一个版本(version)字段，每操作一次，将那条记录的版本号加1。也就是先查询出那条记录，获取出version字段,如果要对那条记录进行操作(更新),则先判断此刻version的值是否与刚刚查询出来时的version的值相等，如果相等，则说明这段期间，没有其他程序对其进行操作，则可以执行更新，将version字段的值加1；如果更新时发现此刻的version值与刚刚获取出来的version的值不相等，则说明这段期间已经有其他程序对其进行操作了，则不进行更新操作。

举例：

下单操作包括3步骤：

1.查询出商品信息

> select (status,status,version) from t_goods where id=#{id}

2.根据商品信息生成订单

3.修改商品status为2

```
update t_goods 

set status=2,version=version+1

where id=#{id} and version=#{version};
```


除了自己手动实现乐观锁之外，现在网上许多框架已经封装好了乐观锁的实现，如hibernate，需要时，可能自行搜索"hiberate 乐观锁"试试看。


### 悲观锁
与乐观锁相对应的就是悲观锁了。悲观锁就是在操作数据时，认为此操作会出现数据冲突，所以在进行每次操作时都要通过获取锁才能进行对相同数据的操作，这点跟java中的synchronized很相似，所以悲观锁需要耗费较多的时间。另外与乐观锁相对应的，悲观锁是由数据库自己实现了的，要用的时候，我们直接调用数据库的相关语句就可以了。

说到这里，由悲观锁涉及到的另外两个锁概念就出来了，它们就是共享锁与排它锁。共享锁和排它锁是悲观锁的不同的实现，它俩都属于悲观锁的范畴。



### 共享锁
共享锁指的就是对于多个不同的事务，对同一个资源共享同一个锁。相当于对于同一把门，它拥有多个钥匙一样。就像这样，你家有一个大门，大门的钥匙有好几把，你有一把，你女朋友有一把，你们都可能通过这把钥匙进入你们家，进去啪啪啪啥的，一下理解了哈，没错，这个就是所谓的共享锁。
刚刚说了，对于悲观锁，一般数据库已经实现了，共享锁也属于悲观锁的一种，那么共享锁在mysql中是通过什么命令来调用呢。通过查询资料，了解到通过在执行语句后面加上lock in share mode就代表对某些资源加上共享锁了。
比如，我这里通过mysql打开两个查询编辑器，在其中开启一个事务，并不执行commit语句
city表DDL如下：

```
CREATE TABLE `city` (  
  `id` bigint(20) NOT NULL AUTO_INCREMENT,  
  `name` varchar(255) DEFAULT NULL,  
  `state` varchar(255) DEFAULT NULL,  
  PRIMARY KEY (`id`)  
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;  
```
![](https://img-blog.csdn.net/20170516162604233?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcHVoYWl5YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

begin;
SELECT * from city where id = "1"  lock in share mode;

然后在另一个查询窗口中，对id为1的数据进行更新


![](https://img-blog.csdn.net/20170516163339831?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcHVoYWl5YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

update  city set name="666" where id ="1";
此时，操作界面进入了卡顿状态，过几秒后，也提示错误信息
[SQL]update  city set name="666" where id ="1";
[Err] 1205 - Lock wait timeout exceeded; try restarting transaction

那么证明，对于id=1的记录加锁成功了，在上一条记录还没有commit之前，这条id=1的记录被锁住了，只有在上一个事务释放掉锁后才能进行操作，或用共享锁才能对此数据进行操作。
再实验一下：


![](https://img-blog.csdn.net/20170516164857534?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcHVoYWl5YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

update city set name="666" where id ="1" lock in share mode;
[Err] 1064 - You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'lock in share mode' at line 1


加上共享锁后，也提示错误信息了，通过查询资料才知道，对于update,insert,delete语句会自动加排它锁的原因

于是，我又试了试SELECT * from city where id = "1" lock in share mode;


![](https://img-blog.csdn.net/20170516170350320?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcHVoYWl5YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

这下成功了。




### 排它锁
排它锁与共享锁相对应，就是指对于多个不同的事务，对同一个资源只能有一把锁。
与共享锁类型，在需要执行的语句后面加上for update就可以了


### 行锁
行锁，由字面意思理解，就是给某一行加上锁，也就是一条记录加上锁。

比如之前演示的共享锁语句

SELECT * from city where id = "1"  lock in share mode; 

由于对于city表中,id字段为主键，就也相当于索引。执行加锁时，会将id这个索引为1的记录加上锁，那么这个锁就是行锁。



### 表锁
表锁，和行锁相对应，给这个表加上锁。

MyISAM引擎里有的，暂时研究了




## mysql 事物 原理

事务（Transaction）是数据库区别于文件系统的重要特性之一，事务会把数据库从一种一致性状态转换为另一种一致性状态。在数据库提交时，可以确保要么所有修改都已保存，要么所有修改都不保存。


### 一 事务的分类
1.1 扁平事务
要么都执行,要么都回滚,InnoDB最常用,最常见的事务.

1.2 带有保存点的偏平事务
事务的操作过程有 begin, A, B, C, D, commit 几个过程,那么带有保存点的扁平事务过程大致如下:

begin--> 隐含保存点1(save work 1)-->A-->B(save work2)-->C-->D(rollback work2) -->commit

上述过程中如果遇到rollback work2, 只需要回滚到保存点2,不需要全部回滚. 

简单来说,带有保存点的扁平事务就是有计划的回滚操作。
保存点是容易失的(volatile), 而非持久的.系统崩溃,所有保存点都将丢失.


1.3 链事务 
链事务提交一个事务时,释放不需要的数据对象,将必要的上下文传递给下一个要开始的事务. 下一个事务可以看到上一个事务的结果.

带有保存点的偏平事务可以回滚到任意正确的保存点,链事务只能回滚到当前事务. 

扁平全程持锁,链事务在commit后释放锁. 

链事务如:  T1->T2->T3


1.4 嵌套事务
 可以理解为一颗事务树,顶层事务控制着下面的子事务.  所有的叶子节点是扁平事务,实际工作是由叶子节点完成的.


1.5 分布式事务  
分布式环境下运行的扁平事务. 


InnoDB支持上述除嵌套事务以外的所有事务类型.





### 二 事务ACID的实现
2.1 隔离性的实现
事务的隔离性由存储引擎的锁来实现, 详细见   Mysql数据库事务的隔离级别和锁的实现原理分析
2.2 原子性和持久性的实现
redo log 称为重做日志(也叫事务日志),用来保证事务的原子性和持久性.   

redo恢复提交事务修改的页操作,redo是物理日志,页的物理修改操作.

事务的提交过程如下图: 

![](https://img-blog.csdn.net/20150823163448097?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)


当提交一个事务时,实际上它干了如下2件事:

一:  InnoDB存储引擎把事务写入日志缓冲(log buffer),日志缓冲把事务刷新到事务日志.

### 二:  InnoDB存储引擎把事务写入缓冲池(Buffer pool).

这里有个问题, 事务日志也是写磁盘日志,为什么不需要双写技术？
因为事务日志块的大小和磁盘扇区的大小一样,都是512字节,因此事务日志的写入可以保证原子性，不需要doublewrite技术

重做日志缓冲是由每个为512字节大小的日志块组成的. 日志块分为三部分:  日志头(12字节),日志内容(492字节),日志尾(8字节).

重做日志是一个日志组,下面的日志形式描绘了这一可能的重做日志存储方式:

group1: 
每个log group的第一个 redo log file,需要保存: log_file_header 512字节,checkpoint1 512字节,空 512字节,checkpoint2 512字节.
group1: 
redo log file1:  log_file_header,cp1,空,cp2 log block,log block.......log block.
read log file2:  空,空,空,空,log block,log block,.......log block. 

group2: 
redo log file1:  log_file_header,cp1,空,cp2 log block,log block.......log block.
read log file2:  空,空,空,空,log block,log block,.......log block. 

但有些事务需要跨 log block如何提交磁盘,如事务A 重做日志是 712字节,需2个log block来装.

InnoDB采用的是group commit的方式来保证原子性.

log buffer什么时候会把block刷新到磁盘呢? 一般是下面的时刻:

1, 事务提交时

2, log buffer 内存使用到一半时.

3, log checkpoint时。

checkpoint表示已经刷新到磁盘上的重做日志总量,因此恢复时只需要恢复从checkpoint开始的日志部分.

<数据库系统概念> 454页<事务管理>一节中说到: 

检查点的引入是为了解决,系统恢复时,需要搜索整个日志来做redo和undo 操作.

系统周期性的执行检查点,刷新检查点时需要执行以下动作序列:

1, 将当前位于主存的所有日志记录输出到磁盘上(我的理解是事务日志).

2, 将当前修改了的缓冲块(我的理解是脏页)输出到磁盘上.

3, 将一个日志记录的<checkpoint>输出到磁盘(我的理解是事务日志).

由此我们可以知道:  重做日志的写入并不完全是顺序的,因为除了log block的写入外,有时还需要更新前2KB部分的信息.

2.3 一致性的实现
undo log 用来保证事务的一致性. undo 回滚行记录到某个特定版本,undo 是逻辑日志,根据每行记录进行记录.

undo 存放在数据库内部的undo段,undo段位于共享表空间内.

undo 只把数据库逻辑的恢复到原来的样子.

undo日志除了回滚作用之外, undo 实现MVCC,读取一行记录时,发现事务锁定,通过undo恢复到之前的版本,实现非锁定读取.



### 三 InnoDB的日志
InnoDB有很多日志,

日志中有2个概念需要分清楚,逻辑日志和物理日志.

3.1 逻辑日志 
有关操作的信息日志成为逻辑日志.

比如,插入一条数据,undo逻辑日志的格式大致如下: 

<Ti,Qj,delete,U> Ti表示事务id,U表示Undo信息,Qj表示某次操作的唯一标示符

undo日志总是这样:

1).  insert操作,则记录一条delete逻辑日志. 

2).  delete操作,则记录一条insert逻辑日志.

3).  update操作,记录相反的update,将修改前的行改回去.

3.2 物理日志
新值和旧值的信息日志称为物理日志. <Ti,Qj,V> 物理日志 

binlog(二进制日志)就是典型的逻辑日志,而事务日志(redo log)则记录的物理日志,他们的区别是什么呢?

1, redo log 是在存储引擎层产生的,binlog是在数据库上层的一种逻辑日志,任何存储引擎均会产生binlog.

2, binlog记录的是sql语句, 重做日志则记录的是对每个页的修改.

3, 写入的时间点不一样. binlog 是在事务提交后进行一次写入,redo log在事务的进行中不断的被写入.

4, redo log 是等幂操作(执行多次等于执行一次,redo log 记录<T0,A,950>记录新值,执行多少次都一样) , binlog 不一样;

redo log 是可能是多条记录, 如: 

<T0,start> 

<Action1> ..... <ActionN>

<t0,commit> 

既有start,又有commit 才是一条完整的redo log。才会被执行,缺失commit在恢复时是不会被执行的.

如遇到并发写入,则redo log 还有可能是如下的情况：
T1,T2,T1,*T2,T3,T1,*T3,*T1 
带*的是事务提交的时间. （从左到右的时间顺序）

redo log ,每个事务对应多个日志条目. 重做日志是并发写入的. 无顺序.

binlog,则如下：
T1,T4,T3,T2,T8,T6,T7,T5


重做日志的例子: 
表t:  a(int,primary key)
 b(int,key(b))
 
insert into t select 1,2;
重做日志大概为(页的物理修改操作,若涉及到B+树的split,会更多的记录)：
page(2,3),offset 32,value 1,2 # 主键索引
page(2,4),offset 64,value 2   # 辅助索引.

Mysql存储引擎在启动时,会进行恢复操作：
重做日志记录的是物理日志，因此恢复的速度比逻辑日志,如二进制日志要快很多.



### 四 总结
1, redo log(事务日志)保证事务的原子性和持久性(物理日志)

2, undo log保证事务的一致性,InnoDB的MVCC也是用undo log来实现的(逻辑日志).

3, redo log中带有有checkPoint,用来高效的恢复数据.

4, 物理日志记录的是修改页的的详情,逻辑日志记录的是操作语句. 物理日志恢复的速度快于逻辑日志.


<https://blog.csdn.net/tangkund3218/article/details/47904021>




### 数据库事务机制
  
  为了找到问题的根源，为了拯救我崩溃的世界观，我又去回顾了数据库事务的知识。借鉴 这篇

#### 数据库的acid属性

- 原性性（Actomicity）：事务是一个原子操作单元，其对数据的修改，要么全都执行，要么全都不执行。

- 一致性（Consistent）：在事务开始和完成时，数据都必须保持一致状态。这意味着所有相关的数据规则都必须应用于事务的修改，以操持完整性；事务结束时，所有的内部数据结构（如B树索引或双向链表）也都必须是正确的。

- 隔离性（Isolation）：数据库系统提供一定的隔离机制，保证事务在不受外部并发操作影响的“独立”环境执行。这意味着事务处理过程中的中间状态对外部是不可见的，反之亦然。

- 持久性（Durable）：事务完成之后，它对于数据的修改是永久性的，即使出现系统故障也能够保持。
　　
说好的一致性呢，童话里都是骗人的！！　　

#### 事务并发调度的问题

- 脏读（dirty read）：A事务读取B事务尚未提交的更改数据，并在这个数据基础上操作。如果B事务回滚，那么A事务读到的数据根本不是合法的，称为脏读。在oracle中，由于有version控制，不会出现脏读。

- 不可重复读（unrepeatable read）：A事务读取了B事务已经提交的更改（或删除）数据。比如A事务第一次读取数据，然后B事务更改该数据并提交，A事务再次读取数据，两次读取的数据不一样。
- 幻读（phantom read）：A事务读取了B事务已经提交的新增数据。注意和不可重复读的区别，这里是新增，不可重复读是更改（或删除）。这两种情况对策是不一样的，对于不可重复读，只需要采取行级锁防止该记录数据被更改或删除，然而对于幻读必须加表级锁，防止在这个表中新增一条数据。
第一类丢失更新：A事务撤销时，把已提交的B事务的数据覆盖掉。
第二类丢失更新：A事务提交时，把已提交的B事务的数据覆盖掉。
　　
#### 三级封锁协议

- 一级封锁协议：事务T中如果对数据R有写操作，必须在这个事务中对R的第一次读操作前对它加X锁，直到事务结束才释放。事务结束包括正常结束（COMMIT）和非正常结束（ROLLBACK）。

- 二级封锁协议：一级封锁协议加上事务T在读取数据R之前必须先对其加S锁，读完后方可释放S锁。 

- 三级封锁协议 ：一级封锁协议加上事务T在读取数据R之前必须先对其加S锁，直到事务结束才释放。
- 
　　可见，三级锁操作一个比一个厉害（满足高级锁则一定满足低级锁）。但有个非常致命的地方，一级锁协议就要在第一次读加x锁，直到事务结束。几乎就要在整个事务加写锁了，效率非常低。三级封锁协议只是一个理论上的东西，实际数据库常用另一套方法来解决事务并发问题。

#### 隔离性级别

　mysql用意向锁（另一种机制）来解决事务并发问题，为了区别封锁协议，弄了一个新概念隔离性级别：包括Read Uncommitted、Read Committed、Repeatable Read、Serializable，见这篇。mysql 一般默认Repeatable Read。

![](https://images2015.cnblogs.com/blog/476810/201608/476810-20160802212600934-1636148148.png)

![](https://images2015.cnblogs.com/blog/476810/201608/476810-20160802234328293-1886690666.png)


　　终于发现自己为什么会误会事务能解决丢失修改了。至于为什么隔离性级别不解决丢失修改，我猜是有更好的解决方案吧。

　　总结一下，repeatable read能解决脏读和不可重复读，但不嗯呢该解决丢失修改。

转载　　
<https://www.cnblogs.com/deliver/p/5730616.html>　　