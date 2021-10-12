#!/bin/bash


echo "#### start ###### "

if [ `whoami` == "root" ];then
    echo "root can not run this shell script,不能使用root来执行这个脚本！！"
    exit 1
fi

POSTGRESQL_PATH="/tol/soft/postgresql"

# 创建文件夹
mkdir -vp "${POSTGRESQL_PATH}"
mkdir -vp "${POSTGRESQL_PATH}"/data
mkdir -vp "${POSTGRESQL_PATH}"/logs

cd ${POSTGRESQL_PATH}

# 安装
# wget https://ftp.postgresql.org/pub/source/v12.0/postgresql-12.0.tar.gz
wget https://mirrors.tuna.tsinghua.edu.cn/postgresql/source/v12.0/postgresql-12.0.tar.gz

# 解压
tar -zxvf postgresql-12.0.tar.gz

cd postgresql-12.0

# 检查依赖包

yum install -y bison
yum install -y flex
yum install -y readline-devel
yum install -y zlib-devel

# 配置选项生成Makefile，默认安装到目录：/app/postgresql-12.0

./configure --prefix=${POSTGRESQL_PATH}/postgresql

# 编译并安装
make & make install

echo "编译并安装 完成"
# 判断用户是否存在，创建，添加postgres 用户

existUser=`cat /etc/passwd |cut -f 1 -d : |grep "postgres"`
echo "existUser=" ${existUser}

if [[ "" ==  "$existUser" ]]; then
  useradd -g postgres postgres
fi

chown -R postgres:postgres /tol/soft/postgresql
chmod -R 700 /tol/soft/postgresql

# 切换用户 且 初始化
su postgres -c "${POSTGRESQL_PATH}/postgresql/bin/initdb -D ${POSTGRESQL_PATH}/data"

su postgres -c "./${POSTGRESQL_PATH}/postgresql/bin/pg_ctl -D ${POSTGRESQL_PATH}/data -l ${POSTGRESQL_PATH}/logs/postgresql.log start &"






