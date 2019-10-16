#!/bin/bash

if [ `whoami` == "root" ];then
    echo "root can not run this shell script,不能使用root来执行这个脚本！！"
    exit 1
fi

MYSQL_PATH="/home/mamba/soft/mysql"

cluster_num=$1

if [ ! "${cluster_num}" ]; then
  echo "输入安装伪集群的数量不能为 null，且不能小于2个,举个例子：sh test.sh 2"
  exit 1
fi

# 判断是否是数字
if [ "$cluster_num" -gt 0 ] 2>/dev/null; then
  echo ""
else
  echo '请输入数字..'
  exit 1
fi

# 创建数量 -gt 表示大于,-lt 小于,-le表示小于等于
if [ "$cluster_num" -lt 1 ]; then
  echo "输入安装伪集群的数量不能小于2个"
  exit 1
else
  echo "创建集群的数量:${cluster_num}"
fi

echo '默认安装目录: ' "${MYSQL_PATH}"

# 创建文件夹
mkdir -vp "${MYSQL_PATH}"

cd "${MYSQL_PATH}"

# 安装新版mysql之前，我们需要将系统自带的mariadb-lib卸载
rpm -qa|grep mariadb
# 由于不知道版本就使用 *
rpm -e mariadb-libs-* --nodeps

# 163 镜像 http://mirrors.163.com/mysql/Downloads/MySQL-8.0/
# tsinghua 清华镜像  https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/?C=S&O=A
# 文件比较大，如果网速不好，下载比较慢

wget https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz

#  解压tar // 注意 tar -xvf xxx.tar 不需要 -zxvf 有参数z 可能有问题.
tar tar -xvf mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz

MYSQL_INSTALL_VERSION=mysql-8.0.15-linux-glibc2.12-x86_64

MYSQL_MASTER_3306=mysql_master_3306

MYSQL_SLAVE_3307=mysql_slave_3307

rm -rf ${MYSQL_MASTER_3306}
rm -rf ${MYSQL_SLAVE_3307}

mkdir ${MYSQL_MASTER_3306}  ${MYSQL_SLAVE_3307}

cp -rf ${MYSQL_INSTALL_VERSION} ${MYSQL_MASTER_3306}

mv ${MYSQL_INSTALL_VERSION} ${MYSQL_SLAVE_3307}

cd ${MYSQL_PATH}/${MYSQL_MASTER_3306}

mkdir data
mkdir tmp
mkdir log
mkdir etc

MY_CNF="
[client]
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR_DIR/tmp/mysql.sock
default-character-set=utf8

[mysql]
basedir=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/
datadir=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/data/
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
port=3306
user=mamba

log_timestamps=SYSTEM
log-error=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/log/mysql.err

default-character-set=utf8

[mysqld]
basedir=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/
datadir=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/data/
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
port=3306
user=mamba
log_timestamps=SYSTEM
collation-server = utf8_unicode_ci
character-set-server = utf8

default_authentication_plugin= mysql_native_password
language=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/share/english


[mysqld_safe]
log-error=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/log/mysqld_safe.err
pid-file=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysqld.pid
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock

[mysql.server]
basedir=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock

[mysqladmin]
socket=/home/mamba/soft/mysql/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
"


echo "$ZK_CFG_CONTENT" > "cluster/$zookeeper_cluster_name"/conf/"$zookeeper_cluster_name".cfg


# 赋予账号 mamba权限
chown -R mamba:mamba ${MYSQL_PATH}/${MYSQL_MASTER_3306}


./bin/mysqld --initalize --user=mamba --basedir=${MYSQL_PATH}/${MYSQL_MASTER_3306} --data=${MYSQL_PATH}/${MYSQL_MASTER_3306}/data defaults-file=${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf

## test local

# 已经验证OK
bin/mysqld  --defaults-file=/home/mamba/soft/mysql/mysql_master_3306/etc/my.cnf --initialize --user=mysql

# 已经验证OK
./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf &

###


./bin/mysqld --user=mysql --basedir=/usr/soft/mysql/mysql_master_3306 --datadir=//usr/soft/mysql/mysql_master_3306/data --initialize --defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf



./bin/mysqld_safe --defaults-file=/usr/soft/mysql/mysql_master_3306/etc/my.cnf &



MYSQL_CLUSER_PREFIX_NAME="330"

# 端口前缀
PORT_PREFIX=700

LOCAL_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d '/'`

echo "ip 地址：$LOCAL_IP"

cd ${MYSQL_PATH}

for cluster_i in $(seq 1 $cluster_num);
do
  echo "开始复制...$cluster_i"
  # 集群名字
  redis_cluster_name=${MYSQL_CLUSER_PREFIX_NAME}${cluster_i};

  mkdir -vp ${MYSQL_PATH}/cluster/${redis_cluster_name}

  redis_port=${PORT_PREFIX}${cluster_i};

  rm -rf "$redis_cluster_name"
  cp -rf redis-5.0.6/redis.conf  cluster/${redis_cluster_name}/

  cd cluster/${redis_cluster_name}
  pwd
  # 替换的内容 sed -i "s#^filename=.*#filename=$user_device#" ./ebs_*.fio  redis.conf
  # 自定义的分隔符 为 ?
  # \n 是换行
  sed -i "s?port 6379?port ${redis_port}?" redis.conf
  sed -i "s?daemonize no?daemonize yes?" redis.conf
  sed -i "s?# cluster-enabled yes?cluster-enabled yes?" redis.conf
  sed -i "s?# cluster-config-file nodes-6379.conf?cluster-config-file nodes-${redis_port}.conf?" redis.conf
  sed -i "s?# cluster-node-timeout 15000?cluster-node-timeout 5000?" redis.conf
  sed -i "s?appendonly no?appendonly yes?" redis.conf
  sed -i "s?pidfile /var/run/redis_6379.pid?pidfile /var/run/redis_${redis_port}.pid?" redis.conf
  sed -i "s?# bind 127.0.0.1 ::1?bind 127.0.0.1?" redis.conf

  pwd ${MYSQL_PATH}/cluster/${redis_cluster_name}
  cd ${MYSQL_PATH}/cluster/${redis_cluster_name}
  # 这里启动注意 路径
  redis-server redis.conf
  cd ${MYSQL_PATH}

done


