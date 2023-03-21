#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Start
# Version: V1.1
# Update: 2023-2-23

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
#task_config=$1
task_config=DemoTask
source $(dirname $CURRENT_DIR)/Scripts/Common/0_0_Common_Format.sh
source $(dirname $CURRENT_DIR)/Conf/${task_config}/${task_config}


# 运行日志目录检测
if [ -f "$(dirname $CURRENT_DIR)/Logs/info.log" ];then
  echo  "$(date '+%Y-%m-%d %H:%M:%S') SmartCompare started" >> $(dirname $CURRENT_DIR)/Logs/info.log
else
  echo "############SmartCompare_info.log#############\r$(date '+%Y-%m-%d %H:%M:%S') SmartCompare started" > $(dirname $CURRENT_DIR)/Logs/info.log
fi

if [ -f "$(dirname $CURRENT_DIR)/Logs/error.log" ];then
  echo  "$(date '+%Y-%m-%d %H:%M:%S') logs doc check ok" >> $(dirname $CURRENT_DIR)/Logs/info.log
else
  echo "############SmartCompare_error.log#############
  " >  $(dirname $CURRENT_DIR)/Logs/error.log
fi
# Common函数引用检测
myecho 1 "This is a test!!!" >/dev/null
if [ $? -eq 0 ];then
    echo "`date '+%Y-%m-%d %H:%M:%S'` CommonFunction induct success" | tee -a $(dirname $CURRENT_DIR)/Logs/info.log
  else
    echo "`date '+%Y-%m-%d %H:%M:%S'` CommonFunction induct failed!!!" | tee -a  $(dirname $CURRENT_DIR)/Logs/error.log
fi

#myLog 1 "This is a test!!!" | tee -a  $(dirname $CURRENT_DIR)/Logs/info.log

# 工作目录检测
if [ -d "$(dirname $CURRENT_DIR)/Workspace/$task_config" ];then
  echo  "$(date '+%Y-%m-%d %H:%M:%S') WorkspaceDoc $task_config exist " >> $(dirname $CURRENT_DIR)/Logs/info.log
else
  mkdir -p $(dirname $CURRENT_DIR)/Workspace/$task_config
  echo "$(date '+%Y-%m-%d %H:%M:%S') WorkspaceDoc $task_config created " > $(dirname $CURRENT_DIR)/Logs/info.log
fi


let P1=`mysql -u$src_username -p$src_password -P$src_port -h$src_ip  -N -e "show variables like '%group_concat_max_len%';"`
if [ $P1 -lt 1024000000 ];then
  myLog 3 "Please check src db variable 'group_concat_max_len' and make sure it >= 1024000000" | tee -a $(dirname $CURRENT_DIR)/Logs/info.log
else
  myLog 2 "src db variable 'group_concat_max_len' is $P1" | tee -a $(dirname $CURRENT_DIR)/Logs/info.log
fi
# 程序执行入口
myecho 1 "SmartCompare_For_Mysql"
myecho 2 "SmartCompare_For_Mysql"
myecho 3 "SmartCompare_For_Mysql"
myecho 1 "
######################·INFO·######################\n
a|all)\t\t         all_modules compare\n
p|parameters)\t    1_para compare\n
u|users)\t         2_user compare\n
f|functions)\t     3_func compare\n
n|tbnm)\t          4_num compare\n
d|ddl)\t\t         5_ddl compare\n
da|data)\t         6_data compare\n
dp|dump)\t         6_1_data compare\n
*)\t\t             Default_exec_table_data compare\n
###################################################
" | column -c 5
read -p "Please choose module what kind of check:" module

case "$module" in
  a|all)
  myecho 1 "all modules compare start" && myLog 2 "all modules compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/1_Parameters_Compare.sh $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/"2_Users&Priv_Compare.sh" $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/"3_Procedures&Functions&Triggers_Compare.sh" $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/"4_Tables_Name&Number_Compare.sh" $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/5_Tables_DDL_Compare.sh $task_config
  bash $(dirname $CURRENT_DIR)/Scripts/Common/6_Tables_Data_Compare.sh $task_config
  ;;
  p|parameters)
  myecho 1 "1_para compare start" && myLog 2 "1_para compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/1_Parameters_Compare.sh $task_config
  ;;
  u|users)
  myecho 1 "2_user compare start" && myLog 2 "2_user compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/"2_Users&Priv_Compare.sh" $task_config
  ;;
  f|functions)
  myecho 1 "3_func compare start" && myLog 2 "3_func compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/"3_Procedures&Functions&Triggers_Compare.sh" $task_config
  ;;
  n|tbnm)
  myecho 1 "4_num compare start" && myLog 2 "4_num compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/"4_Tables_Name&Number_Compare.sh" $task_config
  ;;
  d|ddl)
  myecho 1 "5_ddl compare start" && myLog 2 "5_ddl compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/5_Tables_DDL_Compare.sh $task_config
  ;;
  da|data)
  myecho 1 "6_data compare start" && myLog 2 "6_data compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/6_Tables_Data_Compare.sh $task_config
  ;;
  dp|dump)
  myecho 1 "6_1_data compare start" && myLog 2 "6_1_data compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/6_1_Tables_Data_Dump_Compare.sh $task_config
  ;;
  *)
  myecho 3 "Default exec table data compare" && myLog 3 "Default exec table data compare" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Get_Tables.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/6_1_Tables_Data_Compare.sh $task_config
  ;;
esac
