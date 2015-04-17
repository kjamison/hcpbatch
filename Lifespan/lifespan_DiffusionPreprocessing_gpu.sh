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

Subjlist=$1
StudyFolder="/home/range1-raid1/kjamison/Data/Lifespan" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/Source/BatchPipeline/SetUpHCPPipeline.sh" #Pipeline environment script

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj_list}" ]; then
    Subjlist="${command_line_specified_subj_list}"
fi

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP) , gradunwarp (HCP version 1.0.2)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript} &> /dev/null

FSL_FIXDIR="/home/range1-raid1/kjamison/Data/fix1.06"
export FSL_FIXDIR

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

  #Input Variables
  SubjectID=`echo $Subject | awk -F_ '{print $1}'` #Subject ID Name

  subjdir="$StudyFolder/$SubjectID/Diffusion_gpu"

	if [[ ${Subject} == *_3T* ]]; then
  	RawDataDir="$StudyFolder/$SubjectID/unprocessed/3T/Diffusion" #Folder where unprocessed diffusion data are
		Gdcoeffs="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners/CMRR_Prisma_coeff_AS82_20141111.grad"
		EchoSpacing="0.69" #Echo Spacing in msec for DWI (divided by 1000 in basic_preproc.sh)
	elif [[ ${Subject} == *_7T* ]]; then
  	RawDataDir="$StudyFolder/$SubjectID/unprocessed/7T/Diffusion" #Folder where unprocessed diffusion data are
		Gdcoeffs="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners/CMRR_7TAS_coeff_SC72CD_20141111.grad"
		EchoSpacing="0.25" #Echo Spacing in msec for DWI (divided by 1000 in basic_preproc.sh)
	fi

	dof_epi2t1=12

  rawdir=${subjdir}/rawdata
  topupdir=${subjdir}/topup
  eddydir=${subjdir}/eddy

  mkdir -p ${rawdir}
  mkdir -p ${topupdir}
  mkdir -p ${eddydir}

	bash ./basic_preproc_merge_gpu.sh ${subjdir} ${RawDataDir} ${EchoSpacing} 30
	#bash ./run_topup_eddy_gpu.sh ${subjdir} 0.2
	#bash ./run_postproc_gpu.sh ${subjdir} 0.05

	#bedpostx_gpu ${subjdir}/data -n 3 --rician


done

