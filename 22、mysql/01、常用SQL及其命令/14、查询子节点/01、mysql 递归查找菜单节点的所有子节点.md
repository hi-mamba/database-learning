
原文：<https://www.cnblogs.com/rainydayfmb/p/8028868.html>

# mysql 递归查找菜单节点的所有子节点

项目中遇到一个需求，要求查处菜单节点的所有节点，在网上查了一下，大多数的方法用到了存储过程，
由于线上环境不能随便添加存储过程，

因此在这里采用类似递归的方法对菜单的所有子节点进行查询。


创建menu表：
```mysql
CREATE TABLE `menu` (
`id` int(11) NOT NULL AUTO_INCREMENT COMMENT '菜单id',
`parent_id` int(11) DEFAULT NULL COMMENT '父节点id',
`menu_name` varchar(128) DEFAULT NULL COMMENT '菜单名称',
`menu_url` varchar(128) DEFAULT '' COMMENT '菜单路径',
`status` tinyint(3) DEFAULT '1' COMMENT '菜单状态 1-有效；0-无效',
PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12212 DEFAULT CHARSET=utf8;
```

插入数据：
```mysql
INSERT INTO `menu` VALUES ('0', null, '菜单0', ' ', '1');
INSERT INTO `menu` VALUES ('1', '0', '菜单1', '', '1');
INSERT INTO `menu` VALUES ('11', '1', '菜单11', '', '1');
INSERT INTO `menu` VALUES ('12', '1', '菜单12', '', '1');
INSERT INTO `menu` VALUES ('13', '1', '菜单13', '', '1');
INSERT INTO `menu` VALUES ('111', '11', '菜单111', '', '1');
INSERT INTO `menu` VALUES ('121', '12', '菜单121', '', '1');
INSERT INTO `menu` VALUES ('122', '12', '菜单122', '', '1');
INSERT INTO `menu` VALUES ('1221', '122', '菜单1221', '', '1');
INSERT INTO `menu` VALUES ('1222', '122', '菜单1222', '', '1');
INSERT INTO `menu` VALUES ('12211', '1222', '菜单12211', '', '1');
```

查询

```mysql
select id from (
   select t1.id,
   if(find_in_set(parent_id,@pids) >0,@pids := concat(@pids,',', id),0) as ischild
   from (
        select id,parent_id from re_menu t where t.status =1 order by parent_id, id
       ) t1,
       (select@pids := 要查询的菜单节点 id) t2
   ) t3 where ischild !=0
```

> 如果parent_id 在@pid中，则将@pid 里面再加上parent_id,按行依次执行


## 其他解决办法

[Java递归查询某个节点下所有子节点多级信息（递归部门查询，递归树形结构数据查询）](https://blog.csdn.net/lc8023xq/article/details/107607137)