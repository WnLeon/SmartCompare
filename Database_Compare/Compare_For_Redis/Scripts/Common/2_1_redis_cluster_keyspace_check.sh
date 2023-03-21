#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: cluster redis keyspace info
# Version: V1.1
# Update: 2023-3-7


src_redis_ip=(127.0.0.1 )
src_redis_port=6379
src_redis_passwd=

dest_redis_ip=(127.0.0.1 )
dest_redis_port=6379
dest_redis_passwd=

redis_cmd_0="cluster nodes"
redis_cmd_1="redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep myself | awk -F ' ' '{print $1}'"
redis_cmd_2="INFO Keyspace"


log_file=`echo $0 | grep -o -E '.*\.'`log
#echo $log_file

slot_num=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep master | wc -l`
slot_master_id=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep master | awk -F ' ' '{print $1}'`
arr_slot_master_id=(${slot_master_id//' '/})
current_slot_id=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep myself | awk -F ' ' '{print $1}'`
#echo $slot_master_id
#echo $current_slot_id

for i in $src_redis_ip;
do
  echo "Current node: $i"
  redis-cli -h $i -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_2 >> src-redis-keyspace-0.list
done

for j in $dest_redis_ip;
do
  echo "Current node: $j"
  redis-cli -h $j -p $dest_redis_port -a $dest_redis_passwd --raw $redis_cmd_2 >> dest-redis-keyspace-0.list
done

src_keys=0
for i in `cat src-redis-keyspace-0.list | awk -F ' ' '{print $1}' | grep -o -E "keys=[0-9]*" | sed -e "s/keys=//g"`;
do
  let src_keys=$src_keys+$i
done
echo "src_keys: $src_keys"

dest_keys=0
for i in `cat dest-redis-keyspace-0.list | awk -F ' ' '{print $1}' | grep -o -E "keys=[0-9]*" | sed -e "s/keys=//g"`;
do
  let dest_keys=$dest_keys+$i
done
echo "dest_keys: $dest_keys"

src_ex_keys=0
for i in `cat src-redis-keyspace-0.list | awk -F ' ' '{print $2}' | sed -e "s/expires=//g"`;
do
  let src_ex_keys=$src_ex_keys+$i
done
echo "src_ex_keys: $src_ex_keys"

dest_ex_keys=0
for i in `cat dest-redis-keyspace-0.list | awk -F ' ' '{print $2}' | sed -e "s/expires=//g"`;
do
  let dest_ex_keys=$dest_ex_keys+$i
done
echo "dest_ex_keys: $dest_ex_keys"

if [ $src_keys -ne $dest_keys ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys number are not same" | tee -a $log_file && exit
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys number are same" | tee -a $log_file
  if [ $src_ex_keys -ne $dest_ex_keys ];then
    echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest ex keys number are not same" | tee -a $log_file && exit
  else
    echo "`date '+%Y-%m-%d %H:%M:%S'` [SUCCESS] src & dest keys number are same" | tee -a $log_file
  fi
fi



<<!
redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd >src-redis-keyspace-0.list & PIDIOS=$!
redis-cli -h $dest_redis_ip -p $dest_redis_port -a $dest_redis_passwd --raw $redis_cmd >dest-redis-keyspace-0.list
wait $PIDIOS

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

!