#!/bin/bash

if [ $# -eq 0 ] 
then
	echo
	echo `basename $0`" <sessionID> [<scannum1> <scannum2> ... ]"
	echo
	echo "sessionID = LS7xxx_3T or LS7xxx_3Tb etc"
	echo "scannums = scan numbers for DWI scans"
	echo "    eg: scannum1 = 4 refers to MR-SE004-DWI_dir72_AP"
	echo 
	echo "If no scannums are provided, use ALL DWI scans in session."
	echo
	echo
	exit 0
else
	SESSION=$1
	shift;
	scannums=$@
fi

RUN=""
#RUN="echo"

StudyFolder=/home/range1-raid1/kjamison/Data/Lifespan

dicomdir=/home/range3-raid4/dicom
SUBJID=`echo ${SESSION} | awk -F_ '{print $1}'`
sessdir=`ls ${dicomdir} | grep -E "\-${SESSION}\$"`


if [[ ${SESSION} == *_3T* ]]; then
        magnet=3T
elif [[ ${SESSION} == *_7T* ]]; then
	magnet=7T
else
	echo "unknown magnet strength: ${SESSION}"
	exit 0
fi

if [ "x${scannums}" = "x" ]; then
	scannums=`ls ${dicomdir}/${sessdir} | grep "DWI" | grep -vi "SBRef" \
		| sed -r 's/^.+-SE0*([0-9]+)-.+$/\1/'`
fi

scancount=`echo ${scannums} | wc -w`

if [[ ${scancount} != 4 ]] && [[ ${scancount} != 2 ]]; then
	echo "DWI scans must be in pairs"
	exit 0
fi


niidir=${StudyFolder}/${SUBJID}
rawdir=${niidir}/unprocessed/${magnet}
diffdir=${rawdir}/Diffusion

mkdir -p ${rawdir}
mkdir -p ${diffdir}

nifti_ext="nii.gz"


for i in ${scannums}
do
	scanname=`ls ${dicomdir}/${sessdir} | grep -m1 \`printf "MR-SE%03d-" ${i}\``
	scandir=${dicomdir}/${sessdir}/${scanname}

	diffname=`echo $scanname | sed -r 's/^.+-SE0*([0-9]+)-//'`
	niifile_orig=${scanname}
	niifile=${diffname}

	dcmfile=`find ${scandir} -type f | grep dcm | head -n 1`
	${RUN} dcm2nii_filename --rename ${niifile_orig}.${nifti_ext} -b ~/hcp_pipeline/dcm2nii_hcp.ini -o ${rawdir} ${dcmfile}
	${RUN} ln -s ${rawdir}/${niifile_orig}.${nifti_ext} ${diffdir}/${niifile}.${nifti_ext}
	${RUN} ln -s ${rawdir}/${niifile_orig}.bvec ${diffdir}/${niifile}.bvec
	${RUN} ln -s ${rawdir}/${niifile_orig}.bval ${diffdir}/${niifile}.bval
done


echo "completed: $SUBJID $sessname"



