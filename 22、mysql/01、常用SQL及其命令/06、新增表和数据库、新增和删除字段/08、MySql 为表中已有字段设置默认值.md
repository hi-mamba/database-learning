<https://stackoverflow.com/questions/11312433/how-to-alter-a-column-and-change-the-default-value>

# MySql 为表中存在的字段设置默认值

```mysql
 
ALTER TABLE foobar_data CHANGE COLUMN col col VARCHAR(255) NOT NULL DEFAULT '';

```
