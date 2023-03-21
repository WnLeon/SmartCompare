#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare users & privileges for mysql
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
file_out_dir=$task_out_dir/"2_Users&Privs_Compare"
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
#
if [ ! -d $file_out_dir ];then
  mkdir -p $file_out_dir
fi

mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "SELECT DISTINCT CONCAT('User: ''',user,'''@''',host,''';') AS query FROM mysql.user;" > $file_out_dir/src_users

mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip  -N -e "SELECT DISTINCT CONCAT('User: ''',user,'''@''',host,''';') AS query FROM mysql.user;" > $file_out_dir/dest_users

diff $file_out_dir/src_users $file_out_dir/dest_users > $file_out_dir/diff_out

awk -F: '{print$2}' $file_out_dir/src_users > $file_out_dir/users_2

if [ $? -ne 0 ];then
  myLog 4 "Users check failed, please review $file_out_dir/diff_out" |  tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
else
  myLog 2 "Users check passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
  for u in `cat $file_out_dir/users_2`
  do
    mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "show grants for $u" >> $file_out_dir/src_privs
    mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip  -N -e "show grants for $u" >> $file_out_dir/dest_privs
  done
  if [ $? -eq 0 ];then
    diff $file_out_dir/src_privs $file_out_dir/dest_privs >/dev/null
    if [ $? -eq 0 ];then
      myLog 2 "users'privs check passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
    else
      diff $file_out_dir/src_privs $file_out_dir/dest_privs > $file_out_dir/diff_out
      myLog 2 "users'privs check failed, please review $file_out_dir/diff_out" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
    fi
  fi
fi

