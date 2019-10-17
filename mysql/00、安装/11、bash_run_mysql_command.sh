#!/bin/bash

## 脚本不可用！！！！

MYSQL_PATH="/home/mamba/soft/mysql"

MYSQL_MASTER_3306="mysql_master_3306"

MYSQL_MASTER_3306_PWD=`cat ${MYSQL_PATH}/${MYSQL_MASTER_3306}/log/output.log |grep  "password is generated for root@localhost"  |awk '{print $13}'`

echo "######### ${MYSQL_MASTER_3306}自动生成密码:" ${MYSQL_MASTER_3306_PWD}

# mysql的安全策略不能通过命令行加密码的方式，执行命令。可以把用户名和密码写在配置文件中。
# mysql: [Warning] Using a password on the command line interface can be insecure.
${MYSQL_PATH}/${MYSQL_MASTER_3306}/bin/mysql --user="root" --password="${MYSQL_MASTER_3306_PWD}" --socket ${MYSQL_PATH}/${MYSQL_MASTER_3306}/tmp/mysql.sock  <<  EOF

ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'root123';
exit;

EOF


${MYSQL_PATH}/${MYSQL_MASTER_3306}/bin/mysql --user="root" --password="${MYSQL_MASTER_3306_PWD}" --socket ${MYSQL_PATH}/${MYSQL_MASTER_3306}/tmp/mysql.sock  <<  EOF

show databases;
exit;

EOF
