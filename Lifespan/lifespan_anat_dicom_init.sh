#!/bin/bash


###############################################
function show_help {
	echo
	echo `basename $0`" <sessionID> T1=<scannum> T2=<scannum>"
	echo
	echo "sessionID = LS7xxx_3T or LS7xxx_3Tb etc"
	echo "scannums = scan numbers for T1 or T2 scans"
	echo "    eg: T1=4 refers to MR-SE004-T1w_MPR"
	echo 
	echo "ex: "
	echo `basename $0`" LS7000_3Tb T1=4 T2=6"
	echo " refers to: "
	echo " <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE004-T1w_MPR "
	echo " <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE006-T2w_SPC "
	echo
	echo "Multiple T1 and T2 can be specified"
	echo
	echo "If no T1 and T2 are specified, just print out filter information"
	echo " for T1 and T2 scans in session directory, for reference"
	echo
	echo
	exit 0
	exit 0
}

function matchdir {
	d=`dirname $1`
	f=`basename $1`
	res=`ls $d | grep $f | head -n 1`
	echo "$d/${res}"
	return 0
}

###############################################
if [ $# -eq 0 ] 
then
	show_help;
else
	SESSION=$1
	shift;
fi

##############################################

RUN=""
#RUN="echo"

StudyFolder=/home/range1-raid1/kjamison/Data/Lifespan
dicomdir=/home/range3-raid4/dicom

if [[ $SESSION == */* ]]; then
	dicomsess=`readlink -f $SESSION`
	if [ $# -eq 0 ]; then
		echo "Must provide SUBJID if using explicit DICOM directory"
		exit 0
	fi
	SESSION=$1
	shift;
else
	sessdir=`ls ${dicomdir} | grep -E "\-${SESSION}\$"`
	if [ "x${sessdir}" = x ]; then
		echo "No DICOM folder found: ${dicomdir} ${SESSION}"
		exit 0
	fi
	dicomsess=${dicomdir}/${sessdir}
fi

if [ ! -e ${dicomsess} ]; then
	echo "No DICOM folder found: ${dicomsess}"
	exit 0
fi

SUBJID=`echo ${SESSION} | awk -F_ '{print $1}'`

############################################
## print filter info for all T1 and T2 in a session
##  so we can tell which are normalized etc
echo
echo ${SESSION}
for d in `ls ${dicomsess} | grep -E 'T1w|T2w'`
do
	scanstr=`echo ${d} | sed -r 's/^.+-SE0*([0-9]+)-(T[12]w_.+)$/\1 \2/'`
	dcmfile=`ls ${dicomsess}/${d}/*.dcm | head -n 1`
	filtstr=`dicom_hdr ${dcmfile} | grep "0008 0008" | awk -F// '{print $NF}'`
	echo ${scanstr} ${filtstr}
done
echo

if [ $# -eq 0 ]; then
	exit 0
fi
###############################################
T1scans=
T2scans=

while [[ $# > 0 ]]
do
	case $1 in
		T1=*|t1=* )
			T1scans="${T1scans} "`echo $1 | cut -d= -f2 | sed -r 's/,+/ /g'`;;
		T2=*|t2=* )
			T2scans="${T2scans} "`echo $1 | cut -d= -f2 | sed -r 's/,+/ /g'`;;

		* )
			if [ "x${T1scans}" = "x" ]; then
				T1scans="${T1scans} "`echo $1 | sed -r 's/,+/ /g'`
			else
				T2scans="${T2scans} "`echo $1 | sed -r 's/,+/ /g'`
			fi
	esac
	shift
done


#PASEscan=`echo $scannums | awk '{print $3}'`
#APSEscan=`echo $scannums | awk '{print $4}'`

niidir=${StudyFolder}/${SUBJID}
rawdir=${niidir}/unprocessed
structdir=${rawdir}/Structural

mkdir -p ${rawdir}
mkdir -p ${structdir}

nifti_ext="nii.gz"

for t in `echo T1 T2`; do
	case $t in 
		T1 ) scans=${T1scans};;
		T2 ) scans=${T2scans};;
	esac

	c=0
	for i in "${scans}"
	do
		c=$(( c + 1 ))
		scanname=`ls ${dicomsess} | grep -m1 \`printf "MR-SE%03d-" ${i}\``
		scandir=${dicomsess}/${scanname}

		niifile_orig=${scanname}.${nifti_ext}
		niifile="${t}w${c}.${nifti_ext}"
		dcmfile=`find ${scandir} -type f | grep dcm | head -n 1`
		${RUN} dcm2nii_filename --rename ${niifile_orig} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} ${dcmfile}
			
		${RUN} ln -s ${rawdir}/${niifile_orig} ${structdir}/${niifile}
	done
done


echo "completed: $SUBJID $sessname"

#${RUN} cp -R ${T1dir} ${MNIdir} ${niidir}




