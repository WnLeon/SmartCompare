#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare tables' ddl for mysql
# Version: V1.1
# Update: 2023-2-23

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}

#校验文件存储位置
file=$task_out_dir/"5_Tables_DDL_Compare"
db_file_dir=$task_out_dir
db_list_file=$db_list
db_list_file_new=$db_list_file.new

#排除校验的库所在位置
exclude_db_list=$exclude_file
myDos_unix $exclude_db_list

#源端的数据库
src_ip=$src_ip
src_port=$src_port
src_username=$src_username
src_password=$src_password

#目标端的数据库
dest_ip=$dest_ip
dest_port=$dest_port
dest_username=$dest_username
dest_password=$dest_password

#依赖0_1执行
if [ ! -d $file ];then
  mkdir -p $file
else
  rm -rf $file/${src_ip}_ddlcheck.log
fi

for v in `cat ${db_file_dir}/${db_list_file_new}`
do
  for i in `mysql -u$src_username -p$src_password -P$src_port -h$src_ip -N -e "select TABLE_NAME from information_schema.tables where TABLE_SCHEMA='$v'"`
  do
    rm -rf $file/$v/$i
    mkdir -p $file/$v/$i
    myLog 2 ">>>>>start table : $v.$i"
    mysql -u$src_username -p$src_password -P$src_port -h$src_ip -N -D$v -e "show create table $i" > $file/$v/$i/src_$i.sql
    myLog 2 "src finish."
    mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip -N -D$v -e "show create table $i" > $file/$v/$i/dest_$i.sql
    myLog 2 "dest finish."
    myLog 2 "<<<<<end table : $v.$i "
    echo ""
    diff $file/$v/$i/src_$i.sql $file/$v/$i/dest_$i.sql > $file/$v/$i/check_diff.sql
    if [ $? -eq 0 ]; then
            rm -rf $file/$v/$i/check_diff.sql
            myLog 2 "$v.$i check success" | tee -a $file/${src_ip}_ddlcheck.log
    else
            myLog 4 "$v.$i check failed" | tee -a $file/${src_ip}_ddlcheck.log
    fi
  done
done
cat $file/${src_ip}_ddlcheck.log | grep failed
if [ $? -eq 0 ];then
  myecho 3 "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] DB:$src_ip & DB:$dest_ip DDL Check Failed , Please review $file/${src_ip}_ddlcheck.log\nFailed Info:\n`cat $file/${src_ip}_ddlcheck.log | grep failed`" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
else
  myecho 1 "$(date '+%Y-%m-%d %H:%M:%S') [INFO] DB:$src_ip & DB:$dest_ip DDL Check Passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
fi

