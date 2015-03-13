#!/bin/bash

subjfile=~/Data2/goodsubj.txt


durfile="durations_20140910b.txt"

do_rerun=
if [ ! -e $durfile ]; then
	do_rerun=1
elif [[ $1 == "-r" ]]; then
	do_rerun=1
	shift;
fi
 
if [[ -n ${do_rerun} ]]; then
	bash pipeline_duration.sh $@ > ${durfile}
fi

#cat durations_20140910b.txt | awk '{print $1,$2}' | tr '\n' '\f' | sed 's/\f\s*\f/\n/g' | tr '\f' '\t' | sed 's/.*Phase2_7T\///' | sed 's/\//\t/' | sed 's/\s[a-z]\+\s/\t/g' > durations_20140910b_parsed.txt


numsubj=`cat $subjfile | wc -l`

echo "#. <subjid>	<scanname> 	mc	topup	resamp	surf	hpf	ica"

for s in `seq 1 $numsubj`; do
	subj=`getline $subjfile $s`
	cat ${durfile} | awk '{print $1,$2}' | tr '\n' '\f' | sed 's/\f\s*\f/\n/g' | tr '\f' '\t' | sed 's/.*Phase2_7T\///' | sed 's/\//\t/' | sed 's/\s[a-z]\+\s/\t/g' | grep $subj | sed "s/^/$s. /"
done
