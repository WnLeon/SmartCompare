#!/bin/bash
# Date: 2023-3-2
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Compare Data for Special Dir
# Version: V1.1
# Update: 2023-3-3

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}

#校验文件存储位置
file_out_dir=$task_out_dir/"1_File_Data_Compare"


#排除校验的路径所在位置
exclude_file_list=$exclude_file
myDos_unix $exclude_file_list

#源端登陆信息
src_ip=$src_ip
src_port=$src_port
src_username=$src_username
src_password=$src_password
src_id_rsa=$src_id_rsa
src_dir=$src_dir

#目标端登陆信息
dest_ip=$dest_ip
dest_port=$dest_port
dest_username=$dest_username
dest_password=$dest_password
dest_id_rsa=$dest_id_rsa
dest_dir=$dest_dir

#
if [ ! -d $file_out_dir ];then
  mkdir -p $file_out_dir
fi
#xargs --show-limits
<<!
Your environment variables take up 1871 bytes
POSIX upper limit on argument length (this system): 2093233
POSIX smallest allowable upper limit on argument length (all systems): 4096
Maximum length of command we could actually use: 2091362
Size of command buffer we are actually using: 131072
!

# cat xxx | awk -F' '  '{print $1}' > xxx2
# exec str create
exclude_str=""
for exclude_path in `cat $exclude_file_list`;
do
  exclude_str=$exclude_str"-o -path ${exclude_path} "
done
exclude_str="\( $exclude_str \)"
src_cmd="sudo find ${src_dir} ${exclude_str} -prune -o -type f -print0  | xargs -0 -n500 sudo md5sum >> /tmp/${src_ip}src_file_md5.list"
dest_cmd="sudo find ${dest_dir} ${exclude_str} -prune -o -type f -print0  | xargs -0 -n500 sudo md5sum >> /tmp/${dest_ip}dest_file_md5.list"
src_cmd=`echo $src_cmd | sed '0,/-o/{s/-o//}'`
dest_cmd=`echo $dest_cmd | sed '0,/-o/{s/-o//}'`
myLog 3 "$src_cmd" >> $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
myLog 3 "$dest_cmd" >> $(dirname $(dirname $CURRENT_DIR))/Logs/info.log

#src.sh
echo "#!/bin/bash
if [ -d '/tmp' ];then
  if [ -f '/tmp/${src_ip}src_file_md5.list' ];then
    sudo rm -rf /tmp/${src_ip}src_file_md5.list
    ${src_cmd}
  else
    ${src_cmd}
  fi
else
    exit
fi
" > $file_out_dir/src.sh

#dest.sh
echo "#!/bin/bash
if [ -d '/tmp' ];then
  if [ -f '/tmp/${dest_ip}dest_file_md5.list' ];then
    sudo rm -rf /tmp/${dest_ip}dest_file_md5.list
    ${dest_cmd}
  else
    ${dest_cmd}
  fi
else
    exit
fi
" > $file_out_dir/dest.sh

myLog 2 "src |/& dest file_md5 creating" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
#sshpass -p${src_password} ssh -p${src_port} -o StrictHostKeyChecking=no "$src_username"@"$src_ip" > /dev/null 2>&1 < $file_out_dir/src.sh & PIDIOS=$!
#sshpass -p${dest_password} ssh -p${dest_port} -o StrictHostKeyChecking=no "$dest_username"@"$dest_ip"  > /dev/null 2>&1 < $file_out_dir/dest.sh & PIDMIX=$!
sshpass -p${src_password} ssh -p${src_port} -o StrictHostKeyChecking=no "$src_username"@"$src_ip" < $file_out_dir/src.sh & PIDIOS=$!
sshpass -p${dest_password} ssh -p${dest_port} -o StrictHostKeyChecking=no "$dest_username"@"$dest_ip" < $file_out_dir/dest.sh & PIDMIX=$!
wait $PIDIOS
wait $PIDMIX
if [ $? -eq 0 ];then
  if [ "$src_dir" = "$dest_dir" ];then
    myLog 2 "compare path check down" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
    sshpass -p${dest_password} scp "${dest_username}"@"${dest_ip}":/tmp/${dest_ip}dest_file_md5.list $file_out_dir/  & PIDIOS=$!
    sshpass -p${src_password} scp "${src_username}"@"${src_ip}":/tmp/${src_ip}src_file_md5.list $file_out_dir/  & PIDMIX=$!
    wait $PIDIOS
    wait $PIDMIX
    if [ $? -eq 0 ];then
      myLog 2 "src |/& dest file_md5 ready" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
    else
      myLog 4 "src |/& dest file_md5 trans failed,please check network" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
    fi
  else
      myLog 2 "compare_dir_name:$src_dir && $dest_dir" |tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
      sshpass -p${dest_password} scp "${dest_username}"@"${dest_ip}":/tmp/${dest_ip}dest_file_md5.list $file_out_dir/  & PIDIOS=$!
      sshpass -p${src_password} scp "${src_username}"@"${src_ip}":/tmp/${src_ip}src_file_md5.list $file_out_dir/  & PIDMIX=$!
      wait $PIDIOS
      wait $PIDMIX
      if [ $? -eq 0 ];then
        cat $file_out_dir/${src_ip}src_file_md5.list |awk -F' ' '{print $1}' > $file_out_dir/${src_ip}src_file_md5_1.list && cat $file_out_dir/${src_ip}src_file_md5.list | awk -F ' ' '{print $2}' | sed 's#.*/##' > $file_out_dir/${src_ip}src_file_md5_2.list && awk 'NR==FNR{a[i]=$0;i++}NR>FNR{print a[j]" "$0;j++}' $file_out_dir/${src_ip}src_file_md5_1.list $file_out_dir/${src_ip}src_file_md5_2.list > $file_out_dir/${src_ip}src_file_md5_3.list
        cat $file_out_dir/${dest_ip}dest_file_md5.list |awk -F' ' '{print $1}' > $file_out_dir/${dest_ip}dest_file_md5_1.list && cat $file_out_dir/${dest_ip}dest_file_md5.list | awk -F ' ' '{print $2}' | sed 's#.*/##' > $file_out_dir/${dest_ip}dest_file_md5_2.list && awk 'NR==FNR{a[i]=$0;i++}NR>FNR{print a[j]" "$0;j++}' $file_out_dir/${dest_ip}dest_file_md5_1.list $file_out_dir/${dest_ip}dest_file_md5_2.list > $file_out_dir/${dest_ip}dest_file_md5_3.list
        cat $file_out_dir/${src_ip}src_file_md5_3.list| awk -F' ' '{print$2,$1}' | sort -r > $file_out_dir/${src_ip}src_file_md5.list
        cat $file_out_dir/${dest_ip}dest_file_md5_3.list| awk -F' ' '{print$2,$1}' | sort -r > $file_out_dir/${dest_ip}dest_file_md5.list
        if [ $? -eq 0 ];then
          myLog 2 "src |/& dest file_md5 ready" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
        else
          myLog 4 "src |/& dest file_md5 format failed,please check file_md5_new" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
        fi
      else
        myLog 4 "src |/& dest file_md5 trans failed,please check network" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
      fi

    fi

else
    myLog 4 "src |/& dest file_md5 create failed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
fi

diff $file_out_dir/${src_ip}src_file_md5.list $file_out_dir/${dest_ip}dest_file_md5.list > $file_out_dir/diff_out

if [ $? -eq 0 ];then
  myLog 2 "File Data check passed" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
else
  myLog 4 "File Data check failed, please review $file_out_dir/diff_out" |  tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log
fi
