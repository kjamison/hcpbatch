#!/bin/bash

Subject_all=$1
ScanName_all=$2

#ScanName = eg REST1_PA

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

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"

######################################### DO WORK ##########################################

for Subject in $Subject_all; do

    for ScanName in $ScanName_all; do

        TaskName=`echo ${ScanName} | sed 's/_[APLR]\+$//'`

        SessFolder=`echo ${ScanName} | sed 's/[0-9]\+_[APLR]\+$//'`

        dof_epi2t1=12

        PEpos=PA
        PEneg=AP

        if [[ ${ScanName} == *_${PEpos} ]]; then
	        PEdir=${PEpos}
	        UnwarpDir=y
        elif [[ ${ScanName} == *_${PEneg} ]]; then
	        PEdir=${PEneg}
	        UnwarpDir=-y
        else
	        echo "unknown PE direction: "${ScanName}
	        exit 0
        fi



        fMRIName="${SessFolder}_${ScanName}"

        niidir="${StudyFolder}/${Subject}/unprocessed/${SessFolder}"

        sbfile_full=`imfind ${niidir}/BOLD_${TaskName}_${PEdir}_SBRef`
        mbfile_full=`imfind ${niidir}/BOLD_${TaskName}_${PEdir}`
        sefilePos_full=`imfind ${niidir}/SE_${TaskName}_${PEpos}`
        sefileNeg_full=`imfind ${niidir}/SE_${TaskName}_${PEneg}`

        if [ X${sbfile_full} == X ]; then
            echo "missing sbfile for: "${Subject} ${ScanName} 1>&2
            continue
        elif [ X${mbfile_full} == X ]; then
            echo "missing mbfile for: "${Subject} ${ScanName} 1>&2
            continue
        elif [ X${sefilePos_full} == X ]; then
            echo "missing SE for: "${Subject} ${ScanName} 1>&2
            continue
        elif [ X${sefileNeg_full} == X ]; then
            echo "missing SE for: "${Subject} ${ScanName} 1>&2
            continue
        fi

        sbfile=`basename ${sbfile_full}`
        mbfile=`basename ${mbfile_full}`
        sefilePos=`basename ${sefilePos_full}`
        sefileNeg=`basename ${sefileNeg_full}`
        ###########################################
        #### make sure all images have even number of slices, otherwise topup will fail with subsamp 2

        if (( $StartWithIdx <= $idxDcm && $EndWithIdx >= $idxDcm )); then

            echo "Starting evenslice check: $Subject $ScanName $StartWith $EndWith"

            for f in $sbfile $sefilePos $sefileNeg $mbfile 
            do
                bash hcpkj_run_evenslices.sh ${niidir}/$f
            done

        fi
        ###########################################

        mbfile=`imfind ${niidir}/${mbfile}`
        sbfiles=`imfind ${niidir}/${sbfile}`
        sefileNeg=`imfind ${niidir}/${sefileNeg}`
        sefilePos=`imfind ${niidir}/${sefilePos}`

        fMRITimeSeries="${mbfile}"

        #################################################################
        ############### Volume Pipeline Options ########################

            #fMRISBRef="${sbfile}"
            fMRISBRef="NONE"

            DwellTime="0.00032" #Echo Spacing or Dwelltime of fMRI image
            DistortionCorrection="TOPUP" #FIELDMAP or TOPUP, distortion correction is required for accurate processing

            #For the spin echo field map volume with a negative phase encoding direction (LR in HCP data), set to NONE if using regular FIELDMAP
            #SpinEchoPhaseEncodeNegative="NONE" 
            SpinEchoPhaseEncodeNegative="${sefileNeg}" 

            #For the spin echo field map volume with a positive phase encoding direction (RL in HCP data), set to NONE if using regular FIELDMAP
            #SpinEchoPhaseEncodePositive="NONE"
            SpinEchoPhaseEncodePositive="${sefilePos}"

            #Expects 4D Magnitude volume with two 3D timepoints, set to NONE if using TOPUP
            MagnitudeInputName="NONE" 
            PhaseInputName="NONE" #Expects a 3D Phase volume, set to NONE if using TOPUP
            DeltaTE="NONE" #2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
            #FinalFMRIResolution="3.00" #Target final resolution of fMRI data. 2mm is recommended.  
            FinalFMRIResolution="1.60"

            GradientDistortionCoeffs="/home/range1-raid1/kjamison/Data/Pipelines/global/config/7TAS_coeff_SC72CD.grad" #Gradient distortion correction coefficents, set to NONE to turn off
            
            TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP

            # to use .nii for temp files (instead of nii.gz)
            TMP_FSLOUTPUTTYPE=NIFTI #MOCO only: temp files take up more space but runs faster


        #################################################################
        ############### Surface Pipeline Options ########################
            LowResMesh="32" #Needs to match what is in PostFreeSurfer
            #SmoothingFWHM="1.6" #Recommended to be roughly the voxel size
            SmoothingFWHM=${FinalFMRIResolution}
            GrayordinatesResolution="2" #Needs to match what is in PostFreeSurfer. Could be the same as FinalfRMIResolution something different, which will call a different module for subcortical processing

        #################################################################
        ############### HPF/Melodic Options ########################
        HPF=2000
        AtlasSpaceFolder="MNINonLinear"
        ResultsFolder="Results"

        subjAtlasSpaceFolder="${StudyFolder}"/"${Subject}"/"${AtlasSpaceFolder}"
        subjResultsFolder="${subjAtlasSpaceFolder}"/"${ResultsFolder}"/"${fMRIName}"

        #################################################################
        ############### Run Volume Pipeline #############################

            echo "Starting volume pipeline: $Subject $ScanName"

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
              --printcom=$PRINTCOM


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
              --dof=${dof_epi2t1} \
              --tempfiletype=${TMP_FSLOUTPUTTYPE} \
              --printcom=$PRINTCOM"

          echo ". ${EnvironmentScript}"

        #################################################################
        ############### Run Surface Pipeline #############################

            echo "Starting surface pipeline: $Subject $ScanName"

            ${FSLDIR}/bin/fsl_sub $QUEUE \
              ${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh \
              --path=$StudyFolder \
              --subject=$Subject \
              --fmriname=$Session$fMRIName \
              --lowresmesh=$LowResMesh \
              --fmrires=$FinalfMRIResolution \
              --smoothingFWHM=$SmoothingFWHM \
              --grayordinatesres=$GrayordinatesResolution


              echo "set -- --path=$StudyFolder \
              --subject=$Subject \
              --fmriname=$Session$fMRIName \
              --lowresmesh=$LowResMesh \
              --fmrires=$FinalfMRIResolution \
              --smoothingFWHM=$SmoothingFWHM \
              --grayordinatesres=$GrayordinatesResolution"

              echo ". ${EnvironmentScript}"

        #################################################################
        ############### Run melodic+post #############

            echo "Starting hcp_fix: $Subject $ScanName"

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

            echo $Session$fMRIName

            ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE \
              ${FSL_FIXDIR}/hcp_fix \
              ${fMRIfile} \
              ${HPF}

    done
done
