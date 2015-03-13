#!/bin/bash

filename=$1

niidir=`dirname $filename`
f=`basename $filename`
znum=`${FSLDIR}/bin/fslinfo ${niidir}/$f | grep '^dim3' | awk '{print $NF}'`

if [[ $((znum % 2)) > 0 ]]; then
	znum2=$((znum-1))
	niidir2="${niidir}/orig_${znum}"
	if [[ ! -d ${niidir2} ]]; then
	    mkdir -p ${niidir2}
	fi

	echo "Odd slices (${znum}).  Removing bottom slice from ${niidir}/$f"
	mv -f ${niidir}/$f ${niidir2}/orig_${znum}.$f
	${FSLDIR}/bin/fslroi ${niidir2}/orig_${znum}.$f ${niidir}/$f 0 -1 0 -1 1 -1
else
	echo "Even slices (${znum}). ${niidir}/$f"
fi

