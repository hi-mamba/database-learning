## [mysql/mysql-server](https://hub.docker.com/r/mysql/mysql-server/)

## [Basic Steps for MySQL Server Deployment with Docker](https://dev.mysql.com/doc/mysql-installation-excerpt/5.5/en/docker-mysql-getting-started.html)

# docker 安装MYSQL
```shell script
shell> docker pull mysql/mysql-server:tag
```
  Refer to the list of supported tags above. 
  If :tag is omitted, the latest tag is used, 
  and the image for the latest GA version of MySQL Server is downloaded.
  

## 启动mysql

命令：
> docker run -p 33060:3306 -v $PWD/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password --name mysq9527 -d 16f9fffc75d8

-p33060:3306：将容器的3306端口映射到主机的33060端口；

-v$PWD/mysql:/var/lib/mysql：将主机当前目录下的/mysql挂载到容器的/var/lib/mysql；(可以不设置这个)

-e MYSQL_ROOT_PASSWORD=password：初始化root用户的密码；

--name 给容器命名，mysql9527；(可以不命名)

-d 表示容器在后台运行
 
> docker run -p 3306:3306 -e MYSQL_ROOT_PASSWORD=密码 -d bb639ef9778e
 
## 进入docker 安装MYSQL 里

查看 docker MYSQL 的 container id

> docker ps
```
kobe@kubernetes-master:~$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS                 PORTS                                                                      NAMES
f58323bfe1e9        mysql/mysql-server    "/entrypoint.sh my..."   2 hours ago         Up 2 hours (healthy)   3306/tcp, 33060/tcp                                                        blissful_kirch
0bd463c607a1        kiwenlau/hadoop:1.0   "sh -c 'service ss..."   2 hours ago         Up 2 hours                                                                                        hadoop-slave2
c23e76e8eea3        kiwenlau/hadoop:1.0   "sh -c 'service ss..."   2 hours ago         Up 2 hours                                                                                        hadoop-slave1
87be8b442374        kiwenlau/hadoop:1.0   "sh -c 'service ss..."   2 hours ago         Up 2 hours             0.0.0.0:8088->8088/tcp, 0.0.0.0:9011->9011/tcp, 0.0.0.0:50070->50070/tcp   hadoop-master
pankui@kubernetes-master:~$

```

需要进入mysql服务中(下面的 container id 可以不输入完整的)
 
> kobe@kubernetes-master:~$ docker exec -it f5 bash

然后就可以执行MYSQL 客户端命令连接mysql 服务器了

> mysql -u root -p

注意你启动mysql的时候会有一个默认密码

## [创建一个远程访问账号](./13、创建一个远程访问账号.md)

然后就可以使用客户端连接了，注意映射端口



