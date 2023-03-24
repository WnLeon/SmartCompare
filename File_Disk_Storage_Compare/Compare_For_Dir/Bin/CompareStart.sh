#!/bin/bash
# Date: 2023-3-2
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Start
# Version: V1.1
# Update: 2023-3-3

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


# 程序执行入口
myecho 1 "SmartCompare_For_Dir"
myecho 2 "SmartCompare_For_Dir"
myecho 3 "SmartCompare_For_Dir"
myecho 1 "
######################·INFO·######################\n
a|all)\t\t         all_modules compare\n
*)\t\t             Default_exec_dir_data compare\n
###################################################
" | column -c 5
read -p "Please choose module what kind of check:" module

case "$module" in
  a|all)
  myecho 1 "all modules compare start" && myLog 2 "all modules compare start" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Ssh_Check.sh $task_config
  if [ $? -eq 0 ];then
    bash $(dirname $CURRENT_DIR)/Scripts/Common/1_1_File_Data_Compare.sh $task_config
  fi
  ;;
  *)
  myecho 3 "Default exec table data compare" && myLog 3 "Default exec table data compare" >> $(dirname $CURRENT_DIR)/Logs/info.log
  bash $(dirname $CURRENT_DIR)/Scripts/Common/0_1_Ssh_Check.sh $task_config && bash $(dirname $CURRENT_DIR)/Scripts/Common/1_File_Data_Compare.sh $task_config
  ;;
esac
