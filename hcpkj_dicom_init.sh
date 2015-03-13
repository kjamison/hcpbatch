#!/bin/bash

if [ $# -eq 0 ] 
then
	echo
	echo "$0 <subjid> mov1 REST REST1 <SBscan> <MBscan> <PASEscan> <APSEscan>"
	echo "<SBscan> etc... = scan number of SBRef in dicom directory"
	echo "eg: <SBscan>=6 for MR-SE006-BOLD_REST1_SBRef"
	echo
	exit 0
else
	SUBJID=$1
	sessname=$2
	scantype=$3
	scanname=$4
	shift; shift; shift; shift;
	scannums=$@
fi

RUN=""
#RUN="echo"

hcpdir=/hcp/hcpdb/HCP_500/arc001
dicomdir=/home/range3-raid4/dicom

SBscan=`echo $scannums | awk '{print $1}'`
MBscan=`echo $scannums | awk '{print $2}'`
PASEscan=`echo $scannums | awk '{print $3}'`
APSEscan=`echo $scannums | awk '{print $4}'`

if [ ! -d ${hcpdir} ]; then
	echo "HCPDB not found.  Are you on atlas4?"
	exit 0
fi

function matchdir {
	d=`dirname $1`
	f=`basename $1`
	res=`ls $d | grep $f | head -n 1`
	echo "$d/${res}"
	return 0
}

sessdir=`ls ${dicomdir} | grep ${SUBJID}_${sessname}_7T`

SBdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${SBscan}\``
MBdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${MBscan}\``
PASEdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${PASEscan}\``
APSEdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${APSEscan}\``

PEstr=
if [[ $MBdicomdir = *_AP ]]; then
	PEstr=AP
elif [[ $MBdicomdir = *_PA ]]; then
	PEstr=PA
else
	printf "Unknown PE direction: %s\n" `basename ${MBdicomdir}`
	exit 0
fi

T1dir=${hcpdir}/${SUBJID}_3T/RESOURCES/Structural_preproc/T1w
MNIdir=${hcpdir}/${SUBJID}_3T/RESOURCES/Structural_preproc/MNINonLinear


if [ ! -d ${T1dir} ]; then
	echo "Subject not found in HCPDB: ${SUBJID}."
	exit 0
fi

echo
echo "${sessdir}"
echo "SBRef = ${SBdicomdir}"
echo "MB    = ${MBdicomdir}"
echo "PASE  = ${PASEdicomdir}"
echo "APSE  = ${APSEdicomdir}"
echo "T1    = ${T1dir}"
echo "MNI   = ${MNIdir}"
echo

nifti_ext='nii';
#nifti_ext="nii.gz"

SBnii="BOLD_${scanname}_${PEstr}_SBRef.${nifti_ext}"
MBnii="BOLD_${scanname}_${PEstr}.${nifti_ext}"
PASEnii="SE_${scanname}_PA.${nifti_ext}"
APSEnii="SE_${scanname}_AP.${nifti_ext}"

niidir=/home/range1-raid1/kjamison/Data2/Phase2_7T/${SUBJID}
rawdir=${niidir}/unprocessed/${scantype}

${RUN} mkdir -p ${rawdir}

#don't copy if it's already in place
if [ ! -d "${niidir}/"`basename ${T1dir}` ]; then
	#mkdir first so the next job won't try to duplicate
	mkdir -p "${niidir}/"`basename ${T1dir}`
	${RUN} cp -R ${T1dir} ${niidir}
fi

if [ ! -d "${niidir}/"`basename ${MNIdir}` ]; then
	mkdir -p "${niidir}/"`basename ${MNIdir}`
	${RUN} cp -R ${MNIdir} ${niidir}
fi

${RUN} dcm2nii_filename --rename ${SBnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $SBdicomdir/*.dcm | head -n 1`
${RUN} dcm2nii_filename --rename ${PASEnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $PASEdicomdir/*.dcm | head -n 1`
${RUN} dcm2nii_filename --rename ${APSEnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $APSEdicomdir/*.dcm | head -n 1`
${RUN} dcm2nii_filename --rename ${MBnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $MBdicomdir/*.dcm | head -n 1`

echo "completed: $SUBJID $sessname $scantype $scanname"

#${RUN} cp -R ${T1dir} ${MNIdir} ${niidir}




