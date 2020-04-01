

# 11、InnoDB 和 MyISAM 区别

InnoDB和MyISAM的最大不同点有两个：

- InnoDB支持事务(transaction)；MyISAM不支持事务
- Innodb 默认采用行锁， MyISAM 是默认采用表锁。加锁可以保证事务的一致性，可谓是有人(锁)的地方，就有江湖(事务)
- MyISAM不适合高并发
 