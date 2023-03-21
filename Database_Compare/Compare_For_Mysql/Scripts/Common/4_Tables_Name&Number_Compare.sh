#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare tables' name & number for mysql
# Version: V1.1
# Update: 2023-2-23

#对比源目标表数量及名称
# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}

#校验文件存储位置
check_dir=$task_out_dir/"4_Tables_Name&Number_Compare"
#排除校验的库所在位置
exclude_db_list=$exclude_file
myDos_unix $exclude_db_list

#从information_schema获取所有库表的SQL
str=""
for exclude_db in `cat $exclude_db_list`;
do
 str=$str`echo -n "'${exclude_db}'",`
done
 str=`echo $str | sed 's/,$//g'`

Sql="select TABLE_SCHEMA,TABLE_NAME from information_schema.tables where TABLE_SCHEMA NOT IN ""("$str")"

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

if [ ! -d $check_dir ];then
    mkdir -p $check_dir
else
    rm -rf $check_dir/src.txt
    rm -rf $check_dir/dest.txt
    rm -rf $check_dir/*.log
fi

mysql -u$src_username -p$src_password -P$src_port -h$src_ip -N -e "$Sql"  >  $check_dir/src_0.txt
if [ $? -eq 0 ]; then
    myLog 2 "src_table_num got success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
    myLog 4 " Please check login information or You have an error in your SQL syntax " | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
fi

mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip -N -e "$Sql"  >  $check_dir/dest_0.txt
if [ $? -eq 0 ]; then
  myLog 2 "dest_table_num got success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 " Please check login information or You have an error in your SQL syntax" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
fi

sort -r $check_dir/src_0.txt -o $check_dir/src.txt && myLog 2 "源端表
总数量："`cat $check_dir/src.txt | wc -l` | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
rm -rf $check_dir/src_0.txt
sort -r $check_dir/dest_0.txt -o $check_dir/dest.txt && myLog 2 "目标
端表总数量："`cat $check_dir/dest.txt | wc -l` | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
rm -rf $check_dir/dest_0.txt

diff -q $check_dir/src.txt $check_dir/dest.txt
if [ $? -eq 0 ]; then
    myLog 2 "Tables_name&num check success&passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
    myLog 4 "Tables_name||num check failed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
    diff $check_dir/src.txt $check_dir/dest.txt | tee $check_dir/$src_ip.log
    echo "具体差异请看$check_dir/$src_ip.log 文件"
fi


