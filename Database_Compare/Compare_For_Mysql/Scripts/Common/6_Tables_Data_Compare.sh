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
file_out_dir=$task_out_dir/"6_Tables_Data_Compare"
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


#数据校验
#循环库名
for db_database in `cat $task_out_dir/${db_list_file}.new`;
do
{
        #设置校验表
        for table_name in `cat $task_out_dir/dblist/${db_database}.txt`;
        do
        {
        #唯一键所在列名
        unique_column=`mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "select COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='$db_database' and TABLE_NAME ='$table_name' and COLUMN_KEY='PRI';" |sed  's/,/\`,\`/g' | sed 's/^/\`&/g' | sed 's/$/&\`/g' 2>/dev/null`
        if [ -z "$unique_column" ]; then
            myLog 4 "${table_name} unique_columnw为空" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
            myLog 4 "${table_name} unique_columnw为空" >> $file_out_dir/error.log
            continue
        fi
        myLog 2 "$table_name $unique_column"
        #获取需要校验的列名
        col_list=`mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "select group_concat(COLUMN_NAME) from information_schema.COLUMNS where TABLE_SCHEMA='$db_database' and TABLE_NAME ='$table_name' and EXTRA != 'auto_increment';" |sed  's/,/\`,\`/g' | sed 's/^/\`&/g' | sed 's/$/&\`/g'  2>/dev/null`
        if [ $? -ne 0 ]; then
          myLog 4 "$db_database.$table_name col_list Please Check If You have an error in your SQL syntax" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
        fi
        #将目标端需要对比的数据生成md5值
        rm -rf $file_out_dir/${db_database}_${table_name}
        mkdir -p $file_out_dir/${db_database}_${table_name}
        mysql -u$dest_username -p$dest_password -P$dest_port -h$dest_ip -D$db_database  -N -e "select $unique_column,md5(concat_ws(',',$col_list,',')) from $db_database.$table_name order by $unique_column;" >$file_out_dir/${db_database}_${table_name}/dest
        if [ $? -ne 0 ]; then
          myLog 4 "$db_database.$table_name dest md5 Please Check If You have an error in your SQL syntax" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
        fi
        sort -r $file_out_dir/${db_database}_${table_name}/dest -o $file_out_dir/${db_database}_${table_name}/dest_2
        rm -rf $file_out_dir/${db_database}_${table_name}/dest
        #将源端需要对比的数据生成md5值
        #for i in `seq 1 16`;do
        mysql -u$src_username -p$src_password -P$src_port -h$src_ip -D$db_database  -N -e "select $unique_column,md5(concat_ws(',',$col_list,',')) from $db_database.$table_name group by $unique_column;" >>$file_out_dir/${db_database}_${table_name}/sorc;
        if [ $? -ne 0 ]; then
          myLog 4 "$db_database.$table_name src md5 Please Check If You have an error in your SQL syntax" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
        fi
        #done;
        sort -r $file_out_dir/${db_database}_${table_name}/sorc -o $file_out_dir/${db_database}_${table_name}/sorc_2
        rm -rf $file_out_dir/${db_database}_${table_name}/sorc
        diff -q $file_out_dir/${db_database}_${table_name}/sorc_2 $file_out_dir/${db_database}_${table_name}/dest_2
        if [ $? -eq 0 ]; then
          myLog 2 "${db_database}_${table_name} data check passed"
        else
          myLog 4 "${db_database}_${table_name} data check failed" >> $file_out_dir/error.log
          #diff $file_out_dir/${db_database}_${table_name}/sorc_2  $file_out_dir/${db_database}_${table_name}/dest_2 > $file_out_dir/${db_database}_${table_name}/check_diff_date
          #myLog 4 "具体不同请看$file_out_dir/${db_database}_${table_name}/check_diff_date 文件" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
        fi
        };
        done;
};
done;
cat $file_out_dir/error.log | grep failed > /dev/null
if [ $? -eq 0 ];then
  myecho 3 "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] check failed table info: Please review $file_out_dir/error.log" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
else
  myecho 2 "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Data check passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
fi

