#!/bin/bash

#subj=$1
Subjlist=$@

restcount=900

sesstype=MOVIE
sessnames=(mov1 mov1 mov2 mov2)

cmd="bash hcpkj_dicom_init.sh"

tmp=/tmp/kjdcm.txt
cd ~/range3hcp

for subj in $Subjlist; do
for i in `seq 1 ${#sessnames[@]}`; do

	sessname=${sessnames[$i-1]}
	scanname="MOVIE$i"

	rm -f $tmp
	bash ~/hcp_pipeline/hcpkj_dicom_search.sh $sessname $subj > $tmp

	mbname=`cat $tmp | grep "^\s*9[0-9][0-9]\s\+.\+BOLD_${scanname}" | awk '{print $2}'`

	if [ -z "${mbname}" ]; then
		echo "No $sesstype$i scan found for $subj"
		continue
	elif [ `echo ${mbname} | wc -w` -eq 1 ]; then
		restnum=`echo ${mbname} | awk -F - '{print \$2}' | sed 's/SE//' | bc`
		restpe=`echo ${mbname} | awk -F _ '{print $NF}'`

		if [ $scanname = MOVIE1 ] || [ $scanname = MOVIE3 ]; then
			sbnum=`echo "$restnum - 1" | bc`
			panum=`echo "$restnum + 2" | bc`
			apnum=`echo "$restnum + 4" | bc`
		else
			sbnum=`echo "$restnum - 1" | bc`
			panum=`echo "$restnum - 4" | bc`
			apnum=`echo "$restnum - 2" | bc`
		fi
		sbname=`printf "MR-SE%03d-BOLD_%s_%s_SBRef" $sbnum $scanname $restpe`
		paname=`printf "MR-SE%03d-BOLD_PA_SE" $panum`
		apname=`printf "MR-SE%03d-BOLD_AP_SE" $apnum`

		sbname_grep=`cat $tmp | grep "${sbname}\$" | awk '{print $2}'`
		paname_grep=`cat $tmp | grep "${paname}\$" | awk '{print $2}'`
		apname_grep=`cat $tmp | grep "${apname}\$" | awk '{print $2}'`

		if [ -z ${sbname_grep} ]; then
			echo "SBRef not found: ${sbname}"
		elif [ -z ${paname_grep} ]; then
			echo "PA_SE not found: ${paname}"
		elif [ -z ${apname_grep} ]; then
			echo "AP_SE not found: ${apname}"
		else
		#echo "$subj $scanname
		#$sbname
		#$paname
		#$apname
		#"
			echo $cmd $subj ${sessname} ${sesstype} ${scanname} ${sbnum} ${restnum} ${panum} ${apnum}
		fi
	else
		cat $tmp
		#echo 2 ${mbname}
	fi
done
done

rm -f $tmp

