#!/bin/bash

####################################################
function show_help {
	cmdname=`basename $0`
	echo -e "\033[0;31m
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <sessionID> T1=<scannum> T2=<scannum>
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <session_dcm_dir> <subjID> T1=<scannum> T2=<scannum>

sessionID = LS7xxx_3T or LS7xxx_3Tb etc
scannums = scan numbers for T1 or T2 scans
    eg: T1=4 refers to MR-SE004-T1w_MPR

ex: 
${cmdname} lifespan@prisma LS7000_3Tb T1=4,5 T2=6
 refers to: 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE004-T1w_MPR 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE005-T1w_MPR2 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE006-T2w_SPC 

Multiple T1 and T2 can be specified

If no T1 and T2 are specified, just print out filter information
 for T1 and T2 scans in session directory, for reference
\033[0m"
}

function matchdir {
	d=`dirname $1`
	f=`basename $1`
	find $d -maxdepth 1 -mindepth 1 -type d | grep -m1 -- $f
	return 0
}
##############################################

RUN=""
#RUN="echo"

force_convert=1

if [ $# -lt 2 ] 
then
	show_help;
	exit 0
else
	if [ $1 = "-e" ]; then
		RUN="echo"
		shift;
	fi
	STUDYNAME=$1; shift;
	SESSION=$1; shift;
fi

##############################################



################
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${SCRIPTDIR}/batch_StudySettings.sh `echo $STUDYNAME | tr "@" " "`
if [ -z ${StudyFolder} ]; then
	exit 1
fi
##############
echo $SESSION
echo $STUDYNAME
echo $DicomRoot

if [ x${SESSION} = x ]; then

	echo "*******************************"
	echo "Possible ${STUDYNAME} sessions in ${DicomRoot}:"
	echo
	eval "ls ${DicomRoot} ${SessionGrep} | column"
	echo "*******************************"
	show_help;
	echo ""
	echo "**** Must provide SESSION name to search for in DICOM directory ****"
	echo ""
	exit 0
elif [[ $SESSION == */* ]] && [ -d $SESSION ]; then
	dicomsess=`readlink -f $SESSION`
	SUBJID=$1
	shift;

	if [ "x$SUBJID" = x ]; then
		echo "*******************************"
		echo "Possible ${STUDYNAME} session in ${dicomsess}:"
		echo
		eval "ls ${dicomsess} | column"
		echo "*******************************"
		show_help;
		echo ""
		echo "**** Must provide SUBJID if using explicit DICOM directory ****"
		echo ""
		exit 0
	fi

else
	SUBJID=`echo ${SESSION} | awk -F_ '{print $1}'`

	echo "DICOM folders for ${SUBJID}:"
	ls ${DicomRoot} | grep -- "$SUBJID"

	sessdir=`ls ${DicomRoot} | grep -E "\-${SESSION}\$"`
	if [ "x${sessdir}" = x ]; then
		echo "No DICOM folder found: ${dicomdir} ${SESSION}"
		exit 0
	fi
	dicomsess=${DicomRoot}/${sessdir}
fi

if [ ! -d ${dicomsess} ]; then
	echo "No DICOM folder found: ${dicomsess}"
	exit 0
fi

############################################
## print filter info for all T1 and T2 in a session
##  so we can tell which are normalized etc
echo
echo "SESSION: ${SESSION}"
echo "DICOM Folder: ${dicomsess}"
for d in `ls ${dicomsess} | grep -iE 'T1w|T2w'`
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
	arg=`echo $1 | sed -r -- 's/^-?//' | tr "[a-z]" "[A-Z]"`
	val=`echo $1 | cut -d= -f2 | sed -r 's/,+/ /g'`
	case $arg in
		T1=* )
			T1scans="${T1scans} $val";;
		T2=* )
			T2scans="${T2scans} $val";;
		* )
			echo "Unrecognized scan type: $1"
			exit 0
	esac
	shift
done

################################

#nifti_ext='nii';
nifti_ext="nii.gz"

niidir=${StudyFolder}/${SUBJID}
unprocdir=${niidir}/unprocessed
convertdir=${niidir}/unprocessed/converted
outdir=${niidir}/unprocessed/Structural

for t in `echo T1 T2`; do
	scantype=$t
	scans=
	case $scantype in 
		T1 ) scans=${T1scans};;
		T2 ) scans=${T2scans};;
	esac

	c=0
	for i in ${scans}
	do
		scannum=$i
		c=$(( c + 1 ))
		scandicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${scannum}\``
		niifile="${scantype}w${c}"
		
		dicomname=`basename ${scandicomdir}`
		nii_orig=${dicomname}
		
		scandicom=`find $scandicomdir -maxdepth 1 -mindepth 1 -type f | grep -iE '(dcm|ima)$' | sort | head -n 1`

		if [ ! -d ${unprocdir} ] || [ ! -d ${outdir} ] || [ ! -d ${convertdir} ]; then
			#dont create directories until here, in case there arent actually any scans
			${RUN} mkdir -p ${unprocdir}
			${RUN} mkdir -p ${outdir}
			${RUN} mkdir -p ${convertdir}
		fi

		if [[ ! x${force_convert} = x ]] && [[ `imtest ${unprocdir}/${nii_orig}` = 0 ]]; then
			:
			#skip if we already did a conversion...
			${RUN} dicom_hdr -sexinfo ${scandicom} > ${convertdir}/${nii_orig}.header.txt
			${RUN} cp -f ${scandicom} ${convertdir}/${nii_orig}.dcm
			${RUN} dcm2niiname --rename ${nii_orig}.${nifti_ext} -b ${dcm2nii_inifile} -o ${convertdir} ${scandicom}
		
		fi
		${RUN} imln ${convertdir}/${nii_orig} ${outdir}/${niifile}
		${RUN} ln -fs ${convertdir}/${nii_orig}.header.txt ${outdir}/${niifile}.header.txt
		${RUN} ln -fs ${convertdir}/${nii_orig}.dcm ${outdir}/${niifile}.dcm

	done
done

echo
echo "completed: $SUBJID $SESSION $@"

#${RUN} cp -R ${T1dir} ${MNIdir} ${niidir}




