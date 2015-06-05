#!/bin/bash

set -e

function display_help {
	cmdname=`basename $0`
	echo -e "\033[0;31m
	$cmdname [options] <multiecho nifti>

	Split and rename ME series so that the original name refers only to TE2
	for preprocessing.

	1. rename original input --> _ME
	2. split _ME scans into _TE1 _TE2 _TE3
	3. symlink _TE2 --> original name


	Options:
	-numecho <val>: Number of echo times in input (default=3)
	-preproc <val>: Which echo should be renamed to the original (default=2)
	\033[0m"
	exit 0
}

#######################################################

preprocecho=2
numecho=3

while [[ $1 == -* ]]
do
	case $1 in
		-numecho ) 
			numecho=$2; shift;;
		-preproc )
			preprocecho=$2; shift;;
		-h|-help ) 
			display_help;
		
	esac
	shift	
done

if [ $# -lt 1 ]; then
	display_help;
fi

inputfile=`remove_ext $1`

inputbase=`basename $inputfile`

if [ `imtest ${inputfile}_ME` = 0 ]; then
	immv ${inputfile} ${inputfile}_ME
fi

for i in `seq 1 $numecho`; do 
	fslskip ${inputfile}_ME ${inputfile}_TE$i $((i-1)) 3; 
done

#imln won't work here without an absolute path for some reason, so use readlink
#and of course readlink won't work without an extension, so use imfind
imln `readlink -f \`imfind ${inputfile}_TE${preprocecho}\`` ${inputfile}

