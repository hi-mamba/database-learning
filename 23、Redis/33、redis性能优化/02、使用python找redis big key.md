## [原文](https://www.jianshu.com/p/62ec1d86e45a)

# 使用python找redis big key

统计生产上比较大的key
```bash
./redis-cli --bigkeys

```
对redis中的key进行采样，寻找较大的keys。是用的是scan方式，
不用担心会阻塞redis很长时间不能处理其他的请求。
执行的结果可以用于分析redis的内存的只用状态，每种类型key的平均大小。


感谢一波先：本文参照此文[如何搜索过大的key](https://help.aliyun.com/knowledge_detail/56949.html#concept-frf-r2z-xdb)，
但此文应该是针对阿里云的redis，里面有不支持的redis命令故重新改一下。

注: 此文的目的是针对 redis 集群操作，但 redis 集群不支持 scan，故只能对每一个节点都跑一下

## 1、执行以下命令下载python的redis客户端 或者直接访问链接下载
```bash
wget "https://pypi.python.org/packages/68/44/5efe9e98ad83ef5b742ce62a15bea609ed5a0d1caf35b79257ddb324031a/redis-2.10.5.tar.gz#md5=3b26c2b9703b4b56b30a1ad508e31083"

```
## 2、减压并安装
```bash
tar -xvf redis-2.10.5.tar.gz
cd redis-2.10.5
sudo python setup.py install

```
3、创建如下脚本

```python
import sys
import redis

def check_big_key(r, k):
  bigKey = False
  length = 0 
  try:
    type = r.type(k)
    if type == "string":
      length = r.strlen(k)
    elif type == "hash":
      length = r.hlen(k)
    elif type == "list":
      length = r.llen(k)
    elif type == "set":
      length = r.scard(k)
    elif type == "zset":
      length = r.zcard(k)
  except:
    return
  if length > 10240:
    bigKey = True
  if bigKey :
    print db,k,type,length

def find_big_key_sharding(db_host, db_port, db_password, db_num):
  r = redis.StrictRedis(host=db_host, port=db_port, password=db_password, db=db_num)
  cursor = '0'
  while True:
    iscan = r.scan(cursor=cursor, count=1000)
    for k in iscan[1]:
      check_big_key(r, k)
    cursor = iscan[0]
    if cursor == 0:
      break;  
    
if __name__== '__main__':
  if len(sys.argv) != 4:
     print 'Usage: python ', sys.argv[0], ' host port password '
     exit(1)
  db_host = sys.argv[1]
  db_port = sys.argv[2]
  db_password = sys.argv[3]
  r = redis.StrictRedis(host=db_host, port=int(db_port), password=db_password)
  info =  r.info()
  db = 'db0';
  find_big_key_sharding(db_host, db_port, db_password, db.replace("db", ""))

```

## 4、在命令窗口使用脚本

```python
python xxx.py host port password
# xxx.py：即上面脚本文件目录
# host、port、password：  =redis的host、port 和 password 需按顺序
# 如 python /Library/work/test.py 127.0.0.1 7001 mima

```
## 5、说明

1、第4步的 port 需要在命令行手动切换（或者修改代码写一下循环o(_)o）

2、脚本文件里面的大key大小是10240B，可以直接修改

3、脚本文件里面的 count 也是可以修改的，count 的作用是每次获取多少个key

本人python小白，脚本文件完全参考上述文章，那里改的有问题还请提出建议 ∠( ᐛ 」∠)＿

