#!/bin/bash

if [ $# -lt 3 ]; then
	cmdname=`basename $0`
	echo -e "\033[0;31m
	$cmdname <searchdirectory> <orig subject> <new subject>

	Rename directories and files from <orig subject> to <new subject>
	Also replace instances of <orig subject> with <new subject> in any .spec
	files.

	\033[0m"
	exit 0
fi

#####################################
rootdir=$1
origsubj=$2
newsubj=$3


#searchfilter for in-place replacement text files
#searchfilter='\.(spec|env$'
searchfilter='\.(spec|dat|env|label|lta|sum)$'

maxdepth=10

RUN=
#RUN=echo

# rename directories (leaf directories)
for dep in `seq 1 $maxdepth`; do
	didchange=
	for i in `find $rootdir -mindepth $dep -maxdepth $dep -type d  | grep -E "${origsubj}"`; 
	do 
		d=`dirname $i`
		f=`basename $i`
		if [[ $f =~ "$origsubj" ]]; then
			fnew=`echo $f | sed "s/${origsubj}/${newsubj}/g"`
			${RUN} mv -f $d/$f $d/$fnew
			didchange=1
		fi
	done
	if [ "x${didchange}" = x ]; then
		break;
	fi
done


# rename files
for i in `find $rootdir -maxdepth $maxdepth -type f | grep "${origsubj}"`; 
do 
	d=`dirname $i`
	f=`basename $i`
	if [[ $f =~ "$origsubj" ]]; then
		${RUN} rename $origsubj $newsubj $i
	fi
done

# for all plaintext files, sed in place

if [ "x${searchfilter}" = x ]; then
	searchfilter=.
fi

#for i in `find $rootdir -maxdepth $maxdepth -type f | grep -E ''$searchfilter''`;
for i in `grep -rI ${origsubj} ${rootdir} | cut -d: -f1 | sort -u`
do 
	d=`dirname $i`
	f=`basename $i`
	if [[ $f =~ ''$searchfilter'' ]]; then
		echo sed -i.bak "s#${origsubj}#${newsubj}#g" $i
		${RUN} sed -i.bak "s#${origsubj}#${newsubj}#g" $i
	fi
done


