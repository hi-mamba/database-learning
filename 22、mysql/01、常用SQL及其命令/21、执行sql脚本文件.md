

# 执行sql脚本文件

## 注意下选择数据库

 

## 方法一 使用cmd命令执行(windows下，unix或linux在的其控制台下)

【Mysql的bin目录】\mysql –u用户名 –p密码 –D数据库<【sql脚本文件路径全名】，示例：
```mysql

D:\mysql\bin\mysql –uroot –p123456 -Dtest<d:\test\ss.sql

```
注意：
- A、如果在sql脚本文件中使用了use 数据库，则-D数据库选项可以忽略

- B、如果【Mysql的bin目录】中包含空格，
则需要使用“”包含，如：“C:\Program Files\mysql\bin\mysql” –u用户名 –p密码 –D数据库<【sql脚本文件路径全名】

## 方法二 进入mysql的控制台后，使用source命令执行

Mysql>source 【sql脚本文件的路径全名】 或 Mysql>\. 【sql脚本文件的路径全名】，示例：

```mysql
source d:\test\ss.sql  
```
或者

```mysql
\. d:\test\ss.sql
```
