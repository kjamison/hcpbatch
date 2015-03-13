#!/bin/bash 

# Just give usage if no arguments specified
if [ $# -eq 0 ] 
then
	echo `basename $0` "<subjid>"
	exit 0
	#Subjlist="196144" # 137128 547046 365343" #Space delimited list of subject IDs
else
	Subjlist=$@
	#Subjlist=$1
fi

StudyFolder="/home/range1-raid1/kjamison/Data/Phase2_7T" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script

# Requirements for this script
#  installed versions of: FSL5.0.2 or higher , FreeSurfer (version 5.2 or higher) , gradunwarp (python code from MGH)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript}

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"

########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the FreeSurfer Pipeline

######################################### DO WORK ##########################################

SessFolder="REST"

PEpos=PA
PEneg=AP

#Tasklist=(1_PA 2_AP 3_PA 4_AP)
#PhaseEncodinglist="y -y y -y"


#PA = +y,   AP = -y
#Tasklist=(REST1)
#PhaseEncodinglist="y -y y"

#Tasklist=(REST2 REST3 REST4)
#PhaseEncodinglist="-y y -y"

Tasklist=(REST1algo1 REST1algo2 REST1algo3 REST1algo4)
PhaseEncodinglist="y y y y"

for Subject in $Subjlist ; do
  i=0
 # for fMRIName in $Tasklist ; do

  for ii in ${!Tasklist[@]} ; do

    UnwarpDir=`echo $PhaseEncodinglist | cut -d " " -f $((ii+1))`    
    if [ ${UnwarpDir} == "y" ]; then
	PEdir=${PEpos}
    else
	PEdir=${PEneg}
    fi


    fMRIName="${SessFolder}_${Tasklist[$ii]}_${PEdir}"


    echo $Session$fMRIName
    LowResMesh="32" #Needs to match what is in PostFreeSurfer
    FinalfMRIResolution="1.6" #Needs to match what is in fMRIVolume
    SmoothingFWHM="1.6" #Recommended to be roughly the voxel size
    GrayordinatesResolution="2" #Needs to match what is in PostFreeSurfer. Could be the same as FinalfRMIResolution something different, which will call a different module for subcortical processing

    ${FSLDIR}/bin/fsl_sub $QUEUE \
      ${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh \
      --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$Session$fMRIName \
      --lowresmesh=$LowResMesh \
      --fmrires=$FinalfMRIResolution \
      --smoothingFWHM=$SmoothingFWHM \
      --grayordinatesres=$GrayordinatesResolution &

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

      echo "set -- --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$Session$fMRIName \
      --lowresmesh=$LowResMesh \
      --fmrires=$FinalfMRIResolution \
      --smoothingFWHM=$SmoothingFWHM \
      --grayordinatesres=$GrayordinatesResolution"

      echo ". ${EnvironmentScript}"
            
   done
done

