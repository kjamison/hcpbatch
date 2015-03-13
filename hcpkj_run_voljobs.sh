#!/bin/bash

startidx=$1
endidx=$2

Subjlist=~/Data2/goodsubj.txt

for i in `seq ${startidx} ${endidx}`; do
	subj=`cat ${Subjlist} | tail -n +${i} | head -n 1`
	bash AllGenericfMRIVolumeProcessingPipeline_HCP7T_20140817.sh $subj
	#cat ${Subjlist} | tail -n +${i} | head -n ${skipsize} | bash AllGenericfMRIVolumeProcessingPipeline_HCP7T_20140817.sh
done

