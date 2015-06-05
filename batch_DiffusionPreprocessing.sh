#!/bin/bash 

get_batch_options() {
    local arguments=($@)

    unset command_line_specified_study_folder
    unset command_line_specified_subj_list
    unset command_line_specified_run_local

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --Subjlist=*)
                command_line_specified_subj_list=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
            *) 
                index=$(( index + 1 ))
                ;;
        esac
    done
}

get_batch_options $@

#################################################
STUDYNAME=$1; shift

Subjlist=$1

################
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${SCRIPTDIR}/batch_StudySettings.sh `echo $STUDYNAME | tr "@" " "`
if [ -z ${StudyFolder} ]; then
  exit 1
fi
##############

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj_list}" ]; then
    Subjlist="${command_line_specified_subj_list}"
fi

# Log the originating call
echo "$@"

#Assume that submission nodes have OPENMP enabled (needed for eddy - at least 8 cores suggested for HCP data)
#if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q verylong.q"
#fi

PRINTCOM=""


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline,
#which is a prerequisite for this pipeline

#Scripts called by this script do NOT assume anything about the form of the input names or paths.
#This batch script assumes the HCP raw data naming convention, e.g.

#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir95_RL.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir96_RL.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir97_RL.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir95_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir96_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_DWI_dir97_LR.nii.gz

#Change Scan Settings: Echo Spacing and PEDir to match your images
#These are set to match the HCP Protocol by default

#If using gradient distortion correction, use the coefficents from your scanner
#The HCP gradient distortion coefficents are only available through Siemens
#Gradient distortion in standard scanners like the Trio is much less than for the HCP Skyra.

######################################### DO WORK ##########################################

for Subject in $Subjlist ; do

	echo $Subject

	UnprocDir="${StudyFolder}/${Subject}/unprocessed/Diffusion"

	#Use 1 for Left-Right Phase Encoding, 2 for Anterior-Posterior
	if [[ ${UnwarpAxis} == y ]]; then
		PEdir=2
		#pos/neg hardcoded in diffusion, so make sure studysettings didn't swap them
		PEpos=PA
		PEneg=AP
	else
		PEdir=1
		PEpos=RL
		PEneg=LR
	fi

	#EchoSpacing must be in ms for diffusion pipeline
	EchoSpacing=`echo "scale=6; ${DWIDwellTime}*1000" | bc`

	# Data with positive Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (RL in HCP data, PA in 7T HCP data)
	PosData=`find -L ${UnprocDir} -type f | grep -iE '\.nii(\.gz)?$' | grep -E "DWI.*_${PEpos}[_\.]" | sort | tr "\n" "@" | sed -r 's/@$//'`

	# Data with negative Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (LR in HCP data, AP in 7T HCP data)
	# If corresponding series is missing (e.g. 2 RL series and 1 LR) use EMPTY.
	NegData=`find -L ${UnprocDir} -type f | grep -iE '\.nii(\.gz)?$' | grep -E "DWI.*_${PEneg}[_\.]" | sort | tr "\n" "@" | sed -r 's/@$//'`


  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE} ${FSLSUBOPTIONS}"
  fi

  ${queuing_command} ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
      --posData="${PosData}" --negData="${NegData}" \
      --path="${StudyFolder}" --subject="${Subject}" \
      --echospacing="${EchoSpacing}" --PEdir=${PEdir} \
      --gdcoeffs="${GradientDistortionCoeffs}" \
      --dof="${DOF_EPI2T1}" \
      --printcom=$PRINTCOM

done

