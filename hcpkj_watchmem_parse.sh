#!/bin/bash

watchfile=`readlink -f $1`

qstr='2>/dev/null'

startnums=( $(cat ${watchfile} | grep -n '^top' | awk -F: '{print $1}') );

firstlist=`cat ${watchfile} | grep -n -m1 '^\s*PID\s*USER' | awk -F: '{print $1}'`

((listoffset=$firstlist - ${startnums[0]} + 1))

cmd_blank="tail -n +${firstlist} ${watchfile} ${qstr} | grep -n -m1 '^\s*$' | awk -F: '{print \$1}'"
firstblank=`eval $cmd_blank`
((numblank=startnums[1]-(firstblank+firstlist-1)))

for i in $(seq 0 $((${#startnums[@]}-1))); do
#for i in $(seq 0 10); do
	idx1tmp=${startnums[$i]}
	((idx1=idx1tmp+listoffset))
	idx2=${startnums[$i+1]}
	((idxlen=idx2-idx1-numblank))

	
	if [ X$idx2 == X ]; then
		idxlen=0
		lenstr=
	else
		lenstr=" | head -n $idxlen"
	fi
	
	#timestr=`tail -n +${idx1tmp} ${watchfile} | head -n 1 | awk '{print $3}'`
	cmd_cpu="tail -n +${idx1} ${watchfile} ${qstr} $lenstr | awk 'BEGIN{printf 0}{printf \"+(%s)\",\$9}' | tr '\n' '+' | awk '{print \$0}' | bc"
	cmd_mem="tail -n +${idx1} ${watchfile} ${qstr} $lenstr | awk 'BEGIN{printf 0}{printf \"+(%s)\",\$10}' | tr '\n' '+' | awk '{print \$0}' | bc"

	timestr=
	sum_cpu=`eval $cmd_cpu`
	sum_mem=`eval $cmd_mem`
	echo "$timestr $sum_cpu $sum_mem"
	#eval "tail -n +${idx1} ${watchfile} $lenstr"

	#echo "#############################################################"
	#echo $idx1 $idx2 $idxlen
	#cat ${watchfile}
	#break
done

