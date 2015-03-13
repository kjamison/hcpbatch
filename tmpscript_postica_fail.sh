#!/bin/bash

scannames=(REST1_PA REST2_AP REST3_PA REST4_AP)

for s in `seq 1 25`; do
	subj=`getline ~/Data2/goodsubj.txt $s`

	subjsum=0
	for sc in ${scannames[@]}; do
		#echo ~/Data2/Phase2_7T/${subj}/MNINonLinear/Results/REST_${sc}
		d=~/Data2/postfix/${subj}/MNINonLinear/Results/REST_${sc}
		dfix=$d/REST_${sc}_hp2000.ica/fix

		if [ -d $dfix ]; then
			fixsz=`ls $dfix | wc -l`
		else
			fixsz=0
		fi
		#printf "%2d. %10s %12s %d\n" $s $subj $sc $fixsz

		tfinal=`stat --format="%y" ${dfix}/logMatlab.txt`

		printf "%2d. %10s %12s %s\n" $s $subj $sc "$tfinal"
		#dfixtest=`ls $d/REST_${sc}_hp2000.ica | grep fix`
		#printf "%2d. %10s %12s %s\n" $s $subj $sc $dfixtest
	done
	
done

