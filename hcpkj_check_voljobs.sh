#!/bin/bash

function filesize {
	dims=`fslinfo $1 | grep '^dim' | awk '{print $2}' | xargs | awk '{printf "%dx%dx%d %d",$1,$2,$3,$4}'`
	sz=`stat -c "%s" $1`
	if (( $sz > 1024*1024*1024 )); then
		szs=`echo $sz | awk '{printf "%.2fG\n",$1/(1024*1024*1024)}'`
	else
		szs=`echo $sz | awk '{printf "%.2fM\n",$1/(1024*1024)}'`
	fi
	echo "$szs $dims"
	return 0
}

sessions=(REST1_PA REST2_AP REST3_PA REST4_AP)

for subj in `cat ~/Data2/goodsubj.txt | xargs`; do
for sess in ${sessions[@]}; do
	sessname=`echo $sess | sed 's/_.*//'`

	sbfile=`imfind ~/Data2/Phase2_7T/${subj}/unprocessed/REST/BOLD_${sess}_SBRef`
	mbfile=`imfind ~/Data2/Phase2_7T/${subj}/unprocessed/REST/BOLD_${sess}`
	pafile=`imfind ~/Data2/Phase2_7T/${subj}/unprocessed/REST/SE_${sessname}_PA`
	apfile=`imfind ~/Data2/Phase2_7T/${subj}/unprocessed/REST/SE_${sessname}_AP`

	if [ X$sbfile == X ]; then
		echo "missing $subj $sess $sbfile"
		continue
	elif [ X$mbfile == X ]; then
		echo "missing $subj $sess $mbfile"
		continue
	elif [ X$pafile == X ]; then
		echo "missing $subj $sess $pafile"
		continue
	elif [ X$apfile == X ]; then
		echo "missing $subj $sess $apfile"
		continue
	fi

	
	printf "%10s %5s %-30s %s\n"  $subj $sessname "`filesize $mbfile`" $mbfile
	printf "%10s %5s %-30s %s\n"  $subj $sessname "`filesize $sbfile`" $sbfile
	printf "%10s %5s %-30s %s\n"  $subj $sessname "`filesize $pafile`" $pafile
	printf "%10s %5s %-30s %s\n"  $subj $sessname "`filesize $apfile`" $apfile
done
done
