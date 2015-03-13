#!/bin/bash 

# Just give usage if no arguments specified
if [ $# -eq 0 ] 
then
	echo `basename $0` "<subjid1> <subjid2> ..."
	exit 0
	#Subjlist="178142 899885 901139 205220 214019"
	#Subjlist="137128 547046 365343" #"196144" #Space delimited list of subject IDs
else
	Subjlist=$@
fi

StudyFolder="/home/range1-raid1/kjamison/Data2/Phase2_7T" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script

# Requirements for this script
#  installed versions of: FSL5.0.2 or higher , FreeSurfer (version 5.2 or higher) , gradunwarp (python code from MGH)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript}

FSL_FIXDIR="/home/range1-raid1/kjamison/Data/fix1.06"
export FSL_FIXDIR

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

RUN=""
#RUN="echo"
#QUEUE="-q veryshort.q"

########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the FreeSurfer Pipeline

######################################### DO WORK ##########################################

SessFolder="REST"

HPF=2000

PEpos=PA
PEneg=AP

#Tasklist=(1_PA 2_AP 3_PA 4_AP)
#PhaseEncodinglist="y -y y -y"

AtlasSpaceFolder="MNINonLinear"
ResultsFolder="Results"

#PA = +y,   AP = -y
#Tasklist=(REST1)
#PhaseEncodinglist="y -y y"

Tasklist=(REST1 REST2 REST3 REST4)
PhaseEncodinglist="y -y y -y"

#Tasklist=(REST2 REST3 REST4 REST1algo1 REST1algo2 REST1algo3 REST1algo4)
#PhaseEncodinglist="-y y -y y y y y"

for Subject in $Subjlist ; do
  i=0
 # for fMRIName in $Tasklist ; do

  for ii in ${!Tasklist[@]} ; do

    UnwarpDir=`echo $PhaseEncodinglist | cut -d " " -f $((ii+1))`    
    if [ ${UnwarpDir} == "y" ]; then
	PEdir=${PEpos}
    elif [ ${UnwarpDir} == "-y" ]; then
	PEdir=${PEneg}
    else
	echo "unrecognized phase encode direction: '${UnwarpDir}'"
	exit 0
    fi

    fMRIName="${SessFolder}_${Tasklist[$ii]}_${PEdir}"

    subjAtlasSpaceFolder="${StudyFolder}"/"${Subject}"/"${AtlasSpaceFolder}"
    subjResultsFolder="${subjAtlasSpaceFolder}"/"${ResultsFolder}"/"${fMRIName}"

    fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

    if [ -z $fMRIfile ]; then
	echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	continue
    fi

    echo $Session$fMRIName
    date > ${subjResultsFolder}/hpfstart.txt

    ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE \
      ${FSL_FIXDIR}/hcp_fix \
      ${fMRIfile} \
      ${HPF} &

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

      echo "set -- ${subjResultsFolder}/${fMRIName} \
      ${HPF}"

      echo ". ${EnvironmentScript}"
            
   done
done

