#!/bin/bash


initscript=initlist.txt
startidx=25
skipsize=4

numjobs=`cat ${initscript} | wc -l`
for i in `seq ${startidx} ${skipsize} ${numjobs}`; do
	cat ${initscript} | tail -n +${i} | head -n ${skipsize} | bash &
done

