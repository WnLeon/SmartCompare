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
#myDos_unix "$(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}"
#source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}


workdir=$(dirname $(dirname $CURRENT_DIR))/Workspace/${task_config}
resultdir=$workdir/result
log_file=$workdir/`echo $0 | grep -o -E '.*\.'`log
#echo $log_file
redis_cmd_0="cluster nodes"
#slot_num=`redis-cli -h $src_redis_ip -p $src_redis_port -a $src_redis_passwd --raw $redis_cmd_0 | grep master | wc -l`
slot_num=$2

function tips()
{
  echo -e "\033[34m -------------------------------------------------- \033[0m" #blue
  echo -e "\033[36m ------------------ CompareRedisTTL ------------------ \033[0m" #sky blue
  echo -e "\033[34m -------------------------------------------------- \033[0m"
  echo -e "\033[32m - [1] Init conf \033[0m"                                  #green
  echo -e "\033[34m - [2] Exec compare \033[0m"
  echo -e "\033[36m - [3] Init conf && exec compare \033[0m"
  echo -e "\033[36m - [4] Quick Init conf  \033[0m"
  echo -e "\033[36m - [5] Init conf && Quick exec compare \033[0m"
  echo -e "\033[34m -------------------------------------------------- \033[0m"
}

function tips2()
{
  echo -e "\033[34m -------------------------------------------------- \033[0m" #blue
  echo -e "\033[36m ------------------ CompareRedisTTL ------------------ \033[0m" #sky blue
  echo -e "\033[34m -------------------------------------------------- \033[0m"
  echo -e "\033[32m - [1] rdbtools parse compare \033[0m"                                  #green
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

        sed -i "s/src_redis_ip=1.1.1.1/src_redis_ip="${src_redis_ip}"/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh
        sed -i "s/src_redis_port=6666/src_redis_port="${src_redis_port}"/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh
        sed -i "s/src_redis_passwd=/src_redis_passwd="${src_redis_passwd}"/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh

        sed -i "s/dest_redis_ip=2.2.2.2/dest_redis_ip=${dest_redis_ip}/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh
        sed -i "s/dest_redis_port=7777/dest_redis_port=${dest_redis_port}/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh
        sed -i "s/dest_redis_passwd=/dest_redis_passwd=${dest_redis_passwd}/g" $workdir/s${i}/redis_ttl_check_rsbtools.sh
    done

    if [ $? -ne 0 ];then
       echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] exec programs conf init failed" | tee -a $log_file && exit
    else
       echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] exec programs conf init success" | tee -a $log_file
    fi
}

function execttl()
{
    echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] s$i keys collect start..." | tee -a $log_file && cd $workdir/s${i} && bash $workdir/s${i}/redis_ttl_check_rsbtools.sh
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

    src_cluster_ttl_pick=""
    dest_cluster_ttl_pick=""
    for i in `seq $slot_num`;
    do
      {
      src_cluster_ttl_pick="${src_cluster_ttl_pick} $workdir/s${i}/src_ttl_pick.csv"
      dest_cluster_ttl_pick="${dest_cluster_ttl_pick} $workdir/s${i}/dest_ttl_pick.csv"
      }
    done

    if [ $? -eq 0 ];then
      touch $resultdir/src_cluster_ttl_pick_new.csv
      cat $src_cluster_ttl_pick > $resultdir/src_cluster_ttl_pick.csv
      sort -r $resultdir/src_cluster_ttl_pick.csv -o $resultdir/src_cluster_ttl_pick_new.csv
      rm -rf $resultdir/src_cluster_ttl_pick.csv

      touch $resultdir/dest_cluster_ttl_pick_new.csv
      cat $dest_cluster_ttl_pick > $resultdir/dest_cluster_ttl_pick.csv
      sort -r $resultdir/dest_cluster_ttl_pick.csv -o $resultdir/dest_cluster_ttl_pick_new.csv
      rm -rf $resultdir/dest_cluster_ttl_pick.csv
    fi
    #compare
    diff $resultdir/src_cluster_ttlkey_new.csv $resultdir/dest_cluster_ttlkey_new.csv > $workdir/diffout
    if [ $? -eq 0 ];then
      echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires times are same" | tee -a $log_file
    else
      echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys expires times are not same" | tee -a $log_file
      echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review src&dest_ttl.log" | tee -a $log_file
    fi
}

function redisttlcompare_rdbtools()
{
  if [ ! -d $workdir ];then
    mkdir -p $workdir
  fi
  if [ ! -f $log_file ];then
    touch $log_file
  fi
  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] workdir check ..." | tee -a $log_file
  if [ ! -d $resultdir ];then
    mkdir -p $resultdir
  fi
  if [ ! -d $workdir/src ];then
    mkdir -p $workdir/src
  fi
  if [ ! -d $workdir/dest ];then
    mkdir -p $workdir/dest
  fi

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] workdir check success ..." | tee -a $log_file

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] rdb file check ..." | tee -a $log_file
  for i in `seq $slot_num`
  do
    {
    cp -r /data/redis-fomal-rdb/src/src_ttl_pick_$i.rdb $workdir/src 2>&1 >/dev/null
    cp -r /data/redis-fomal-rdb/dest/dest_ttl_pick_$i.rdb $workdir/dest 2>&1 >/dev/null
    } &
  done
  wait

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] rdb file check success ..." | tee -a $log_file

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] rdb file parse ..." | tee -a $log_file
  for i in `seq $slot_num`
  do
    {
    rdb -c memory $workdir/src/src_ttl_pick_$i.rdb -f $workdir/src/src_ttl_pick_0_$i.csv 2>/dev/null
    sed -i "1d" $workdir/src/src_ttl_pick_0_$i.csv && awk -F ',' '{print$3,$8}' $workdir/src/src_ttl_pick_0_$i.csv >$workdir/src/src_ttl_pick_$i.csv 2>/dev/null
    rdb -c memory $workdir/dest/dest_ttl_pick_$i.rdb -f $workdir/dest/dest_ttl_pick_0_$i.csv 2>/dev/null
    sed -i "1d" $workdir/dest/dest_ttl_pick_0_$i.csv && awk -F ',' '{print$3,$8}' $workdir/dest/dest_ttl_pick_0_$i.csv >$workdir/dest/dest_ttl_pick_$i.csv 2>/dev/null
    } &
  done
  wait

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] rdb file parse success ..." | tee -a $log_file

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] first compare ..." | tee -a $log_file
  src_cluster_ttl_pick=""
  dest_cluster_ttl_pick=""
  for i in `seq $slot_num`;
  do
    {
    src_cluster_ttl_pick="${src_cluster_ttl_pick} $workdir/src/src_ttl_pick_$i.csv"
    dest_cluster_ttl_pick="${dest_cluster_ttl_pick} $workdir/dest/dest_ttl_pick_$i.csv"
    }
  done

  if [ $? -eq 0 ];then
    touch $resultdir/src_cluster_ttl_pick_new.csv
    cat $src_cluster_ttl_pick > $resultdir/src_cluster_ttl_pick.csv
    sort -r $resultdir/src_cluster_ttl_pick.csv -o $resultdir/src_cluster_ttl_pick_new.csv
    rm -rf $resultdir/src_cluster_ttl_pick.csv

    touch $resultdir/dest_cluster_ttl_pick_new.csv
    cat $dest_cluster_ttl_pick > $resultdir/dest_cluster_ttl_pick.csv
    sort -r $resultdir/dest_cluster_ttl_pick.csv -o $resultdir/dest_cluster_ttl_pick_new.csv
    rm -rf $resultdir/dest_cluster_ttl_pick.csv
  fi

  #compare
  diff $resultdir/src_cluster_ttl_pick_new.csv $resultdir/dest_cluster_ttl_pick_new.csv > $workdir/diffout

  if [ ! -s  $workdir/diffout ];then
        if [ $? -eq 0 ];then
            echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires times are same" | tee -a $log_file && exit
        else
            echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys expires times are not same" | tee -a $log_file
            echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review src&dest_cluster_ttl_pick_new.csv" | tee -a $log_file && exit
        fi
  fi

  echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] second compare ..." | tee -a $log_file

  #grep -f $workdir/diffout $resultdir/src_cluster_ttl_pick_new.csv > $resultdir/src_cluster_ttl_pick_new_1.csv && grep -f $workdir/diffout $resultdir/dest_cluster_ttl_pick_new.csv > $resultdir/dest_cluster_ttl_pick_new_1.csv
  #grep -wf $workdir/diffout $resultdir/src_cluster_ttl_pick_new.csv > $resultdir/src_cluster_ttl_pick_new_1.csv
  #grep -wf $workdir/diffout $resultdir/dest_cluster_ttl_pick_new.csv > $resultdir/dest_cluster_ttl_pick_new_1.csv
  grep -E '^<.*|^>.*' $workdir/diffout > $workdir/diffout1 && sed -i "s/^<//g" $workdir/diffout1 && sed -i "s/^>//g" $workdir/diffout1 && sed -i 's/^[\t ]\+//g' $workdir/diffout1
  awk '{print $0}' $workdir/diffout1 $resultdir/src_cluster_ttl_pick_new.csv |sort -r |uniq -d  >$resultdir/src_cluster_ttl_pick_new_1.csv
  awk '{print $0}' $workdir/diffout1 $resultdir/dest_cluster_ttl_pick_new.csv |sort -r |uniq -d >$resultdir/dest_cluster_ttl_pick_new_1.csv
  awk -F ' ' '{print$1}' $resultdir/src_cluster_ttl_pick_new_1.csv > $resultdir/src_cluster_ttl_pick_new_2.csv && awk -F ' ' '{print$1}' $resultdir/dest_cluster_ttl_pick_new_1.csv > $resultdir/dest_cluster_ttl_pick_new_2.csv

  #diff $resultdir/src_cluster_ttl_pick_new_1.csv $resultdir/dest_cluster_ttl_pick_new_1.csv > $workdir/diffout2
  diff $resultdir/src_cluster_ttl_pick_new_2.csv $resultdir/dest_cluster_ttl_pick_new_2.csv > $workdir/diffout2

  if [ $? -eq 0 ];then
    echo "`date '+%Y-%m-%d %H:%M:%S'` [INFO] src & dest keys expires times are same" | tee -a $log_file
  else
    echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] src & dest keys expires times are not same" | tee -a $log_file
    echo "`date '+%Y-%m-%d %H:%M:%S'` [ERROR] please review src&dest_cluster_ttl_pick_new.csv" | tee -a $log_file
  fi

}

function main()
{
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
    4)
      init_redisttlcompare_pipe_conf
      ;;
    5)
      init_redisttlcompare_pipe_conf && redis_ttl_compare
      ;;
    esac
}

function main2()
{
    tips2
    read -p "init conf or exec main compare [1] :" act
    case $act in
    1)
      redisttlcompare_rdbtools
      ;;
    2)
      redis_ttl_compare
      ;;
    3)
      init_redisttlcompare_conf && redis_ttl_compare
      ;;
    4)
      init_redisttlcompare_pipe_conf
      ;;
    5)
      redisttlcompare_rdbtools
      ;;
    esac
}
#main
main2