#!/bin/bash

# mysql_pseudo_cluster_install.sh

echo "####   这个脚本已经配置好配置文件 主从，但是没有配置数据库配置创建账号，设置主从 需要手动去配置 ###### "

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

cd ${MYSQL_PATH}

# 安装新版mysql之前，我们需要将系统自带的mariadb-lib卸载
rpm -qa|grep mariadb
# 由于不知道版本就使用 *
rpm -e mariadb-libs-* --nodeps

# 163 镜像 http://mirrors.163.com/mysql/Downloads/MySQL-8.0/
# tsinghua 清华镜像  https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/?C=S&O=A
# 文件比较大，如果网速不好，下载比较慢

# wget 通配符
# https://stackoverflow.com/questions/18107236/using-wildcards-in-wget-or-curl-query
# wget www.download.example.com/dir/{version,old}/package{00..99}.rpm
# 镜像 更新之后，下面的版本就不存在了，擦
# wget https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz

# 获取 第一个版本，因为有多个版本
MYSQL_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0/";

# 过滤关键词和 获取href 里面的文件
MYSQL_VERSION=`curl -L -s ${MYSQL_MIRROR} | grep -iF "linux-glibc2.12-x86_64.tar.xz" |sed -r 's/^.+href="([^"]+)".+$/\1/'  |head -1`

wget ${MYSQL_MIRROR}/${MYSQL_VERSION}

#  解压tar // 注意 tar -xvf xxx.tar 不需要 -zxvf 有参数z 可能有问题.
# 通配符，因为不知道版本
tar -xvf mysql-8.*

MYSQL_MASTER_3306=mysql_master_3306
rm -rf ${MYSQL_MASTER_3306}

# 重命名，过滤掉压缩包 且只需要指定的包
mv `ls -1 |grep -v *.tar.xz |grep -v *.sh |grep glibc2.12-x86_64` ${MYSQL_MASTER_3306}


cd ${MYSQL_PATH}/${MYSQL_MASTER_3306}
mkdir data tmp log etc

cd ${MYSQL_PATH}
MYSQL_SLAVE_3307=mysql_slave_3307
rm -rf ${MYSQL_SLAVE_3307}

# Linux中用mkdir同时创建多个文件夹
mkdir ${MYSQL_SLAVE_3307}
cp -rf ${MYSQL_MASTER_3306}/* ${MYSQL_SLAVE_3307}/

# 配置文件
MY_CNF="
[client]
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR_DIR/tmp/mysql.sock
default-character-set=utf8

[mysql]
basedir=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/
datadir=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/data/
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
port=
user=mamba

log_timestamps=SYSTEM
log-error=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/log/mysql.err

default-character-set=utf8

[mysqld]
server-id=
basedir=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/
datadir=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/data/
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
port=
user=mamba
log_timestamps=SYSTEM
collation-server = utf8_unicode_ci
character-set-server = utf8

default_authentication_plugin= mysql_native_password
language=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/share/english


[mysqld_safe]
log-error=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/log/mysqld_safe.err
pid-file=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysqld.pid
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock

[mysql.server]
basedir=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock

[mysqladmin]
socket=${MYSQL_PATH}/NEED_TO_BE_REPLACED_DIR/tmp/mysql.sock
"

echo "$MY_CNF" > ${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf
echo "$MY_CNF" > ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf


# \n 换行
sed -i "s?NEED_TO_BE_REPLACED_DIR?${MYSQL_MASTER_3306}?" ${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf
sed -i "s?port=?port=3306?" ${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf
sed -i "s?server-id=?server-id=1 \nlog-bin=master-bin \nlog-bin-index=master-bin.index?" ${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf


sed -i "s?NEED_TO_BE_REPLACED_DIR?${MYSQL_SLAVE_3307}?"  ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf
sed -i "s?port=?port=3307?"  ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf
sed -i "s?server-id=?server-id=2 \nrelay-log=slave-relay-log \nrelay-log-index=slave-relay-bin.index?"  ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf





# 赋予账号 mamba权限
chown -R mamba:mamba ${MYSQL_PATH}/${MYSQL_MASTER_3306}
chown -R mamba:mamba ${MYSQL_PATH}/${MYSQL_SLAVE_3307}


# 启动之前把 MYSQL 服务都KILL 掉
PID=`ps -eaf | grep mysql | grep -v grep | grep -v mysql_pseudo_cluster_install.sh | awk '{print $2}'`
if [[ "" !=  "$PID" ]]; then
  echo "killing $PID"
  kill -9 $PID
fi

rm -rf ${MYSQL_PATH}/${MYSQL_MASTER_3306}/data
rm -rf ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/data

# 初始化 注意 --defaults-file 必须放在mysqld 后面  且把输出日志放到文件里，为了过滤获取root的密码
${MYSQL_PATH}/${MYSQL_MASTER_3306}/bin/mysqld  --defaults-file=${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf --user=mamba --initialize 2>&1 |tee ${MYSQL_PATH}/${MYSQL_MASTER_3306}/log/output.log
# 过滤且获取密码所在的地方  https://stackoverflow.com/questions/418896/how-to-redirect-output-to-a-file-and-stdout
MYSQL_MASTER_3306_PWD=`cat ${MYSQL_PATH}/${MYSQL_MASTER_3306}/log/output.log |grep  "password is generated for root@localhost"  |awk '{print $13}'`
## 保存启动的文件，为了过滤获取初始化root 账号的密码。哈哈哈哈哈
echo "######### ${MYSQL_MASTER_3306}自动生成密码:" ${MYSQL_MASTER_3306_PWD}


${MYSQL_PATH}/${MYSQL_SLAVE_3307}/bin/mysqld  --defaults-file=${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf --user=mamba --initialize 2>&1 |tee ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/log/output.log
MYSQL_SLAVE_3307_PWD=`cat ${MYSQL_PATH}/${MYSQL_SLAVE_3307}/log/output.log |grep  "password is generated for root@localhost"  |awk '{print $13}'`
echo "######### ${MYSQL_SLAVE_3307}自动生成密码:" ${MYSQL_SLAVE_3307_PWD}

# 启动服务

${MYSQL_PATH}/${MYSQL_MASTER_3306}/bin/mysqld_safe --defaults-file=${MYSQL_PATH}/${MYSQL_MASTER_3306}/etc/my.cnf &

${MYSQL_PATH}/${MYSQL_SLAVE_3307}/bin/mysqld_safe --defaults-file=${MYSQL_PATH}/${MYSQL_SLAVE_3307}/etc/my.cnf &
