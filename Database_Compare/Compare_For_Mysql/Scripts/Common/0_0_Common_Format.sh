#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Common Shell Functions
# Version: V1.1
# Update: 2023-2-23


# Function0
# 这是一个Demo
function myDemo(){
  pass
}
#e.g
#################################################################
# Function1
# 文件fileformat 由 dos 转 unix
function myDos_unix(){
  if [ -w $1 ];then
    sed -i 's/\r$//g' $1
  fi
}
#e.g myDos_unix "${exclude_db_list}"
################################################################
# Function2
# 格式化log日志
function myLog(){
  #日志级别 debug-1, info-2, warn-3, error-4, always-5
  LOG_LEVEL=$1
  case $LOG_LEVEL in
      1)#debug
      content="$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $2"
      ;;
      2)#info
      content="$(date '+%Y-%m-%d %H:%M:%S') [INFO] $2"
      ;;
      3)#warn
      content="$(date '+%Y-%m-%d %H:%M:%S') [WARN] $2"
      ;;
      4)#error
      content="$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $2"
      ;;
      5)#always
       content="$(date '+%Y-%m-%d %H:%M:%S') [ALWAYS] $2"
      ;;
      *)
       content="$(date '+%Y-%m-%d %H:%M:%S') [ALWAYS] $2"
      ;;
  esac
  echo ${content}
}
#e.g myLog 1 "This is a test"
#################################################################
# Function3
# 标准化排除对象
function myExclude(){
  exclude_objs_list=$1
  myDos_unix $exclude_objs_list
  myDos_unix $2
  grep -vxf $exclude_objs_list $2 > $2.new
  myDos_unix $2.new
	#系统库
  #sed -i  '/^sys$/d' ${file_out_dir}/$db_list_file
  #sed -i  '/^sysdb$/d' ${file_out_dir}/$db_list_file
  #sed -i  '/^mysql$/d' ${file_out_dir}/$db_list_file
  #sed -i  '/^information_schema$/d' ${file_out_dir}/$db_list_file
  #sed -i  '/^performance_schema$/d' ${file_out_dir}/$db_list_file
  #新环境不需要校验的库
  #sed -i  '/^tars_stat$/d' ${file_out_dir}/$db_list_file
  #sed -i  '/^tars_property$/d' ${file_out_dir}/$db_list_file
}
#e.g myExclude "${exclude_db_list}" "${file_out_dir}/$db_list_file"
#################################################################
# Function4
# 格式化输出echo
function myecho(){
<<!
1 正确输出 绿色
#2 警告输出 黄色
#3 错误输出 红色
!
  if [ $# -ge 2 ];then
     params_num=$1
     shift 1
     params_mes=$@
  else
    echo $1
    exit
  fi
  case $params_num in
        1)#绿
        echo -e "\033[32;40;1m${params_mes}\033[0m\r"
        ;;
        2)#黄
        echo -e "\033[33;40;1m${params_mes} \033[0m\r"
        ;;
        3)#红
        echo -e "\033[31;40;1m${params_mes}\033[0m\r"
        ;;
        *)
        echo -e ${params_mes}
        ;;
   esac
}
#e.g myecho 1 "goodboy"
#################################################################

