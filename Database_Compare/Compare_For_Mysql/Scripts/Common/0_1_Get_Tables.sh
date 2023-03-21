#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Get tables for mysql
# Version: V1.1
# Update: 2023-2-23


# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}

#生成待校验的遍历表名

#文件输出位置
file_out_dir=$task_out_dir
if [ ! -d $file_out_dir ];then
  mkdir -p $file_out_dir
fi
db_list_file=$db_list
db_list_file_new=$db_list_file.new
db_file_dir=$file_out_dir/dblist
exclude_db_list=$exclude_file
myDos_unix $exclude_db_list

#源端
db_user=$src_username
db_passwd=$src_password
db_port=$src_port
db_ip=$src_ip
#echo "file_out_dir:"$file_out_dir,"db_list_file:"$db_list_file,"db_file_dir:"$db_file_dir
#echo $db_user $db_passwd $db_port $db_ip
#echo $exclude_db_list

#验证源数据库连接信息
mysql -u$db_user -p$db_passwd -P$db_port -h$db_ip  -N -e "show databases;" 2>/dev/null
if [ $? -eq 0 ];then
        myecho 1 "`date +%F_%T_`源端数据库登陆验证成功" && myLog 2 "源端数据库登陆验证成功" >>$(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
        myecho 3 "`date +%F_%T_`源端数据库登陆验证失败，请确认数据库连接信息" && myLog 4 "源端数据库登陆验证失败，请确认数据库连接信息" >>$(dirname $(dirname $CURRENT_DIR))/Logs/error.log
        exit
fi

#生产库信息文件，排除系统库
if [ ! -d $db_file_dir ];then
    mkdir -p $db_file_dir
fi
mysql -u$db_user -p$db_passwd -P$db_port -h$db_ip  -N -e "show databases;" > ${file_out_dir}/${db_list_file}
myExclude ${exclude_db_list} ${file_out_dir}/$db_list_file

#分布式实例去掉下面注释
#sed -i  '/^xa$/d' ${db_file_dir}/$db_ip_file.txt

#以库名为文件名遍历生成表文件名目录
if [ ! -d $db_file_dir ];then
    mkdir -p $db_file_dir
else
    rm -rf $db_file_dir/*.txt
fi
for i in `cat ${file_out_dir}/${db_list_file_new}`;
do
{
    mysql -u$db_user -p$db_passwd -P$db_port -h$db_ip -N -e  " use $i;SHOW tables" > ${db_file_dir}/$i.txt
    myLog 2 " $i : `cat ${db_file_dir}/$i.txt | wc -l`" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
}
done

#校验数据库对象review
for db_database in `cat $file_out_dir/${db_list_file_new}`;
do
{
        #源端表信息
        if [ ! -d $file_out_dir/tbreview ];then
            mkdir -p $file_out_dir/tbreview
        else
            rm -rf $file_out_dir/tbreview/yuan_${db_database}.txt
        fi
        mysql -u$db_user -p$db_passwd -P$db_port -h$db_ip -D$db_database  -N -e "show tables;" > $file_out_dir/tbreview/yuan_${db_database}.txt
        diff $file_out_dir/tbreview/yuan_${db_database}.txt  $db_file_dir/${db_database}.txt
        if [ $? -eq 0 ]; then
                myLog 2 " tablenames in $db_database got and check success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
        else
                myLog 4 " Please check login information or You have an error in your SQL syntax and tablenames in $db_database check failed " |tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit 1
fi
};
done