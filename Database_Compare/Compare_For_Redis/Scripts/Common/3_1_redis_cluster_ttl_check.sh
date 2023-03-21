#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: redis keys ttl check
# Version: V1.1
# Update: 2023-3-7


# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $(dirname $CURRENT_DIR))/Scripts/Common/0_0_Common_Format.sh
myDos_unix "$(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}"
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}


workdir=$(dirname $(dirname $CURRENT_DIR))/Workspace/${task_config}
resultdir=$workdir/result
log_file=$workdir/`echo $0 | grep -o -E '.*\.'`log
#echo $log_file
redis_cmd_0="cluster nodes"
#slot_num=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep master | wc -l`
slot_num=3

function tips(){
  echo -e "\033[34m -------------------------------------------------- \033[0m" #blue
  echo -e "\033[36m ------------------ CompareRedisTTL ------------------ \033[0m" #sky blue
  echo -e "\033[34m -------------------------------------------------- \033[0m"
  echo -e "\033[32m - [1] Init conf \033[0m"                                  #green
  echo -e "\033[34m - [2] Exec compare \033[0m"
  echo -e "\033[36m - [3] Init conf && exec compare \033[0m"
  echo -e "\033[34m -------------------------------------------------- \033[0m"
}


function init_redisttlcompare_conf()
{
    for i in `seq $slot_num`;
    do
      if [ ! -d s${i} ];then
        mkdir -p  $workdir/s$i/
      fi
      cp -r $workdir/s/* $workdir/s$i/
      if [ $? -eq 0 ];then
        echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] slot$i workdir ready" | tee -a $log_file
      else
        echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] create slot$i workdir failed" | tee -a $log_file
      fi
    done

    for i in `seq $slot_num`;
    do
        source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}
        src_redis_ip=`eval echo '$'{"src${i}_redis_ip"}`
        src_redis_port=`eval echo '$'{"src${i}_redis_port"}`
        src_redis_passwd=`eval echo '$'{"src${i}_redis_passwd"}`

        dest_redis_ip=`eval echo '$'{"dest${i}_redis_ip"}`
        dest_redis_port=`eval echo '$'{"dest${i}_redis_port"}`
        dest_redis_passwd=`eval echo '$'{"dest${i}_redis_passwd"}`

        sed -i "s/src_redis_ip=1.1.1.1/src_redis_ip="${src_redis_ip}"/g" $workdir/s${i}/redis_ttl_check.sh
        sed -i "s/src_redis_port=6666/src_redis_port="${src_redis_port}"/g" $workdir/s${i}/redis_ttl_check.sh
        sed -i "s/src_redis_passwd=/src_redis_passwd="${src_redis_passwd}"/g" $workdir/s${i}/redis_ttl_check.sh

        sed -i "s/dest_redis_ip=2.2.2.2/dest_redis_ip=${dest_redis_ip}/g" $workdir/s${i}/redis_ttl_check.sh
        sed -i "s/dest_redis_port=7777/dest_redis_port=${dest_redis_port}/g" $workdir/s${i}/redis_ttl_check.sh
        sed -i "s/dest_redis_passwd=/dest_redis_passwd=${dest_redis_passwd}/g" $workdir/s${i}/redis_ttl_check.sh
    done

    if [ $? -ne 0 ];then
       echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] exec programs conf init failed" | tee -a $log_file && exit
    else
       echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] exec programs conf init success" | tee -a $log_file
    fi
}

function execttl(){
    echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] s$i keys collect start..." | tee -a $log_file && cd $workdir/s${i} && bash $workdir/s${i}/redis_ttl_check.sh
}

function redis_ttl_compare()
{
    if [ ! -d $resultdir ];then
      mkdir -p $workdir/result
    fi
    process=$slot_num
    if [ ! -d $workdir/tmp ];then
      mkdir -p $workdir/tmp
    fi
    tmp_fifofile=$workdir/tmp/$$.tmp_fifofile
    mkfifo $tmp_fifofile
    exec 666<>$tmp_fifofile
    rm $tmp_fifofile
    for i in $(seq ${process}) #往文件中添加i个空行
    do
      echo >& 666
    done
    for i in `seq $slot_num`;
    do
      {
      read -u 666
        {
         #echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] s$i keys collect start..." | tee -a $log_file && cd $workdir/s${i} && bash $workdir/s${i}/redis_ttl_check.sh
        execttl &
        }
      }
    done
    wait
    exec 666>&-                 # 释放
    exec 666<&-
    echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] slot keys collect ended..." | tee -a $log_file

    src_cluster_ttlkey=""
    dest_cluster_ttlkey=""
    src_cluster_ttl_pick=""
    dest_cluster_ttl_pick=""
    for i in `seq $slot_num`;
    do
      {
      src_cluster_ttlkey="${src_cluster_ttlkey} $workdir/s${i}/src_ttlkey.log"
      dest_cluster_ttlkey="${dest_cluster_ttlkey} $workdir/s${i}/dest_ttlkey.log"
      src_cluster_ttl_pick="${src_cluster_ttl_pick} $workdir/s${i}/src_ttl_pick.log"
      dest_cluster_ttl_pick="${dest_cluster_ttl_pick} $workdir/s${i}/dest_ttl_pick.log"
      }
    done

    if [ $? -eq 0 ];then
      cat $src_cluster_ttlkey > $resultdir/src_cluster_ttlkey.log && sort -r $resultdir/src_cluster_ttlkey.log -o $resultdir/src_cluster_ttlkey_new.log && rm -rf $resultdir/src_cluster_ttlkey.log
      cat $dest_cluster_ttlkey > $resultdir/dest_cluster_ttlkey.log
      sort -r $resultdir/dest_cluster_ttlkey.log -o $resultdir/dest_cluster_ttlkey_new.log
      rm -rf $resultdir/dest_cluster_ttlkey.log
      cat $src_cluster_ttl_pick > $resultdir/src_cluster_ttl_pick.log
      sort -r $resultdir/src_cluster_ttl_pick.log -o $resultdir/src_cluster_ttl_pick_new.log
      rm -rf $resultdir/src_cluster_ttl_pick.log
      cat $dest_cluster_ttl_pick > $resultdir/dest_cluster_ttl_pick.log
      sort -r $resultdir/dest_cluster_ttl_pick.log -o $resultdir/dest_cluster_ttl_pick_new.log
      rm -rf $resultdir/dest_cluster_ttl_pick.log
    fi
    #compare
    diff $resultdir/src_cluster_ttlkey_new.log $resultdir/dest_cluster_ttlkey_new.log > $workdir/diffout
    if [ $? -eq 0 ];then
      echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires times are same" | tee -a $log_file
    else
      echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys expires times are not same" | tee -a $log_file
      echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review src&dest_ttl.log" | tee -a $log_file
    fi
}


tips

read -p "init conf or exec main compare [1|2|3] :" act
case $act in
1)
  init_redisttlcompare_conf
  ;;
2)
  redis_ttl_compare
  ;;
3)
  init_redisttlcompare_conf && redis_ttl_compare
  ;;
esac