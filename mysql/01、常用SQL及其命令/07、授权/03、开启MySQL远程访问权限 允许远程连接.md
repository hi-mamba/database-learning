
# 开启MySQL远程访问权限 允许远程连接


[创建一个远程访问账号](../../00、安装/13、创建一个远程访问账号.md)

## 遇到异常

[原文](https://www.jianshu.com/p/53ac2d55b279)

> MySQL 报错 ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement

报错提示告诉我们，需要重新设置密码。那我们就重新设置一下密码，命令如下：

> set password = password('root');

