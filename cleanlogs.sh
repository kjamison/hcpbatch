#!/bin/bash

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
scriptroot=${SCRIPTDIR}/../

for i in `find ${scriptroot} -mindepth 1 -maxdepth 1 -type d`
do 
	logfiles=`find $i -maxdepth 1 -type f | grep -E '\.[oe][0-9]+$'`
	if [ "x$logfiles" = x ]
	then 
		continue
	fi
	mkdir -p $i/logs
	mv $logfiles $i/logs/
done

