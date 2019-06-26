


## [原文](https://www.cnblogs.com/letcafe/p/mysqlautodump.html)


 # shell 定时备份数据


 在Linux中，使用vi或者vim编写脚本内容并命名为：mysql_dump_script.sh

 ```bash
#!/bin/bash

#保存备份个数，备份31天数据
number=31
#备份保存路径
backup_dir=/root/mysqlbackup
#日期
dd=`date +%Y-%m-%d-%H-%M-%S`
#备份工具
tool=mysqldump
#用户名
username=root
#密码
password=TankB214
#将要备份的数据库
database_name=edoctor

#如果文件夹不存在则创建
if [ ! -d $backup_dir ]; 
then     
    mkdir -p $backup_dir; 
fi

#简单写法  mysqldump -u root -p123456 users > /root/mysqlbackup/users-$filename.sql
# 如果这里连接有问题可以添加 -h ip地址 -u 账号 -p 密码 -P 端口  数据库
$tool -u $username -p$password $database_name > $backup_dir/$database_name'_'$dd.sql

#写创建备份日志
echo "create $backup_dir/$database_name"_"$dd.dupm" >> $backup_dir/log.txt

#找出需要删除的备份
delfile=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | head -1`

#判断现在的备份数量是否大于$number
count=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | wc -l`

if [ $count -gt $number ]
then
  #删除最早生成的备份，只保留number数量的备份
  rm $delfile
  #写删除文件日志
  echo "delete $delfile" >> $backup_dir/log.txt
fi
 ```


 如上代码主要含义如下：

1.首先设置各项参数，例如number最多需要备份的数目，备份路径，用户名，密码等。

2.执行mysqldump命令保存备份文件，并将操作打印至同目录下的log.txt中标记操作日志。

3.定义需要删除的文件：通过ls命令获取第九列，即文件名列，再通过

head -1
实现定义操作时间最晚的那个需要删除的文件。

4.定义备份数量：通过ls命令加上

wc -l
统计以sql结尾的文件的行数。

5.如果文件超出限制大小，就删除最早创建的sql文件




## 使用crontab定期执行备份脚本

cron的配置文件称为“crontab”，是“cron table”的简写。


```bash
* * * * * /root/mysql_backup_script.sh
```

