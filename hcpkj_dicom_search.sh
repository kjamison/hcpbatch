#!/bin/bash

# Just give usage if no arguments specified
if [ $# -eq 0 ] 
then	
	echo
	echo "$0 mov1 <subjid1> <subjid2>"
	echo
	exit 0
else
	sessname=$1
	shift;
	Subjlist=$@
fi

cd ~/range3hcp


hcpdir=/hcp/hcpdb/HCP_500/arc001/

if [ ! -d ${hcpdir} ]; then
	echo
	echo "HCPDB not found!  Make sure you are on atlas4.cmrr.umn.edu"
	echo
	exit 0
fi

echo
for SUBJID in $Subjlist
do

	T1dir="${hcpdir}/${SUBJID}_3T/RESOURCES/Structural_preproc/T1w"
	MNIdir="${hcpdir}/${SUBJID}_3T/RESOURCES/Structural_preproc/MNINonLinear"

	if [ ! -d ${T1dir} ]; then
		echo "Not found in 3T database: ${SUBJID}"
		echo
		continue
	fi

	#dicomcount -d *${SUBJID}_${sessname}_7T | grep "REST\|${sessname}_"
	dicomcount -d *${SUBJID}_${sessname}_7T
	echo
	

done

