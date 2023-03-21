#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare tables' data for mysql
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
file_out_dir=$task_out_dir/"6_1_Tables_Data_Compare"
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
if [ -d $file_out_dir ];then
  rm -rf $file_out_dir/*
else
  mkdir -p $file_out_dir
fi

#验证源数据库连接信息
mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "show databases;" 2>/dev/null >/dev/null
if [ $? -eq 0 ];then
  myLog 2 "源端数据库登陆验证成功" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "源端数据库登陆验证失败，请确认数据库连接信息" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
  exit
fi

#目标端数据库验证
mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip  -N -e "show databases;" 2>/dev/null >/dev/nul
if [ $? -eq 0 ];then
  myLog 2 "目标端数据库登陆验证成功" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "目标端数据库登陆验证失败，请确认数据库连接信息" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
  exit
fi

# 数据校验
dump_db=`cat $task_out_dir/$db_list_file_new`
# 源端数据导出
myLog 2 "src data dumping" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
mysqldump --max_allowed_packet=1024M -u$src_username -p$src_password -P$src_port -h$src_ip  -q -e -R -C --databases $dump_db 2>>$file_out_dir/error.log >$file_out_dir/src.sql
sed -e "/^\/.*\;$/d" -e "/^--/d" -e "/^$/d" $file_out_dir/src.sql > $file_out_dir/src_cut.sql
if [ $? -eq 0 ];then
  myLog 2 "src data dump success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "src data dump failed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
  myLog 4 "dest data dump failed" >> $file_out_dir/error.log && myecho 3 "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] check failed table info: Please review $file_out_dir/error.log" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
fi
# 目标端数据导出
myLog 2 "dest data dumping" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
mysqldump --max_allowed_packet=1024M -u$dest_username -p$dest_password -P$dest_port -h$dest_ip  -q -e -R -C --databases $dump_db 2>>$file_out_dir/error.log >$file_out_dir/dest.sql
sed -e "/^\/.*\;$/d" -e "/^--/d" -e "/^$/d" $file_out_dir/dest.sql > $file_out_dir/dest_cut.sql

if [ $? -eq 0 ];then
  myLog 2 "dest data dump success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "dest data dump failed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
  myLog 4 "dest data dump failed" >> $file_out_dir/error.log && myecho 3 "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] check failed table info: Please review $file_out_dir/error.log" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
fi
# 导出数据比对
diff $file_out_dir/src_cut.sql $file_out_dir/dest_cut.sql >> $file_out_dir/error.log
if [ ! -s $file_out_dir/error.log ];then
  myecho 1 "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Data check passed"
  myLog 2 "Data check passed" >> $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myecho 3 "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] check failed table info: Please review $file_out_dir/error.log"
  myLog 4 "check failed table info: Please review $file_out_dir/error.log" >> $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
fi

