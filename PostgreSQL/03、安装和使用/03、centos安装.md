
# centos 安装



## 遇到问题


### [安装postgreSQL出现configure:error:readline library not found解决方法及pg安装全过程](https://blog.csdn.net/wypblog/article/details/6863342)

```
[root@HK81-107 postgresql-9.0.0]# ./configure

configure: error: readline library not found
If you have readline already installed, see config.log for details on the
failure.  It is possible the compiler isnt looking in the proper directory.
Use --without-readline to disable readline support.

     根据提示，应该是没有安装 readline包。

3 检查系统是否安装 readline 包
[root@HK81-107 postgresql-9.0.0]# rpm -qa | grep readline
readline-5.1-3.el5

   说明系统已经安装了 readline包。

4 通过 yum 搜索相关的 readline 包
[root@HK81-107 postgresql-9.0.0]# yum search readline
lftp.i386 : A sophisticated file transfer program
lftp.i386 : A sophisticated file transfer program
php-readline.i386 : Standard PHP module provides readline library support
lftp.i386 : A sophisticated file transfer program
readline.i386 : A library for editing typed command lines.
compat-readline43.i386 : The readline 4.3 library for compatibility with older software.
readline-devel.i386 : Files needed to develop programs which use the readline library.
readline.i386 : A library for editing typed command lines.

 根据提示，有一个包引起了注意 "readline-devel", 猜想可能与这个包有关。
 
5 安装 readline-devel 包
[root@HK81-107 postgresql-9.0.0]# yum -y install -y readline-devel
```

### [failure.  It is possible the compiler isn't looking in the proper directory.]()
```
checking for inflate in -lz... no
configure: error: zlib library not found
If you have zlib already installed, see config.log for details on the
failure. It is possible the compiler isn't looking in the proper directory.
Use --without-zlib to disable zlib support.
```
出现这种错误，说明你的系统缺少zlib库，输入： rpm -qa | grep zlib，如果出现如下提示：
```
zlib-1.2.3-29.el6.x86_64
zlib-1.2.3-29.el6.i686
jzlib-1.0.7-7.5.el6.x86_64
```
则说明，你的电脑缺少 zlib-devel库，安装一下即可
```shell
[root@HK81-107 postgresql-9.0.0]# yum -y install -y zlib-devel
```

