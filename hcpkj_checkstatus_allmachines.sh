#!/bin/bash

searchsubj=$1
cmd='bash /home/range1-raid1/kjamison/hcp_pipeline/hcpkj_checkstatus.sh'

machines="atlas5 atlas6 atlas7 atlas8 gpu4hcp euclid asaf"
#machines="atlas7"

machines="atlas6 atlas7 atlas8 euclid"
for m in $machines; do
	echo
	echo $m
	ssh $m $cmd $searchsubj
done

