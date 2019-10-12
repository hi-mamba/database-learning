#!/bin/bash

REDIS_PATH="/home/mamba/soft/redis"

cluster_num=$1

if [ ! "${cluster_num}" ]; then
  echo "输入安装伪集群的数量不能为 null，且不能小于6个【6个redis节点，其中三个为主节点，三个为从节点】,举个例子：sh test.sh 6"
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
if [ "$cluster_num" -lt 6 ]; then
  echo "输入安装伪集群的数量不能小于6个"
  exit 1
else
  echo "创建集群的数量:${cluster_num}"
fi

echo '默认安装目录: ' "${REDIS_PATH}"

# 创建文件夹
mkdir -vp "${REDIS_PATH}/cluster"

cd "${REDIS_PATH}"


wget http://download.redis.io/releases/redis-5.0.6.tar.gz

tar -zxvf redis-5.0.6.tar.gz

cd redis-5.0.6

make && make install


REDIS_CLUSER_PREFIX_NAME="700"

# 端口前缀
PORT_PREFIX=700

LOCAL_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d '/'`

echo "ip 地址：$LOCAL_IP"

cd ${REDIS_PATH}

for cluster_i in $(seq 1 $cluster_num);
do
  echo "开始复制...$cluster_i"
  # 集群名字
  redis_cluster_name=${REDIS_CLUSER_PREFIX_NAME}${cluster_i};

  mkdir -vp ${REDIS_PATH}/cluster/${redis_cluster_name}

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

  pwd ${REDIS_PATH}/cluster/${redis_cluster_name}
  cd ${REDIS_PATH}/cluster/${redis_cluster_name}
  # 这里启动注意 路径
  redis-server redis.conf
  cd ${REDIS_PATH}

done


