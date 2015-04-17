#!/bin/bash

Subject_all=$1
ScanName_all=$2

#ScanName = eg REST1_PA
#startwith = dcm2nii , init gdc mc dc resample norm results , surface, hpf, melodic

StudyFolder="/home/range1-raid1/kjamison/Data/mayo_data" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/Source/BatchPipeline/SetUpHCPPipeline.sh" #Pipeline environment script

# Requirements for this script
#  installed versions of: FSL5.0.2 or higher , FreeSurfer (version 5.2 or higher) , gradunwarp (python code from MGH)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript} &> /dev/null

FSL_FIXDIR="/home/range1-raid1/kjamison/Data/fix1.06"
export FSL_FIXDIR

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"

RUN=

HPF=2000

for Subject in $Subject_all; do
	for ScanName in $ScanName_all; do

		fMRIName="${ScanName}"

		fMRIfile=`imfind ${StudyFolder}/${Subject}/${ScanName}/${fMRIName}_mc`

		if [ -z $fMRIfile ]; then
			echo "Can't find file: ${StudyFolder}/${Subject}/${ScanName}/${fMRIName}_mc"
			continue
		fi

		${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE \
		${FSL_FIXDIR}/hcp_fix \
		${fMRIfile} \
		${HPF}
	done
done
