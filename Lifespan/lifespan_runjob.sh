#!/bin/bash

Subject_all=$1
ScanName_all=$2
StartWith=`echo $3 dcm2nii | awk '{print $1}'`
EndWith=`echo $4 melodic | awk '{print $1}'`

#ScanName = eg REST1_PA
#startwith = dcm2nii , init gdc mc dc resample norm results , surface, hpf, melodic

StudyFolder="/home/range1-raid1/kjamison/Data/Lifespan" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script

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

##############################################################################################
idxDcm=0
idxInit=1
idxGdc=2
idxMc=3
idxDc=4
idxResample=5
idxNorm=6
idxResults=7
idxSurface=8
idxHpf=9
idxMelodic=10
idxPostfix=11

#default run all
StartWithIdx=$idxDcm
EndWithIdx=$idxMelodic

case $StartWith in
	 dcm2nii )
		StartWithIdx=$idxDcm;;
	 init )
		StartWithIdx=$idxInit;;
	 gdc )
		StartWithIdx=$idxGdc;;
	 mc )
		StartWithIdx=$idxMc;;
	 dc )
		StartWithIdx=$idxDc;;
	 resample )
		StartWithIdx=$idxResample;;
	 norm )
		StartWithIdx=$idxNorm;;
	 results )
		StartWithIdx=$idxResults;;
	 surface )
		StartWithIdx=$idxSurface;;
	 hpf )
		StartWithIdx=$idxHpf;;
	 melodic )
		StartWithIdx=$idxMelodic;;
	 postfix )
		StartWithIdx=$idxPostfix;;
     * )
        echo "Unknown StartWith: $StartWith"
        exit 0;;
esac

case $EndWith in
	 dcm2nii )
		EndWithIdx=$idxDcm;;
	 init )
		EndWithIdx=$idxInit;;
	 gdc )
		EndWithIdx=$idxGdc;;
	 mc )
		EndWithIdx=$idxMc;;
	 dc )
		EndWithIdx=$idxDc;;
	 resample )
		EndWithIdx=$idxResample;;
	 norm )
		EndWithIdx=$idxNorm;;
	 results )
		EndWithIdx=$idxResults;;
	 surface )
		EndWithIdx=$idxSurface;;
	 hpf )
		EndtWithIdx=$idxHpf;;
	 melodic )
		EndWithIdx=$idxMelodic;;
	 postfix )
		EndWithIdx=$idxPostfix;;
     * )
        echo "Unknown EndWith: $EndWith"
        exit 0;;
esac

######################################### DO WORK ##########################################

for Subject in $Subject_all; do

    for ScanName in $ScanName_all; do

        TaskName=`echo ${ScanName} | sed 's/_[APLR]\+$//'`

        SessFolder=`echo ${ScanName} | sed 's/[0-9]\+_[APLR]\+$//'`

        dof_epi2t1=12

        #PEpos=RL
        #PEneg=LR
	#UnwarpAxis=x

        PEpos=PA
        PEneg=AP
	UnwarpAxis=y

        if [[ ${ScanName} == *_${PEpos} ]]; then
	        PEdir=${PEpos}
	        UnwarpDir=${UnwarpAxis}
        elif [[ ${ScanName} == *_${PEneg} ]]; then
	        PEdir=${PEneg}
	        UnwarpDir="-${UnwarpAxis}"
        else
	        echo "unknown PE direction: "${ScanName}
	        exit 0
        fi


        fMRIName="${ScanName}"

        niidir="${StudyFolder}/${Subject}/unprocessed/${ScanName}"

        #sbfile=`ls ${niidir} | grep "BOLD_${Tasklist[$ii]}_${PEdir}_SBRef_fix\.*"`
        sbfile_full=`imfind ${niidir}/BOLD_${TaskName}_${PEdir}_SBRef`
        mbfile_full=`imfind ${niidir}/BOLD_${TaskName}_${PEdir}`
        sefilePos_full=`imfind ${niidir}/SE_${TaskName}_${PEpos}`
        sefileNeg_full=`imfind ${niidir}/SE_${TaskName}_${PEneg}`

        if [ X${sbfile_full} == X ]; then
            echo "missing sbfile for: "${Subject} ${ScanName} 1>&2
            continue
            #exit 0
        elif [ X${mbfile_full} == X ]; then
            echo "missing mbfile for: "${Subject} ${ScanName} 1>&2
            continue
            #exit 0
        elif [ X${sefilePos_full} == X ]; then
            echo "missing SE for: "${Subject} ${ScanName} 1>&2
            continue
            #exit 0
        elif [ X${sefileNeg_full} == X ]; then
            echo "missing SE for: "${Subject} ${ScanName} 1>&2
            continue
            #exit 0
        fi

        sbfile=`basename ${sbfile_full}`
        mbfile=`basename ${mbfile_full}`
        sefilePos=`basename ${sefilePos_full}`
        sefileNeg=`basename ${sefileNeg_full}`
        ###########################################
        #### make sure all images have even number of slices, otherwise topup will fail with subsamp 2

        #echo "$sbfile_full $sefilePos_full $sefileNeg_full $mbfile_full"
        #continue

        if (( $StartWithIdx <= $idxDcm && $EndWithIdx >= $idxDcm )); then

	    echo "Starting fslreorient2std: $Subject $ScanName $StartWith $EndWith"
            for f in $sbfile $sefilePos $sefileNeg $mbfile 
            do
                fslreorient2std_inplace ${niidir}/$f
            done

            echo "Starting evenslice check: $Subject $ScanName $StartWith $EndWith"

            for f in $sbfile $sefilePos $sefileNeg $mbfile 
            do
                bash `dirname $0`/hcpkj_run_evenslices.sh ${niidir}/$f
            done

	   StartWithIdx=$idxInit
        fi

        ###########################################

        mbfile=`imfind ${niidir}/${mbfile}`
        sbfile=`imfind ${niidir}/${sbfile}`
        sefileNeg=`imfind ${niidir}/${sefileNeg}`
        sefilePos=`imfind ${niidir}/${sefilePos}`

        fMRITimeSeries="${mbfile}"

        #################################################################
        ############### Volume Pipeline Options ########################

            #fMRISBRef="${sbfile}"
            fMRISBRef="NONE"

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

	if [[ ${Subject} == *_3T* ]]; then
		GradientDistortionCoeffs="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners/CMRR_Prisma_coeff_AS82_20141111.grad"
		FinalFMRIResolution=2.00
		DwellTime="0.00058" #Echo Spacing or Dwelltime of fMRI image
	elif [[ ${Subject} == *_7T* ]]; then
		GradientDistortionCoeffs="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners/CMRR_7TAS_coeff_SC72CD_20141111.grad"
		FinalFMRIResolution=1.60
		DwellTime="0.00032" #Echo Spacing or Dwelltime of fMRI image
	fi
            
            TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP

            # to use .nii for temp files (instead of nii.gz)
            TMP_FSLOUTPUTTYPE=NIFTI #MOCO only: temp files take up more space but runs faster

            # init gdc mc dc resample norm results
            #StartWith="init"
            #EndWith="init"
            #EndWith="mc"
            #EndWith="results"
            #StartWith="resample"
            #EndWith="results"

            #DistortionCorrection="ALREADYDONE"
            
            #StartWith="dc"
            #EndWith="dc"
            #EndWith="resample"

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

        if (( $StartWithIdx >= $idxInit && $EndWithIdx >= $idxInit )); then

            echo "Starting volume pipeline: $Subject $ScanName $StartWith $EndWith"

            StartWith_volproc=$StartWith
            EndWith_volproc=$EndWith

            if [[ $StartWithIdx < $idxInit ]]; then
                StartWith_volproc=init
            fi

            if [[ $EndWithIdx > $idxResults ]]; then
                EndWith_volproc=results
            fi

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
              --startwith=${StartWith_volproc} \
              --endwith=${EndWith_volproc} \
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
        fi

        #################################################################
        ############### Run Surface Pipeline #############################
        if (( $StartWithIdx <= $idxSurface && $EndWithIdx >= $idxSurface )); then

            echo "Starting surface pipeline: $Subject $ScanName $StartWith $EndWith"

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
        fi

        #################################################################
        ############### Run High-pass filter #############


        if (( $StartWithIdx <= $idxHpf && $EndWithIdx >= $idxHpf )); then

            echo "Starting hcp_fix HPF: $Subject $ScanName"

            StartWith_fix=hpf
            EndWith_fix=hpf

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

            echo $Session$fMRIName

            ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE \
              ${FSL_FIXDIR}/hcp_fix \
              ${fMRIfile} \
              ${HPF} \
              ${StartWith_fix} \
              ${EndWith_fix} 

        fi

        #################################################################
        ############### Run melodic+post #############


        if (( $StartWithIdx <= $idxMelodic && $EndWithIdx >= $idxMelodic )); then

            echo "Starting hcp_fix: $Subject $ScanName"

            StartWith_fix=melodic
            EndWith_fix=final

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

            echo $Session$fMRIName

            ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE \
              ${FSL_FIXDIR}/hcp_fix \
              ${fMRIfile} \
              ${HPF} \
              ${StartWith_fix} \
              ${EndWith_fix} 

        fi

        #################################################################
        ############### Run post-melodic steps for crashed jobs #############

        if (( $StartWithIdx <= $idxPostfix && $EndWithIdx >= $idxPostfix )); then

            echo "Starting hcp_fix_post: $Subject $ScanName $StartWith $EndWith"

            StartWith_fix=$StartWith
            EndWith_fix=$EndWith

            if [[ $StartWithIdx < $idxHpf ]]; then
                StartWith_fix=hpf
            fi

            if [[ $EndWithIdx > $idxMelodic ]]; then
                EndWith_fix=melodic
            fi

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

	    tmpdir=`echo ${subjResultsFolder} | sed 's/Phase2_7T/fixtrain/'`
	    mkdir -p ${tmpdir}
	    tmp_fMRIfile=${tmpdir}/`basename ${fMRIfile}`
	    if [ ! -e ${tmp_fMRIfile} ]; then
	    	ln -s ${fMRIfile} ${tmp_fMRIfile}
	    fi
            echo $Session$fMRIName

            ${RUN} ${FSL_FIXDIR}/hcp_fix_post \
              ${tmp_fMRIfile} \
              ${HPF} \
	      ${fMRIfile}

        fi
    done
done
