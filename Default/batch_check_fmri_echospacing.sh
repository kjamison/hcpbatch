#!/bin/bash

dicomfiles=
for sessiondir in $@
do
	for d in `ls $sessiondir | grep -iE 'rfMRI|REST' | grep -vi sbref | grep -vE -- '(-SE.+SE|SpinEcho)'`
	do
		dcmfile=`dicom_file $sessiondir/$d`
		dicomfiles="$dicomfiles $dcmfile"
	done

done

bash ~/MATLAB/batch_echospacing.sh $dicomfiles


