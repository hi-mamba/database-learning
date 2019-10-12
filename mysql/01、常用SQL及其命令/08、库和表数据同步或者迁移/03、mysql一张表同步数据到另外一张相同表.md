## [mysql - move rows from one table to another](https://stackoverflow.com/questions/19821736/mysql-move-rows-from-one-table-to-another)

# 03、mysql一张表同步数据到另外一张相同表

```mysql
set autocommit=0;
begin ;
INSERT INTO persons_table SELECT * FROM customer_table WHERE person_name = 'tom';
DELETE FROM customer_table WHERE person_name = 'tom';
commit ;
set autocommit = 1;
```
