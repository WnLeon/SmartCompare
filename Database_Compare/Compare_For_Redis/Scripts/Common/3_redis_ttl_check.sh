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

dest_redis_ip=2.2.2.2
dest_redis_port=7777
dest_redis_passwd=

cursor=0             # 第一次游标
cnt=10000              # 每次迭代的数量
new_cursor=0         # 下一次游标


slotnum=`pwd | awk -F '/' '{print $NF}'`

log_file=`echo $0 | grep -o -E '.*\.'`log
#echo $log_file

rm -f scan_tmp_result
rm -f scan_result
rm -rf src_ttl.log
rm -rf dest_ttl.log
rm -rf dest_ttlkey.log
rm -rf src_ttlkey.log

echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] ${slotnum}/src & dest keys scan start" | tee -a $log_file

redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw scan $cursor count $cnt > scan_tmp_result
new_cursor=`sed -n '1p' scan_tmp_result`
sed -n '2,$p' scan_tmp_result > scan_result
cat scan_result | while read line
do
    src_ttl_result=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw ttl $line `
    dest_ttl_result=`redis-cli -h $dest_redis_ip -p $dest_redis_port -a $dest_redis_passwd --raw ttl $line `
    if [[ $src_ttl_result != -1 ]] && [[ $src_ttl_result != -2 ]];then
        echo $line | tee -a src_ttlkey.log
        echo $src_ttl_result >>src_ttl.log
    fi

    if [[ $dest_ttl_result != -1 ]] && [[ $dest_ttl_result != -2 ]];then                  # 判断过期时间，-1 是不过期
        echo $line >> dest_ttlkey.log
        echo $dest_ttl_result >>dest_ttl.log                 # 追加到指定文件
    fi
done

while [ $cursor -ne $new_cursor ]    # 若 游标 不为 0 ，则证明没有迭代完所有的 key，继续执行
do
    redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw scan $new_cursor count $cnt 2>/dev/null> scan_tmp_result
    new_cursor=`sed -n '1p' scan_tmp_result`
    sed -n '2,$p' scan_tmp_result > scan_result
    cat scan_result |while read line
    do
      src_ttl_result=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw ttl $line`
      dest_ttl_result=`redis-cli -h $dest_redis_ip -p $dest_redis_port -a $dest_redis_passwd --raw ttl $line`
      if [[ $src_ttl_result != -1 ]] && [[ $src_ttl_result != -2 ]];then
          echo $line | tee -a src_ttlkey.log
          echo $src_ttl_result >>src_ttl.log
      fi
      if [[ $dest_ttl_result != -1 ]] && [[ $dest_ttl_result != -2 ]];then                  # 判断过期时间，-1 是不过期
          echo $line >> dest_ttlkey.log
          echo $dest_ttl_result >>dest_ttl.log                                     # 追加到指定文件
      fi
    done
    sleep 0.1
done

awk 'NR==FNR{a[i]=$0;i++}NR>FNR{print a[j]" "$0;j++}'  src_ttlkey.log src_ttl.log > src_ttl_pick.log
awk 'NR==FNR{a[i]=$0;i++}NR>FNR{print a[j]" "$0;j++}'  dest_ttlkey.log dest_ttl.log > dest_ttl_pick.log

rm -rf scan_tmp_result
rm -rf scan_result
rm -rf src_ttl.log
rm -rf dest_ttl.log

#diff src_ttlkey.log dest_ttlkey.log >diffout
if [ $? -eq 0 ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] ${slotnum}/src & dest keys expires ready" | tee -a $log_file && exit
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] ${slotnum}/src & dest keys expires times are not ready" | tee -a $log_file && exit
  echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review ${slotnum}/src&dest_ttlkey.log" | tee -a $log_file && exit
fi

<<!
if [ $? -eq 0 ];then
  echo "`date '+%Y-%m-%d %H:%M:%S'` [SUCCESS]  killed success"| tee -a $log_file
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` [FAILED] please check scripts"| tee -a $log_file
fi
!