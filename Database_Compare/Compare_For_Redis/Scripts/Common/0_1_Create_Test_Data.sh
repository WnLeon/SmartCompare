#!/bin/bash
# Date: 2023-3-7
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: create redis test data
# Version: V1.1
# Update: 2023-3-7

#type    input         lookfor
#string  set           get
#hash    hmset         hget
#list    lpush         lrange
#set     sadd          smembers
#zset    zadd          zrangebyscore

#string
for i in `seq 10000`;
do
{
  echo string$i
  echo  "     SET StrKey$i VALUE$i" >>redistestdata1.txt
} &
wait
done

#addexpiretimes
for i in `seq 10000`;
do
{
  echo $i
  echo  "     expire StrKey$i 1000" >>redistestdataexpir.txt
} &
wait
done

#hash
for i in `seq 10000`;
do
{
  echo hash$i
  echo  '     HMSET HsKey$i field1 "VALUE$i" field2 "VALUE$i+1"' >>redistestdata1.txt
} &
wait
done
#list
for i in `seq 10000`;
do
{
  echo list$i
  echo  "     lpush LsKey$i VALUE$i  VALUE$i+1" >>redistestdata1.txt
} &
wait
done

#set
for i in `seq 10000`;
do
{
  echo set$i
  echo  "     sadd SetKey$i VALUE$i VALUE$i+1" >>redistestdata1.txt
} &
wait
done

#zset
for i in `seq 10000`;
do
{
  echo zset$i
  echo  "     zadd ZsetKey$i 0  VALUE$i" >>redistestdata1.txt
} &
wait
done

for i in `seq 10000`;
do
{
  echo $i
  echo  "     expire HsKey$i 1000" >>redistestdataexpir.txt
} &
wait
done


for i in `seq 10000`;
do
{
  echo $i
  echo  "     expire LsKey$i 1000" >>redistestdataexpir.txt
} &
wait
done


for i in `seq 10000`;
do
{
  echo $i
  echo  "     expire SetKey$i 1000" >>redistestdataexpir.txt
} &
wait
done

for i in `seq 10000`;
do
{
  echo $i
  echo  "     expire ZsetKey$i 1000" >>redistestdataexpir.txt
} &
wait
done
