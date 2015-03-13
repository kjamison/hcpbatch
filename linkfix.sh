#!/bin/bash

D=$1

for l in `find $D -type l`
do
	targ=`readlink $l`
	targ2=`echo $targ | sed 's/REST1_REST1/REST_REST1/g'`
	targ2=`echo $targ2 | sed 's/REST2_REST2/REST_REST2/g'`
	#echo `dirname $l`/$targ2
	if [ -e `dirname $l`/$targ ]; then
		echo "link ok: $l"
		continue
	fi

	if [ -e `dirname $l`/$targ2 ]; then
		
		#origdir=`pwd`
		#cd `dirname $l`
		#cmd="ln -sf ${targ2} "`basename $l`
		#$cmd
		#cd $origdir

		echo "YES $l -> $targ2"
	else
		echo "NO $l -> $targ2"
	fi
done
