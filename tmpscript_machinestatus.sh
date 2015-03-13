#!/bin/bash

statusfile=machinestatus.txt
subjfile=~/Data2/goodsubj.txt

bash hcpkj_checkstatus_allmachines.sh > ${statusfile}

numsubj=`cat ${subjfile} | wc -l`

for s in `seq 1 ${numsubj}`; do
	#cat ${statusfile} | grep `getline ${subjfile} $s` | sed "s/^/$s. /"
	cat ${statusfile} | grep `getline ${subjfile} $s` | sed "s/^/$s.\t/"
done

