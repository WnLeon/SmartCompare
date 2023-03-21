#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare routines & events & triggers for mysql
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
file_out_dir=$task_out_dir/"3_Procedures&Functions&Triggers_Compare"
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

#依赖0_1执行
#
if [ ! -d $file_out_dir ];then
  mkdir -p $file_out_dir
fi

mysqldump --max_allowed_packet=1024M -h$src_ip -u$src_username -p$src_password -R -E --triggers -ndt --socket=/tmp/mysql.sock -B `cat $task_out_dir/$db_list_file_new `>$file_out_dir/src_ret
sed -e "/^\/.*\;$/d" -e "/^--/d" -e "/^$/d" $file_out_dir/src_ret > $file_out_dir/src_ret_cut

mysqldump --max_allowed_packet=1024M -h$dest_ip -u$dest_username -p$dest_password -R -E --triggers -ndt --socket=/tmp/mysql.sock -B `cat $task_out_dir/$db_list_file_new `>$file_out_dir/dest_ret
sed -e "/^\/.*\;$/d" -e "/^--/d" -e "/^$/d" $file_out_dir/dest_ret > $file_out_dir/dest_ret_cut
diff $file_out_dir/src_ret_cut $file_out_dir/dest_ret_cut > $file_out_dir/diff_out

if [ $? -eq 0 ];then
  myLog 2 "Procedures&Functions&Triggers check passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "Procedures&Functions&Triggers check failed, please review $file_out_dir/diff_out" |  tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
fi