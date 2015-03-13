#!/bin/bash 

# Just give usage if no arguments specified
if [ $# -eq 0 ] 
then
	Subjlist="137128" # 547046 365343" #196144 #Space delimited list of subject IDs
else
	Subjlist=$@
fi


StudyFolder="/home/range1-raid1/kjamison/Data/Phase2_7T" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script
SessFolder="REST1"


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

#Scripts called by this script do NOT assume anything about the form of the input names or paths.
#This batch script assumes the HCP raw data naming convention, e.g. for tfMRI_EMOTION_LR and tfMRI_EMOTION_RL:

#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_tfMRI_EMOTION_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_tfMRI_EMOTION_LR_SBRef.nii.gz

#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_tfMRI_EMOTION_RL.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_tfMRI_EMOTION_RL_SBRef.nii.gz

#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz

#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz

#Change Scan Settings: Dwelltime, FieldMap Delta TE (if using), and $PhaseEncodinglist to match your images
#These are set to match the HCP Protocol by default

#If using gradient distortion correction, use the coefficents from your scanner
#The HCP gradient distortion coefficents are only available through Siemens
#Gradient distortion in standard scanners like the Trio is much less than for the HCP Skyra.

#To get accurate EPI distortion correction with TOPUP, the flags in PhaseEncodinglist must match the phase encoding
#direction of the EPI scan, and you must have used the correct images in SpinEchoPhaseEncodeNegative and Positive
#variables.  If the distortion is twice as bad as in the original images, flip either the order of the spin echo
#images or reverse the phase encoding list flag.  The pipeline expects you to have used the same phase encoding
#axis in the fMRI data as in the spin echo field map data (x/-x or y/-y).  

######################################### DO WORK ##########################################

dof_epi2t1=9

PEpos=PA
PEneg=AP

#Tasklist=(1_PA 2_AP 3_PA 4_AP)
#PhaseEncodinglist="y -y y -y"


#PA = +y,   AP = -y
Tasklist=(REST1)
PhaseEncodinglist="y -y y"

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

    niidir="${StudyFolder}/${Subject}/unprocessed/${SessFolder}"

    #sbfile=`ls ${niidir} | grep "BOLD_${Tasklist[$ii]}_${PEdir}_SBRef_fix\.*"`
    sbfile=`ls ${niidir} | grep "BOLD_${Tasklist[$ii]}_${PEdir}_SBRef\.*"`
    mbfile=`ls ${niidir} | grep "BOLD_${Tasklist[$ii]}_${PEdir}\.\.*"`
    sefilePos=`ls ${niidir} | grep "SE_${Tasklist[$ii]}_${PEpos}\.*"`
    sefileNeg=`ls ${niidir} | grep "SE_${Tasklist[$ii]}_${PEneg}\.*"`

    ###########################################
    #### make sure all images have even number of slices, otherwise topup will fail with subsamp 2

    for f in $sbfile $mbfile $sefilePos $sefileNeg
    do
	znum=`fslinfo ${niidir}/$f | grep '^dim3' | awk '{print $NF}'`
        if [[ $((znum % 2)) > 0 ]]; then
		znum2=$((znum-1))
            	niidir2="${niidir}/orig_${znum}"
		if [[ ! -d ${niidir2} ]]; then
			mkdir -p ${niidir2}
		fi

		echo "Odd slices (${znum}).  Removing bottom slice from ${niidir}/$f"
		mv -f ${niidir}/$f ${niidir2}/orig_${znum}.$f
		fslroi ${niidir2}/orig_${znum}.$f ${niidir}/$f 0 -1 0 -1 1 -1
	fi
    done
    ###########################################
    
    fMRITimeSeries="${niidir}/${mbfile}"
    #fMRISBRef="${niidir}/${sbfile}"
    fMRISBRef="NONE"

    DwellTime="0.00032" #Echo Spacing or Dwelltime of fMRI image
    DistortionCorrection="TOPUP" #FIELDMAP or TOPUP, distortion correction is required for accurate processing

    #For the spin echo field map volume with a negative phase encoding direction (LR in HCP data), set to NONE if using regular FIELDMAP
    #SpinEchoPhaseEncodeNegative="NONE" 
    SpinEchoPhaseEncodeNegative="${niidir}/${sefileNeg}" 

    #For the spin echo field map volume with a positive phase encoding direction (RL in HCP data), set to NONE if using regular FIELDMAP
    #SpinEchoPhaseEncodePositive="NONE"
    SpinEchoPhaseEncodePositive="${niidir}/${sefilePos}"

    #Expects 4D Magnitude volume with two 3D timepoints, set to NONE if using TOPUP
    MagnitudeInputName="NONE" 
    PhaseInputName="NONE" #Expects a 3D Phase volume, set to NONE if using TOPUP
    DeltaTE="NONE" #2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
    #FinalFMRIResolution="3.00" #Target final resolution of fMRI data. 2mm is recommended.  
    FinalFMRIResolution="1.60"
    #GradientDistortionCoeffs="/home/range2-raid1/anvu/data/raw/UPenn_coeff.grad" #Gradient distortion correction coefficents, set to NONE to turn off
    #GradientDistortionCoeffs="/home/range2-raid1/anvu/data/raw/7TAS_coeff.grad" #Gradient distortion correction coefficents, set to NONE to turn off
    GradientDistortionCoeffs="/home/range1-raid1/kjamison/Data/Pipelines/global/config/7TAS_coeff_SC72CD.grad" #Gradient distortion correction coefficents, set to NONE to turn off
    
    TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP

    # to use .nii for temp files (instead of nii.gz)
    TMP_FSLOUTPUTTYPE=NIFTI #MOCO only: temp files take up more space but runs faster

    ${FSLDIR}/bin/fsl_sub $QUEUE \
      ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
      --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$fMRIName \
      --fmritcs=$fMRITimeSeries \
      --fmriscout=$fMRISBRef \
      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
      --SEPhasePos=$SpinEchoPhaseEncodePositive \
      --fmapmag=$MagnitudeInputName \
      --fmapphase=$PhaseInputName \
      --echospacing=$DwellTime \
      --echodiff=$DeltaTE \
      --unwarpdir=$UnwarpDir \
      --fmrires=$FinalFMRIResolution \
      --dcmethod=$DistortionCorrection \
      --gdcoeffs=$GradientDistortionCoeffs \
      --topupconfig=$TopUpConfig \
      --dof=${dof_epi2t1} \
      --tempfiletype=${TMP_FSLOUTPUTTYPE} \
      --printcom=$PRINTCOM &


  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "set -- --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$fMRIName \
      --fmritcs=$fMRITimeSeries \
      --fmriscout=$fMRISBRef \
      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
      --SEPhasePos=$SpinEchoPhaseEncodePositive \
      --fmapmag=$MagnitudeInputName \
      --fmapphase=$PhaseInputName \
      --echospacing=$DwellTime \
      --echodiff=$DeltaTE \
      --unwarpdir=$UnwarpDir \
      --fmrires=$FinalFMRIResolution \
      --dcmethod=$DistortionCorrection \
      --gdcoeffs=$GradientDistortionCoeffs \
      --topupconfig=$TopUpConfig \
      --dof=$dof_epi2t1 \
      --tempfiletype=${TMP_FSLOUTPUTTYPE} \
      --printcom=$PRINTCOM"

  echo ". ${EnvironmentScript}"
	
  done
done


