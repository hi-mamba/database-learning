## [MySQL DATETIME - Change only the date](https://stackoverflow.com/a/17697367/4712855)

# MySQL DATETIME 只修改日期不修改时间

```mysql
update yourtable set eventtime=replace(eventtime,substr(eventtime,1,10), '2013-07-17')  WHERE  `id`=4
```
