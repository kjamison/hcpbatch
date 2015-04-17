#!/bin/bash

if [ $# -eq 0 ] 
then
	echo
	echo "$0 <subjid> REST REST1 <SBscan> <MBscan> <PASEscan> <APSEscan>"
	echo "<SBscan> etc... = scan number of SBRef in dicom directory"
	echo "eg: <SBscan>=6 for MR-SE006-BOLD_REST1_SBRef"
	echo
	exit 0
else
	SUBJID=$1; shift;
	scanname=$1; shift;
	scannums=$@
fi

RUN=""
#RUN="echo"

StudyFolder=/home/range1-raid1/kjamison/Data/MPS
dicomdir=/home/range1-raid1/igor-data/LDN/connectome

taskname=`echo ${scanname} | sed 's/_[APLR]\+$//'`

SBscan=`echo $scannums | awk '{print $1}'`
MBscan=`echo $scannums | awk '{print $2}'`
PASEscan=`echo $scannums | awk '{print $3}'`
APSEscan=`echo $scannums | awk '{print $4}'`

function matchdir {
	d=`dirname $1`
	f=`basename $1`
	res=`ls $d | grep $f | head -n 1`
	echo "$d/${res}"
	return 0
}

sessdir=`ls ${dicomdir} | grep ${SUBJID}`

SBdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${SBscan}\``
MBdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${MBscan}\``
PASEdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${PASEscan}\``
APSEdicomdir=`matchdir \`printf "${dicomdir}/${sessdir}/MR-SE%03d-" ${APSEscan}\``

PEstr=
if [[ $MBdicomdir = *_AP ]]; then
	PEstr=AP
elif [[ $MBdicomdir = *_PA ]]; then
	PEstr=PA
elif [[ $MBdicomdir = *_RL ]]; then
	PEstr=RL
elif [[ $MBdicomdir = *_LR ]]; then
	PEstr=LR
else
	printf "Unknown PE direction: %s\n" `basename ${MBdicomdir}`
	exit 0
fi

if [[ $PEstr = AP || $PEstr = PA ]]; then
        PEpos=PA
        PEneg=AP
	UnwarpAxis=y
else
        PEpos=RL
        PEneg=LR
	UnwarpAxis=x
fi

echo
echo "${sessdir}"
echo "SBRef = ${SBdicomdir}"
echo "MB    = ${MBdicomdir}"
echo "${PEpos}SE  = ${PASEdicomdir}"
echo "${PEneg}SE  = ${APSEdicomdir}"
echo "T1    = ${T1dir}"
echo "MNI   = ${MNIdir}"
echo

#nifti_ext='nii';
nifti_ext="nii.gz"

SBnii="BOLD_${taskname}_${PEstr}_SBRef.${nifti_ext}"
MBnii="BOLD_${taskname}_${PEstr}.${nifti_ext}"
PASEnii="SE_${taskname}_${PEpos}.${nifti_ext}"
APSEnii="SE_${taskname}_${PEneg}.${nifti_ext}"

niidir=${StudyFolder}/${SUBJID}
rawdir=${niidir}/unprocessed/${scanname}

SBnii_orig=${niidir}/unprocessed/`basename ${SBdicomdir}`.${nifti_ext}
MBnii_orig=${niidir}/unprocessed/`basename ${MBdicomdir}`.${nifti_ext}
PASEnii_orig=${niidir}/unprocessed/`basename ${PASEdicomdir}`.${nifti_ext}
APSEnii_orig=${niidir}/unprocessed/`basename ${APSEdicomdir}`.${nifti_ext}

${RUN} mkdir -p ${rawdir}

if [ -e ${SBnii_orig} ]; then
	${RUN} ln -s ${SBnii_orig} ${rawdir}/${SBnii}
	${RUN} ln -s ${MBnii_orig} ${rawdir}/${MBnii}
	${RUN} ln -s ${PASEnii_orig} ${rawdir}/${PASEnii}
	${RUN} ln -s ${APSEnii_orig} ${rawdir}/${APSEnii}
else
	${RUN} dcm2nii_filename --rename ${SBnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $SBdicomdir/*.dcm | head -n 1`
	${RUN} dcm2nii_filename --rename ${PASEnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $PASEdicomdir/*.dcm | head -n 1`
	${RUN} dcm2nii_filename --rename ${APSEnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $APSEdicomdir/*.dcm | head -n 1`
	${RUN} dcm2nii_filename --rename ${MBnii} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} `ls $MBdicomdir/*.dcm | head -n 1`
fi

echo "completed: $SUBJID $sessname $scanname"

#${RUN} cp -R ${T1dir} ${MNIdir} ${niidir}




