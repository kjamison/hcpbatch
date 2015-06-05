#!/bin/bash

####################################################
function show_help {
	cmdname=`basename $0`
	echo -e "\033[0;31m
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <sessionID> [<scannum1> <scannum2> ... ]
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <session_dcm_dir> <subjID> [<scannum1> <scannum2> ... ]

sessionID = LS7xxx_3T or LS7xxx_3Tb etc
scannums = scan numbers for DWI scans
    eg: scannum1 = 4 refers to MR-SE004-DWI_dir72_AP

ex: 
${cmdname} lifespan@prisma LS7000_3T 4 6 10 12
 refers to: 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE004-DWI_dir72_AP
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE006-DWI_dir72_PA
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE008-DWI_dir71_AP
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE012-DWI_dir71_PA

If no scannums are provided, use ALL DWI scans in session.

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
#####################################

############################################
## print dicom counts for all relevant scans in a session
##  so we can tell which are complete
echo
echo "SESSION: ${SESSION}"
echo "DICOM Folder: ${dicomsess}"
for d in `ls ${dicomsess} | grep -iE 'DWI'`
do
	scannum=`echo ${d} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\1/'`
	scanstr=`echo ${d} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\2/'`
	dcmfile=`ls ${dicomsess}/${d}/*.dcm | head -n 1`
	dcmcount=`ls ${dicomsess}/${d}/*.dcm | wc -l`
	#filtstr=`dicom_hdr ${dcmfile} | grep "0008 0008" | awk -F// '{print $NF}'`
	printf "%2d %5s %-s\n" ${scannum} ${dcmcount} ${scanstr}
done
echo

if [ $# -eq 0 ]; then
	exit 0
fi

scannums=$@

if [ "x${scannums}" = "x" ]; then
	scannums=`ls ${dicomdir}/${sessdir} | grep "DWI" | grep -vi "SBRef" \
		| sed -r 's/^.+-SE0*([0-9]+)-.+$/\1/'`
fi

scancount=`echo ${scannums} | wc -w`

if [[ ${scancount} != 4 ]] && [[ ${scancount} != 2 ]]; then
	echo "DWI scans must be in pairs"
	exit 0
fi

#nifti_ext='nii';
nifti_ext="nii.gz"

niidir=${StudyFolder}/${SUBJID}
unprocdir=${niidir}/unprocessed
convertdir=${niidir}/unprocessed/converted
outdir=${niidir}/unprocessed/Diffusion

for i in ${scannums}
do
	scannum=$i
	scandicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${scannum}\``

	dicomname=`basename ${scandicomdir}`
	nii_orig=${dicomname}
	
	scandicom=`find $scandicomdir -maxdepth 1 -mindepth 1 -type f | grep -iE '(dcm|ima)$' | sort | head -n 1`

	if [ ! -d ${unprocdir} ] || [ ! -d ${outdir} ] || [ ! -d ${convertdir} ]; then
		#dont create directories until here, in case there arent actually any scans
		${RUN} mkdir -p ${unprocdir}
		${RUN} mkdir -p ${outdir}
		${RUN} mkdir -p ${convertdir}
	fi


	diffname=`echo $dicomname | sed -r 's/^.+-SE0*([0-9]+)-//'`
	niifile=${diffname}

	if [[ ! x${force_convert} = x ]] && [[ `imtest ${unprocdir}/${nii_orig}` = 0 ]]; then
		:
		#skip if we already did a conversion...
		${RUN} cp -f ${scandicom} ${convertdir}/${nii_orig}.dcm
		${RUN} dcm2niiname --rename ${nii_orig}.${nifti_ext} -b ${dcm2nii_inifile} -o ${convertdir} ${scandicom}

	fi

	${RUN} imln ${convertdir}/${nii_orig} ${outdir}/${niifile}
	${RUN} ln -fs ${convertdir}/${nii_orig}.bvec ${outdir}/${niifile}.bvec
	${RUN} ln -fs ${convertdir}/${nii_orig}.bval ${outdir}/${niifile}.bval

	${RUN} ln -fs ${convertdir}/${nii_orig}.dcm ${outdir}/${niifile}.dcm

	#${RUN} ln -fs ${convertdir}/${nii_orig}.header.txt ${outdir}/${niifile}.header.txt
	${RUN} dicom_hdr -sexinfo ${outdir}/${niifile}.dcm > ${outdir}/${niifile}.header.txt
done


echo "completed: $SUBJID $SESSION $@"



