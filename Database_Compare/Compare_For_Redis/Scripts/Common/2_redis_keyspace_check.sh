#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: redis keyspace info
# Version: V1.1
# Update: 2023-3-7


src_redis_ip=127.0.0.1
src_redis_port=6379
src_redis_passwd=

dest_redis_ip=127.0.0.1
dest_redis_port=6379
dest_redis_passwd=

redis_cmd="INFO Keyspace"

log_file=`echo $0 | grep -o -E '.*\.'`log
#echo $log_file

redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd >src-redis-keyspace-0.list & PIDIOS=$!
redis-cli -h $dest_redis_ip -p $dest_redis_port -a $dest_redis_passwd --raw $redis_cmd >dest-redis-keyspace-0.list
wait $PIDIOS
<<!
src_keynum=`cat src-redis-keyspace-0.list |grep -o -E "keys=[0-9]*,"` | grep -o -E "[0-9]*"
src_ex_keynum=`cat src-redis-keyspace-0.list |grep -o -E "expires=[0-9]*,"` | grep -o -E "[0-9]*"
dest_keynum=`cat dest-redis-keyspace-0.list |grep -o -E "keys=[0-9]*,"`| grep -o -E "[0-9]*"
dest_ex_keynum=`cat dest-redis-keyspace-0.list |grep -o -E "expires=[0-9]*,"`| grep -o -E "[0-9]*"
echo $src_keynum $src_ex_keynum
echo $dest_keynum $dest_ex_keynum
!
cat src-redis-keyspace-0.list | awk -F ',' '{print $1}' > src-redis-keys-num.list
cat src-redis-keyspace-0.list | awk -F ',' '{print $2}' > src-redis-expires-keys-num.list
cat dest-redis-keyspace-0.list | awk -F ',' '{print $1}' > dest-redis-keys-num.list
cat dest-redis-keyspace-0.list | awk -F ',' '{print $2}' > dest-redis-expires-keys-num.list

# keysnum

if [ $? -eq 0 ];then
  diff src-redis-keys-num.list dest-redis-keys-num.list > diffout-keysnum
  if [ $? -eq 0 ];then
       echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys number are same" | tee -a $log_file
       diff src-redis-expires-keys-num.list dest-redis-expires-keys-num.list > diffout-exkeysnum
       if [ $? -eq 0 ];then
         echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires number are same" | tee -a $log_file
       else
         echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires number are not same" | tee -a $log_file && exit 1
       fi
  else
     echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys number are not same" | tee -a $log_file && exit 1
  fi
else
  echo  "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] keys number & expire keys got wrong" | tee -a $log_file && exit 1
fi

<<!
if [ $? -eq 0 ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [SUCCESS]  killed success"| tee -a $log_file
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [FAILED] please check scripts"| tee -a $log_file
fi
!