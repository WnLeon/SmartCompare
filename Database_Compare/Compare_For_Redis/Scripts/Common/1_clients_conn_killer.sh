#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: redis clients killer
# Version: V1.1
# Update: 2023-3-7

# redis4.0
src_redis_ip=127.0.0.1
src_redis_port=6379
src_redis_passwd=
redis_cmd="client list"
log_file=`echo $0 | grep -o -E '.*\.'`log
#echo $log_file

redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd >redis-clients-0.list
cat redis-clients-0.list | awk -F ' ' '{print $1}' | sed -e 's/addr=//g' | sed -e '$d' >redis-clients.list
clinum=`cat redis-clients.list |wc -l`

if [ $clinum -ne 0 ];then
   for i in `cat redis-clients.list`
   do
     echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] killing $i" | tee -a $log_file
     redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw client kill $i >/dev/null
     if [ $? -eq 0 ];then
       echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] $i has been killed" | tee -a $log_file
     else
       echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] kill $i failed" | tee -a $log_file
     fi
   done
   echo "---Leave clients---" | tee -a $log_file
   redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd | awk -F ' ' '{print $1}' | tee -a $log_file
   echo "-------------------" | tee -a $log_file
else
   echo  "`date '+%Y-%m-%d %H:%M:%S'` [INFO] zero conn" | tee -a $log_file && exit
fi

if [ $? -eq 0 ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [SUCCESS] clients killed success"| tee -a $log_file
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [FAILED] please check scripts"| tee -a $log_file
fi