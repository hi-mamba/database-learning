

# MySQL非聚簇索引&&二级索引&&辅助索引

MySQL非聚簇索引&&二级索引&&辅助索引

mysql中每个表都有一个聚簇索引（clustered index ），除此之外的表上的每个非聚簇索引都是二级索引，又叫辅助索引（secondary indexes）。

以InnoDB来说，每个InnoDB表具有一个特殊的索引称为聚集索引。如果您的表上定义有主键，该主键索引是聚集索引。如果你不定义为您的表的主键时，MySQL取第一个唯一索引（unique）而且只含非空列（NOT NULL）作为主键，InnoDB使用它作为聚集索引。如果没有这样的列，InnoDB就自己产生一个这样的ID值，它有六个字节，而且是隐藏的，使其作为聚簇索引。

聚簇索引：<http://my.oschina.net/xinxingegeya/blog/474895>

如下除主键外都是二级索引，或叫做辅助索引。

```mysql
> show create table article

******************** 1. row *********************
       Table: article
Create Table: CREATE TABLE `article` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `shortName` varchar(255) NOT NULL,
  `authorId` int(11) NOT NULL,
  `createTime` datetime NOT NULL,
  `state` int(11) NOT NULL,
  `totalView` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_short_name_title` (`title`,`shortName`),
  KEY `idx_author_id` (`authorId`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1
1 rows in set
```