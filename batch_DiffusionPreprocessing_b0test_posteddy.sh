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
b0type=$2

StudyFolder="/home/range1-raid1/kjamison/Data/Lifespan/b0test" #Location of Subject folders (named by subjectID)
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
  #SubjectID=`echo $Subject | awk -F_ '{print $1}'` #Subject ID Name
  SubjectID=$Subject
  #Scan Setings
  #EchoSpacing=0.78 #Echo Spacing or Dwelltime of dMRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.
  
	PEdir=2 #Use 1 for Left-Right Phase Encoding, 2 for Anterior-Posterior

  #Config Settings
  # Gdcoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" #Coefficients that describe spatial variations of the scanner gradients. Use NONE if not available.
  #Gdcoeffs="NONE" # Set to NONE to skip gradient distortion correction
  
	SubjectID_b0type=`echo ${SubjectID} | sed -r 's/_b0$/_'${b0type}'/'`

	RawDataDir="$StudyFolder/../${SubjectID}/unprocessed/b0recombine" #Folder where unprocessed diffusion data are
	Gdcoeffs="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners/CMRR_Prisma_coeff_AS82_20141111.grad"
	EchoSpacing="0.69" #Echo Spacing in msec for DWI (divided by 1000 in basic_preproc.sh)
	dof_epi2t1=6

	#dof_epi2t1=12

	#PEpos=RL
	#PEneg=LR
	#UnwarpAxis=x

	#!!!!!!!opposite of pos/neg for functional data  #now fixed
	PEpos=PA
	PEneg=AP

  # Data with positive Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (RL in HCP data, PA in 7T HCP data)
	PosData=`find -L ${RawDataDir} -type f | grep -iE '\.nii(\.gz)?$' | grep -E "DWI.*_${PEpos}[_\.]" | grep ${b0type} | sort | tr "\n" "@" | sed -r 's/@$//'`

  # Data with negative Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (LR in HCP data, AP in 7T HCP data)
  # If corresponding series is missing (e.g. 2 RL series and 1 LR) use EMPTY.
	NegData=`find -L ${RawDataDir} -type f | grep -iE '\.nii(\.gz)?$' | grep -E "DWI.*_${PEneg}[_\.]" | grep ${b0type} | sort | tr "\n" "@" | sed -r 's/@$//'`

  #Scan Setings
  #EchoSpacing=0.78 #Echo Spacing or Dwelltime of dMRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.
  #PEdir=2 #Use 1 for Left-Right Phase Encoding, 2 for Anterior-Posterior

  #Config Settings
  # Gdcoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" #Coefficients that describe spatial variations of the scanner gradients. Use NONE if not available.
  #Gdcoeffs="NONE" # Set to NONE to skip gradient distortion correction

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  echo ${queuing_command} ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
      --posData="${PosData}" --negData="${NegData}" \
      --path="${StudyFolder}" --subject="${SubjectID_b0type}" \
      --echospacing="${EchoSpacing}" --PEdir=${PEdir} \
      --gdcoeffs="${Gdcoeffs}" \
      --printcom=$PRINTCOM

PRINTCOM=
${queuing_command} ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PostEddy.sh \
--path=${StudyFolder} \
--subject=${SubjectID_b0type} \
--gdcoeffs=${Gdcoeffs} \
--dof=${dof_epi2t1} \
--printcom="${PRINTCOM}"

exit 0
    outdir=${StudyFolder}/${SubjectID_b0type}/Diffusion
    outdirT1w=${StudyFolder}/${SubjectID_b0type}/T1w/Diffusion

FSSubject=`echo ${SubjectID} | sed -r 's/_b0$/_3T/'`
#FSSubject=LSKJ_3T
DegreesOfFreedom=${dof_epi2t1}
GdFlag=1

    DiffRes=`${FSLDIR}/bin/fslval ${outdir}/data/data pixdim1`
    DiffRes=`printf "%0.2f" ${DiffRes}`




    T1wFolder="${StudyFolder}/${SubjectID_b0type}/T1w" #Location of T1w images
    T1wImage="${T1wFolder}/T1w_acpc_dc"
    T1wRestoreImage="${T1wFolder}/T1w_acpc_dc_restore"
    T1wRestoreImageBrain="${T1wFolder}/T1w_acpc_dc_restore_brain"
    BiasField="${T1wFolder}/BiasField_acpc_dc"
    FreeSurferBrainMask="${T1wFolder}/brainmask_fs"
    RegOutput="${outdir}"/reg/"Scout2T1w"
    QAImage="${outdir}"/reg/"T1wMulEPI"
    DiffRes=`${FSLDIR}/bin/fslval ${outdir}/data/data pixdim1`
    DiffRes=`printf "%0.2f" ${DiffRes}`

    log_Msg "Running Diffusion to Structural Registration"
    ${runcmd} ${HCPPIPEDIR_dMRI}/DiffusionToStructural.sh \
        --t1folder="${T1wFolder}" \
        --subject="${FSSubject}" \
        --workingdir="${outdir}/reg" \
        --datadiffdir="${outdir}/data" \
        --t1="${T1wImage}" \
        --t1restore="${T1wRestoreImage}" \
        --t1restorebrain="${T1wRestoreImageBrain}" \
        --biasfield="${BiasField}" \
        --brainmask="${FreeSurferBrainMask}" \
        --datadiffT1wdir="${outdirT1w}" \
        --regoutput="${RegOutput}" \
        --QAimage="${QAImage}" \
        --dof="${DegreesOfFreedom}" \
        --gdflag=${GdFlag} \
        --diffresol=${DiffRes}

done

