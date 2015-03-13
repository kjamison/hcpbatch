#!/bin/bash 

#Subjlist="792564" #Space delimited list of subject IDs
#StudyFolder="/media/myelin/brainmappers/Connectome_Project/TestStudyFolder" #Location of Subject folders (named by subjectID)
#EnvironmentScript="/media/2TBB/Connectome_Project/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script

Subjlist=$1 #Space delimited list of subject IDs
StudyFolder="/home/range1-raid1/kjamison/Data/mayo_data" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script


# Requirements for this script
#  installed versions of: FSL5.0.2 or higher , FreeSurfer (version 5.2 or higher) , gradunwarp (python code from MGH)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript} &> /dev/null

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline

######################################### DO WORK ##########################################

for Subject in $Subjlist ; do
  #Input Variables
  SubjectID="$Subject" #FreeSurfer Subject ID Name
  SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  #T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)
  T2wImage=

  #hack to try and avoid freesurfer skullstripping problems
  T1wImage=${T1wImageBrain}

  T2wImage=${T1wImage}

  #${FSLDIR}/bin/fsl_sub ${QUEUE} \
  #   ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
  ${FSLDIR}/bin/fsl_sub ${QUEUE} \
      /home/range1-raid1/kjamison/hcp_pipeline/FreeSurferPipeline_hires.sh \
      --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --printcom=$PRINTCOM
      
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "set -- --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --printcom=$PRINTCOM"

  echo ". ${EnvironmentScript}"

done

