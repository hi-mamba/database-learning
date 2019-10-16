#!/bin/bash

# 前提是各个服务已经启动 redis-server  ${REDIS_PATH}/cluster/${redis_cluster_name}/redis.conf

# 创建集群 https://redis.io/topics/cluster-tutorial

redis-cli --cluster create 127.0.0.1:7006 127.0.0.1:7001 \
127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
--cluster-replicas 1

