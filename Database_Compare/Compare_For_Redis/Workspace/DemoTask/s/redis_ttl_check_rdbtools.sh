#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: redis keys ttl check
# Version: V1.1
# Update: 2023-3-7


src_redis_ip=1.1.1.1
src_redis_port=6666
src_redis_passwd=

#dest_redis_ip=2.2.2.2
#dest_redis_port=7777
#dest_redis_passwd=

slotnum=`pwd | awk -F '/' '{print $NF}'`

log_file=`echo $0 | grep -o -E '.*\.'`log
#echo $log_file

rm -rf src_ttl_pick.csv
#rm -rf dest_ttl_pick.csv
rm -rf src_ttl_pick_0.rdb
#rm -rf dest_ttl_pick_0.rdb

#/opt/bin/redis-dump -m $src_redis_passwd@$src_redis_ip:$src_redis_port -o src_ttl_pick_0.rdb & PIDS=$!
#/opt/bin/redis-dump -m $dest_redis_passwd@$dest_redis_ip:$dest_redis_port -o dest_ttl_pick_0.rdb & PIDD=$!
#wait $PIDS
#wait $PIDD


rdb -c memory src_ttl_pick_0.rdb -f src_ttl_pick_0.csv
rdb -c memory dest_ttl_pick_0.rdb -f dest_ttl_pick_0.csv

echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] ${slotnum}/src & dest keys parse start" | tee -a $log_file

sed -i "1d" src_ttl_pick_0.csv && awk -F ',' '{print$3,$8}' src_ttl_pick_0.csv >src_ttl_pick.csv
sed -i "1d" dest_ttl_pick_0.csv && awk -F ',' '{print$3,$8}' dest_ttl_pick_0.csv >dest_ttl_pick.csv

rm -rf src_ttl_pick_0.csv
rm -rf dest_ttl_pick_0.csv

if [ $? -eq 0 ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] ${slotnum}/src & dest keys parse success" | tee -a $log_file && exit
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] ${slotnum}/src & dest keys expires times parse failed" | tee -a $log_file && exit
  echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review ${slotnum}/src&dest.csv" | tee -a $log_file && exit
fi
