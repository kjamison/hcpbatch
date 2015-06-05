#!/bin/bash

filename=$1

niidir=`dirname $filename`
f=`basename $filename`
znum=`${FSLDIR}/bin/fslinfo ${niidir}/$f | grep '^dim3' | awk '{print $NF}'`

if [[ $((znum % 2)) > 0 ]]; then
	znum2=$((znum-1))
	WD="${niidir}/orig_${znum}"
	mkdir -p ${WD}

	Image=${WD}/orig_${znum}.$f

	echo "Odd slices (${znum}).  Removing bottom slice from ${filename}"
	mv -f ${filename} ${Image}

	fslroi ${Image} ${WD}/slice.nii.gz 0 -1 0 -1 0 1 0 -1
	fslmaths ${WD}/slice.nii.gz -mul 0 ${WD}/slice.nii.gz
	fslmerge -z ${filename} ${Image} ${WD}/slice.nii.gz
	rm ${WD}/slice.nii.gz

else
	echo "Even slices (${znum}). ${filename}"
fi

