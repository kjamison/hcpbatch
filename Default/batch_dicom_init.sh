#!/bin/bash

####################################################
function show_help {

	cmdname=`basename $0`
	echo -e "\033[0;31m
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <sessionID> <scan description> BOLD=<scannum> SE=<scannums> ...
${cmdname} <WHICHSTUDY>[@<WHICHSCANNER>] <session_dcm_dir> <subjID> <scan description> BOLD=<scannum> SE=<scannums> ...

Convert DICOM to nifti for a single functional scan.

sessionID = LS7000_3T or 102311_mov1_7T etc...
scan description = Name to assign this scan in the pipeline
    eg: REST1_AP or MOVIE1_PA etc...
scannums = scan numbers for BOLD, SBRef, SpinEchoFieldmap, or GRE Fieldmap scans
    eg: BOLD=12 refers to MR-SE012-rfMRI_REST1_AP

ex: 
${cmdname} lifespan@prisma LS7000_3Tb BOLD=12 SE=9,10
 refers to: 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE012-rfMRI_REST1_AP 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE009-SpinEchoFieldMap_PA 
 <dicomdir>/20150101-ST001-LS7000_3Tb/MR-SE010-SpinEchoFieldMap_AP 

BOLD=<scannum>
SE=<scannum1>,<scannum2> (Must specify both +/-, eg AP/PA or RL/LR)
FM=<scannum1>,<scannum2> (Must specify both phase and magnitude scans)

If no scans are given, just list relevant scans in session directory, 
 for reference
\033[0m"

}

function matchdir {
	d=`dirname $1`
	f=`basename $1`
	find $d -maxdepth 1 -mindepth 1 -type d | grep -Em1 -- $f
	return 0
}
##############################################

RUN=""
#RUN="echo"

force_convert=1

if [ $# -eq 0 ] 
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
		echo "Possible ${STUDYNAME} sessions in ${dicomsess}:"
		echo
		eval "ls ${dicomsess} ${SessionGrep} | column"
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
###############################

############################################
## print dicom counts for all relevant scans in a session
##  so we can tell which are complete
echo
echo "SESSION: ${SESSION}"
echo "DICOM Folder: ${dicomsess}"
for d in `ls ${dicomsess} | grep -iE 'BOLD|FieldMap|rfMRI|tfMRI|REST'`
do
	scannum=`echo ${d} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\1/'`
	scanstr=`echo ${d} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\2/'`
	dcmfile=`ls ${dicomsess}/${d}/*.dcm | head -n 1`
	dcmcount=`ls ${dicomsess}/${d}/*.dcm | wc -l`
	#filtstr=`dicom_hdr ${dcmfile} | grep "0008 0008" | awk -F// '{print $NF}'`
	printf "%2d %5s %-s\n" ${scannum} ${dcmcount} ${scanstr}
done
echo

scanname=$1; shift;

if [ $# -eq 0 ]; then
	exit 0
fi

if [[ $scanname = *=* ]]; then
	show_help;
	echo ""
	echo "**** Must provide scan name ****"
	echo ""
	exit 0
fi
################################

taskname=`echo ${scanname} | sed -r 's/_[APLR]+$//'`
tasktype=`echo ${scanname} | sed -r 's/[0-9]+(_[APLR]+)?$//'`

taskprefix=
case `echo $tasktype | tr "[a-z]" "[A-Z]"` in
	RFMRI_*|TFMRI_* )
		taskprefix=`echo ${taskname} | sed -r 's/^([tr]fMRI_).+/\1/i'`
		scanname=`echo ${scanname} | sed -r 's/^[tr]fMRI_//i'`
		taskname=`echo ${taskname} | sed -r 's/^[tr]fMRI_//i'`
		tasktype=`echo ${tasktype} | sed -r 's/^[tr]fMRI_//i'`
		;;
	REST* )
		taskprefix=rfMRI_;;
	RET* )
		taskprefix=tfMRI_;;
	MOVIE* )
		taskprefix=tfMRI_;;
	* )
		taskprefix=
		;;
esac

SBScan=
MBscan=
SEscanpos=
SEscanneg=
FMmag=
FMphs=
SEscans=
FMscans=

while [[ $# > 0 ]]
do
	arg=`echo $1 | sed -r -- 's/^-?//' | tr "[a-z]" "[A-Z]"`
	val=`echo $1 | cut -d= -f2 | sed -r 's/,+/ /g'`
	case $arg in
		SB=* )
			SBscan=$val;;
		BOLD=* )
			MBscan=$val;;
		SE=* )
			SEscans=$val;;
		FM=* )
			FMscans=$val;;
		FMMAG=* )
			FMmag=$val;;
		FMPHS=* )
			FMphs=$val;;
		SEAP=*|APSE=* )
			SEscanneg=$val;;
		SEPA=*|PASE=* )
			SEscanpos=$val;;
		SERL=*|RLSE=* )
			SEscanpos=$val;;
		SELR=*|LRSE=* )
			SEscanneg=$val;;

		* )
			echo "Unrecognized scan type: $1"
			exit 0
	esac
	shift
done

MBdicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${MBscan}\``
MBpedir=

#If no SB specified, check to see if scan before BOLD is the matching SBRef
if [ ! "x${MBdicomdir}" = x ] && [ "x${SBscan}" = x ]; then
	MBname=`basename ${MBdicomdir} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\2/'`
	MBscannum=`basename ${MBdicomdir} | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\1/'`

	sbtest=`matchdir \`printf "${dicomsess}/MR-SE%03d-" $(( MBscannum - 1 ))\``
	if [[ `basename ${sbtest}` = *${MBname}_SBRef ]]; then
		echo "Found the matching SBRef scan: $sbtest"
		SBscan=$(( MBscannum - 1 ))
	fi
fi

#PA vs RL is set based on study type in StudySettings, but if we supply a BOLD scan, check 
# to make sure it complies
if [ ! "x${MBdicomdir}" = x ]; then
	MBpedir=`basename ${MBdicomdir} | tr "[a-z]" "[A-Z]" | sed -r 's/^.+_(PA|AP|RL|LR)(_.+)?$/\1/'`
	if [[ ${MBpedir} = AP || ${MBpedir} = PA ]]; then
		UnwarpAxis=y
		PEpos=${PEpos_y}
		PEneg=${PEneg_y}
	elif [[ ${MBpedir} = RL || ${MBpedir} = LR ]]; then
		UnwarpAxis=x
		PEpos=${PEpos_x}
		PEneg=${PEneg_x}
	fi
fi

#If SpinEcho pair is provided, separate into positive and negative PE dir 
if [ ! "x$SEscans" = x ]; then
	for i in $SEscans; do
		scandir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${i}\``
		scanstr=`basename $scandir | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\2/'`

		SEpe=`echo $scanstr | tr "[a-z]" "[A-Z]" | sed -r 's/^.+_(PA|AP|RL|LR)(_.+)?$/\1/'`
		if [[ ${SEpe} == ${PEpos} ]]; then
			SEscanpos=$i
		elif [[ ${SEpe} == ${PEneg} ]]; then
			SEscanneg=$i
		else
			echo "SE Fieldmap: unknown PE direction: " ${scanstr}
			continue
		fi
	done
fi

#If GRE Fieldmap pair is provided, separate into Magnitude (2x files) and Phase (1x files) 
if [ ! "x$FMscans" = x ]; then
	fmcounts=
	for i in $FMscans; do
		scandir=`matchdir \`printf "${dicomsess}/-SE%03d-" ${i}\``
		if [ "x${scandir}" = x ]; then
			continue
		fi
		dcmcount=`ls ${scandir}/*.dcm | wc -l`
		scanstr=`basename $scandir | sed -r 's/^.+-SE0*([0-9]+)-(.+)$/\2/'`

		fmcounts="${fmcounts} $i=${dcmcount}"
	done

	if (( `echo $fmcounts | wc -w` == 2 )); then
		fmmin=`echo $fmcounts | tr " =" "\n " | sort -gk2 | head -n1`
		fmmax=`echo $fmcounts | tr " =" "\n " | sort -gk2 | tail -n +2 | head -n1`

		nmin=`echo $fmmin | awk '{print $2}'`
		nmax=`echo $fmmax | awk '{print $2}'`

		fm2x=`echo "scale=2; $nmax/$nmin == 2" | bc`

		if (( $fm2x )); then
			FMmag=`echo $fmmax | awk '{print $1}'`
			FMphs=`echo $fmmin | awk '{print $1}'`
		else
			echo "GRE Fieldmap: magnitude scans must have 2x files"
		fi
	fi
fi

#Dont use GRE fieldmap if we only have mag or phase
if (( `echo "$FMmag $FMphs" | wc -w` == 1 )); then
	echo "GRE Fieldmaps: Must include valid phase and magnitude scans"
	FMmag=
	FMphs=
fi

#Dont use SE fieldmap if we only have pos or neg
if (( `echo "$SEscanpos $SEscanneg" | wc -w` == 1 )); then
	echo "SpinEcho Fieldmaps: Must include valid positive and negative scans (eg: AP and PA)"
	SEscanpos=
	SEscanneg=
fi

SBdicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${SBscan}\``
MBdicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${MBscan}\``
SEposdicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${SEscanpos}\``
SEnegdicomdir=`matchdir \`printf "${dicomsess}/MR-SE%03d-" ${SEscanneg}\``
FMmagdicomdir=`matchdir \`printf "${dicomsess}/-SE%03d-" ${FMmag}\``
FMphsdicomdir=`matchdir \`printf "${dicomsess}/-SE%03d-" ${FMphs}\``

echo
echo "${dicomsess}"
echo "SBRef = ${SBdicomdir}"
echo "BOLD  = ${MBdicomdir}"
echo "SEpos = ${SEposdicomdir}"
echo "SEneg = ${SEnegdicomdir}"
echo "FMmag = ${FMmagdicomdir}"
echo "FMphs = ${FMphsdicomdir}"
echo

################################

#nifti_ext='nii';
nifti_ext="nii.gz"

niidir=${StudyFolder}/${SUBJID}
unprocdir=${niidir}/unprocessed
convertdir=${niidir}/unprocessed/converted
outdir=${niidir}/unprocessed/${taskprefix}${scanname}

SBnii="${taskprefix}${taskname}_${MBpedir}_SBRef"
MBnii="${taskprefix}${taskname}_${MBpedir}"
SEposnii="SE_${taskname}_${PEpos}"
SEnegnii="SE_${taskname}_${PEneg}"
FMmagnii="FM_${taskname}_Fieldmap_Mag"
FMphsnii="FM_${taskname}_Fieldmap_Phs"

#SEposnii="SE_${taskname}_${PEpos}"
#SEnegnii="SE_${taskname}_${PEneg}"
#FMmagnii="FM_${taskname}_Fieldmap_Mag"
#FMphsnii="FM_${taskname}_Fieldmap_Phs"

for sc in SB=${SBdicomdir}@${SBnii} MB=${MBdicomdir}@${MBnii} SEpos=${SEposdicomdir}@${SEposnii} SEneg=${SEnegdicomdir}@${SEnegnii} FMmag=${FMmagdicomdir}@${FMmagnii} FMphs=${FMphsdicomdir}@${FMphsnii}
do
	scantype=`echo $sc | cut -d= -f1`
	scandicomdir=`echo $sc | cut -d= -f2 | cut -d@ -f1`
	niifile=`echo $sc | cut -d= -f2 | cut -d@ -f2`
	if [ "x${scandicomdir}" = x ]; then
		continue
	fi

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
		
		if [ "${RUN}" = "echo" ]; then
			${RUN} "dicom_hdr -csa ${scandicom} > ${convertdir}/${nii_orig}.header.txt"
		else
			${RUN} dicom_hdr -csa ${scandicom} > ${convertdir}/${nii_orig}.header.txt

			dcmecho=`dicom_hinfo -tag 0018,0081 ${scandicomdir}/*-00??.dcm | sort -uk2 | awk '{print $1}'`
			for de in $dcmecho 
			do 
				${RUN} dicom_hinfo -tag 0018,0081 -no_name $de \
					| awk '{print "MultiEchoDICOM '`basename $de`' =",$0}' \
					>> ${convertdir}/${nii_orig}.header.txt
			done
		fi
		${RUN} cp -f ${scandicom} ${convertdir}/${nii_orig}.dcm
		${RUN} dcm2niiname --rename ${nii_orig}.${nifti_ext} -b ${dcm2nii_inifile} -o ${convertdir} ${scandicom}
		
	fi
	#bash ~/MATLAB/echospacing.sh ${scandicom}
	${RUN} imln ${convertdir}/${nii_orig} ${outdir}/${niifile}
	${RUN} ln -fs ${convertdir}/${nii_orig}.header.txt ${outdir}/${niifile}.header.txt
	${RUN} ln -fs ${convertdir}/${nii_orig}.dcm ${outdir}/${niifile}.dcm
done

echo "completed: $SUBJID $SESSION $scanname $@"





