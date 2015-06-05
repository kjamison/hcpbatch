#!/bin/bash

#############################################################################################
function display_help {
	cmdname=`basename $0`
	echo -e "\033[0;31m
  $cmdname <WHICHSTUDY>@<WHICHSCANNER> <Subject(s)> <ScanName(s)> \\
    [<StartWith>] [<EndWith>]

  $cmdname Lifespan@Prisma LS7000 rfMRI_REST1_PA
  $cmdname Lifespan@Prisma \"LS7000 LS7001\" \"rfMRI_REST1_PA rfMRI_REST1_AP\"

  <StartWith> and <EndWith> can be: 
    unproc   = fslreorient2std and make inputs have even slices for topup
    init     = Create directories and copy/reorient files from /unprocessed
    gdc      = Gradient distortion correction
    moco     = Motion correction
    dc       = Readout distortion correction (topup, etc...) and reg to anatomy
    resample = One-step Resampling
    norm     = Intensity normalization (mean=10000) and bias correction 
    results  = Copying main outputs into MNINonlinear
    surface  = Volume-to-surface mapping, create dtseries, etc...
    hpf      = High-pass filter at 2000sec
    fix      = melodic ICA decomposition + FIX denoising
  ( postica  = Run post-melodic steps in FIX... in case job crashed )
\033[0m"
}

if [ $# -lt 3 ]; then
	display_help
	exit 0
fi
#############################################################################################

# Log the originating call
echo "$@"

STUDYNAME=$1; shift

Subject_all=$1; shift;
ScanName_all=$1; shift;
if [[ "$1" == --echospacing=* ]]; then
	NewEchoSpacing=`echo $1 | sed 's/--echospacing=//'`
	shift;
fi
StartWith=`echo $1 unproc | awk '{print $1}'`
EndWith=`echo $2 fix | awk '{print $1}'`

################
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${SCRIPTDIR}/batch_StudySettings.sh `echo $STUDYNAME | tr "@" " "`
if [ -z ${StudyFolder} ]; then
  exit 1
fi
##############



if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"

##############################################################################################
idxUnproc=0
idxInit=1
idxGdc=2
idxMc=3
idxDc=4
idxResample=5
idxNorm=6
idxResults=7
idxSurface=8
idxHpf=9
idxFix=10
idxPostIca=11

surfaceRes1=

#default run all
StartWithIdx=$idxUnproc
EndWithIdx=$idxFix

case $StartWith in
	 unproc )
		StartWithIdx=$idxUnproc;;
	 init )
		StartWithIdx=$idxInit;;
	 gdc )
		StartWithIdx=$idxGdc;;
	 mc|moco )
		StartWithIdx=$idxMc;;
	 dc )
		StartWithIdx=$idxDc;;
	 resample )
		StartWithIdx=$idxResample;;
	 norm )
		StartWithIdx=$idxNorm;;
	 results )
		StartWithIdx=$idxResults;;
	 surf|surface )
		StartWithIdx=$idxSurface;;
	 surf@*|surface@* )
		StartWithIdx=$idxSurface
		surfaceRes1=`echo $StartWith | cut -d@ -f2`
		;;
	 hpf )
		StartWithIdx=$idxHpf;;
	 fix )
		StartWithIdx=$idxFix;;
	 postica )
		StartWithIdx=$idxPostIca;;
     * )
        echo "Unknown StartWith: $StartWith"
        exit 0;;
esac

case $EndWith in
	 unproc )
		EndWithIdx=$idxUnproc;;
	 init )
		EndWithIdx=$idxInit;;
	 gdc )
		EndWithIdx=$idxGdc;;
	 mc|moco )
		EndWithIdx=$idxMc;;
	 dc )
		EndWithIdx=$idxDc;;
	 resample )
		EndWithIdx=$idxResample;;
	 norm )
		EndWithIdx=$idxNorm;;
	 results )
		EndWithIdx=$idxResults;;
	 surf|surface )
		EndWithIdx=$idxSurface;;
	 hpf )
		EndtWithIdx=$idxHpf;;
	 fix )
		EndWithIdx=$idxFix;;
	 postica )
		EndWithIdx=$idxPostIca;;
     * )
        echo "Unknown EndWith: $EndWith"
        exit 0;;
esac

case $surfaceRes1 in
	32|32k )
		
		export GrayordinatesResolution=${GrayordinatesResolution_32k} 
		export LowResMesh=${LowResMesh_32k} 
		export GrayordinatesTemplate=${GrayordinatesTemplate_32k}
		export GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/${GrayordinatesTemplate}"
		;;
	59|59k )
		export GrayordinatesResolution=${GrayordinatesResolution_59k} 
		export LowResMesh=${LowResMesh_59k} 
		export GrayordinatesTemplate=${GrayordinatesTemplate_59k}
		export GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/${GrayordinatesTemplate}"
		;;
	164|164k )
		export GrayordinatesResolution=${GrayordinatesResolution_59k} 
		export LowResMesh=164
		export GrayordinatesTemplate=
		export GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/${GrayordinatesTemplate}"
		;;
	* ) 
		;;
esac

######################################### DO WORK ##########################################

for Subject in $Subject_all; do

    for ScanName in $ScanName_all; do

	#ScanName: REST1_AP MOVIE2_PA RET5_AP
	#TaskName: REST1 MOVIE2 RET5
	#TaskType: REST MOVIE RET

	#unprocessed niftis should be in eg: <subjdir>/unprocessed/REST
	#expecting format BOLD_REST1_AP, SE_REST1_AP (+PA), FM_REST1_Fieldmap_Phs (+Mag)
	#in intradb:
	#<subj>_7T_rfMRI_REST1_AP, <subj>_7T_SpinEchoFieldMap_AP
	#
	#possibly: rfMRI_REST1_AP, rfMRI_REST1_AP_SBRef, SE_REST1_AP, SE_REST1_PA, 
	#just replace "BOLD" in here and in dicom_init with REST*->rfMRI, MOVIE|RET*->tfMRI 

        TaskName=`echo ${ScanName} | sed -r 's/_[APLR]+$//'`
        TaskType=`echo ${ScanName} | sed -r 's/[0-9]+(_[APLR]+)?$//'`


	TaskPrefix=
	case `echo $TaskType | tr "[a-z]" "[A-Z]"` in
		RFMRI_*|TFMRI_* )
			TaskPrefix=`echo ${TaskName} | sed -r 's/^([tr]fMRI_).+/\1/i'`
			ScanName=`echo ${ScanName} | sed -r 's/^[tr]fMRI_//i'`
			TaskName=`echo ${TaskName} | sed -r 's/^[tr]fMRI_//i'`
			TaskType=`echo ${TaskType} | sed -r 's/^[tr]fMRI_//i'`
			;;
		REST* )
			TaskPrefix=rfMRI_;;
		RET* )
			TaskPrefix=tfMRI_;;
		MOVIE* )
			TaskPrefix=tfMRI_;;
		* )
			TaskPrefix=
			;;
	esac

	#unprocdir="${StudyFolder}/${Subject}/unprocessed/${TaskType}"
	unprocdir="${StudyFolder}/${Subject}/unprocessed/${TaskPrefix}${ScanName}"

	if [[ ${ScanName} = *_AP || ${ScanName} = *_PA ]]; then
		UnwarpAxis=y
		PEpos=${PEpos_y}
		PEneg=${PEneg_y}
	elif [[ ${ScanName} = *_RL || ${ScanName} = *_LR ]]; then
		UnwarpAxis=x
		PEpos=${PEpos_x}
		PEneg=${PEneg_x}
	else
		printf "Unknown PE direction: %s\n" `basename ${ScanName}`
		exit 0
	fi

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

        sbfile_full=`imfind ${unprocdir}/${TaskPrefix}${TaskName}_${PEdir}_SBRef`
        mbfile_full=`imfind ${unprocdir}/${TaskPrefix}${TaskName}_${PEdir}`
        sefilePos_full=`imfind ${unprocdir}/SE_${TaskName}_${PEpos}`
        sefileNeg_full=`imfind ${unprocdir}/SE_${TaskName}_${PEneg}`
        fmfileMag_full=`imfind ${unprocdir}/FM_${TaskName}_Fieldmap_Mag`
        fmfilePhs_full=`imfind ${unprocdir}/FM_${TaskName}_Fieldmap_Phs`

        if [ X${mbfile_full} == X ]; then
            echo "missing mbfile for: "${Subject} ${ScanName} 1>&2
            continue
            #exit 0
	fi

        sbfile=`basename "${sbfile_full}"`
        mbfile=`basename "${mbfile_full}"`
        sefilePos=`basename "${sefilePos_full}"`
        sefileNeg=`basename "${sefileNeg_full}"`
        fmfilePhs=`basename "${fmfilePhs_full}"`
        fmfileMag=`basename "${fmfileMag_full}"`

        ###########################################
        #### make sure all images have even number of slices, otherwise topup will fail with subsamp 2

        #echo "$sbfile_full $sefilePos_full $sefileNeg_full $mbfile_full"
        #continue

        if (( $StartWithIdx <= $idxUnproc && $EndWithIdx >= $idxUnproc )); then

	    echo "Starting fslreorient2std: $Subject $ScanName $StartWith $EndWith"
            for f in $sbfile $sefilePos $sefileNeg $mbfile $fmfilePhs $fmfileMag
            do
                fslreorient2std_inplace ${unprocdir}/$f
            done

            #Topup handles this internally now so dont bother
            #echo "Starting evenslice check: $Subject $ScanName $StartWith $EndWith"
            #for f in $sbfile $sefilePos $sefileNeg $mbfile $fmfilePhs $fmfileMag
            #do
            #    bash `dirname $0`/hcpkj_run_evenslices.sh ${unprocdir}/$f
            #done

	   StartWithIdx=$idxInit
        fi

        ###########################################

        mbfile=`imfind ${unprocdir}/${mbfile}`
        sbfile=`imfind ${unprocdir}/${sbfile}`
        sefileNeg=`imfind ${unprocdir}/${sefileNeg}`
        sefilePos=`imfind ${unprocdir}/${sefilePos}`
        fmfilePhs=`imfind ${unprocdir}/${fmfilePhs}`
        fmfileMag=`imfind ${unprocdir}/${fmfileMag}`

	fMRIName="${TaskPrefix}${ScanName}"
        fMRITimeSeries="${mbfile}"

        #################################################################
        ############### Volume Pipeline Options ########################

	#EPIScoutType=VOL1
	fMRISBRef=NONE

	case `echo ${EPIScoutType} | tr "[a-z]" "[A-Z]"` in
		SBREF )
			if [ -e ${sbfile} ]; then
				fMRISBRef="${sbfile}"
			fi
			;;
		VOL10 )
			echo "Unimplimented EPIScoutType: ${EPIScoutType}"
			continue
			;;
		VOL10-20 )
			echo "Unimplimented EPIScoutType: ${EPIScoutType}"
			continue
			;;
		* )
			;;
	esac

	DistortionCorrection=${EPIDistortionCorrection}
	case ${DistortionCorrection} in
		TOPUP )
			SpinEchoPhaseEncodeNegative="${sefileNeg}" 
			SpinEchoPhaseEncodePositive="${sefilePos}"
			MagnitudeInputName="NONE" 
			PhaseInputName="NONE"
			if [ ! "x$NewEchoSpacing" = x ]; then
				TopupDwellTime=${DwellTime}
				DwellTime=$NewEchoSpacing
			fi
			;;
		FIELDMAP )
			SpinEchoPhaseEncodeNegative="NONE"
			SpinEchoPhaseEncodePositive="NONE"
			MagnitudeInputName=${fmfileMag}
			PhaseInputName=${fmfilePhs}
			;;
		* )
			SpinEchoPhaseEncodeNegative="NONE"
			SpinEchoPhaseEncodePositive="NONE"
			MagnitudeInputName="NONE" 
			PhaseInputName="NONE"
			;;
	esac
  

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
        ############### HPF/Melodic Options ########################
        HPF=${fMRI_HPF}
        AtlasSpaceFolder="MNINonLinear"
        ResultsFolder="Results"

        subjAtlasSpaceFolder="${StudyFolder}"/"${Subject}"/"${AtlasSpaceFolder}"
        subjResultsFolder="${subjAtlasSpaceFolder}"/"${ResultsFolder}"/"${fMRIName}"

        #################################################################
        ############### Run Volume Pipeline #############################

        if (( $StartWithIdx <= $idxInit && $EndWithIdx >= $idxInit )); then

            echo "Starting volume pipeline: $Subject $ScanName $StartWith $EndWith"

            StartWith_volproc=$StartWith
            EndWith_volproc=$EndWith

            if [[ $StartWithIdx < $idxInit ]]; then
                StartWith_volproc=init
            fi

            if [[ $EndWithIdx > $idxResults ]]; then
                EndWith_volproc=results
            fi

            ${FSLDIR}/bin/fsl_sub $QUEUE ${FSLSUBOPTIONS} \
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
              --SEechospacing=$TopupDwellTime \
              --echospacing=$DwellTime \
              --echodiff=$DeltaTE \
              --unwarpdir=$UnwarpDir \
              --fmrires=$FinalfMRIResolution \
              --dcmethod=$DistortionCorrection \
              --gdcoeffs=$GradientDistortionCoeffs \
              --topupconfig=$TopUpConfig \
              --startwith=${StartWith_volproc} \
              --endwith=${EndWith_volproc} \
              --dof=${DOF_EPI2T1} \
              --tempfiletype=${TMP_FSLOUTPUTTYPE} \
              --mctype=${MotionCorrectionType} \
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
              --fmrires=$FinalfMRIResolution \
              --dcmethod=$DistortionCorrection \
              --gdcoeffs=$GradientDistortionCoeffs \
              --topupconfig=$TopUpConfig \
              --dof=${DOF_EPI2T1} \
              --tempfiletype=${TMP_FSLOUTPUTTYPE} \
              --printcom=$PRINTCOM"

          echo ". ${EnvironmentScript}"
        fi

        #################################################################
        ############### Run Surface Pipeline #############################
        if (( $StartWithIdx <= $idxSurface && $EndWithIdx >= $idxSurface )); then

            echo "Starting surface pipeline: $Subject $ScanName $StartWith $EndWith"
            if [ "x$surfaceRes1" = x ]; then
		SurfScript="GenericfMRISurfaceProcessingPipeline"
            else
		SurfScript="GenericfMRISurfaceProcessingPipeline_1res"
            fi
            ${FSLDIR}/bin/fsl_sub $QUEUE ${FSLSUBOPTIONS} \
              ${HCPPIPEDIR}/fMRISurface/${SurfScript}.sh \
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

            ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE ${FSLSUBOPTIONS} \
              ${FSL_FIXDIR}/hcp_fix \
              ${fMRIfile} \
              ${HPF} \
              ${StartWith_fix} \
              ${EndWith_fix} 

        fi

        #################################################################
        ############### Run melodic+post #############


        if (( $StartWithIdx <= $idxFix && $EndWithIdx >= $idxFix )); then

            echo "Starting hcp_fix: $Subject $ScanName"

            StartWith_fix=melodic
            EndWith_fix=final

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

            echo $Session$fMRIName

            ${RUN} ${FSLDIR}/bin/fsl_sub $QUEUE ${FSLSUBOPTIONS} \
              ${FSL_FIXDIR}/hcp_fix \
              ${fMRIfile} \
              ${HPF} \
              ${StartWith_fix} \
              ${EndWith_fix} 

        fi

        #################################################################
        ############### Run post-melodic steps for crashed jobs #############

        if (( $StartWithIdx <= $idxPostIca && $EndWithIdx >= $idxPostIca )); then

            echo "Starting hcp_fix_post: $Subject $ScanName $StartWith $EndWith"

            StartWith_fix=$StartWith
            EndWith_fix=$EndWith

            if [[ $StartWithIdx < $idxHpf ]]; then
                StartWith_fix=hpf
            fi

            if [[ $EndWithIdx > $idxFix ]]; then
                EndWith_fix=melodic
            fi

            fMRIfile=`imfind ${subjResultsFolder}/${fMRIName}`

            if [ -z $fMRIfile ]; then
	        echo "Can't find file: ${subjResultsFolder}/${fMRIName}"
	        continue
            fi

	    #tmpdir=`echo ${subjResultsFolder} | sed 's/Phase2_7T/fixtrain/'`
	    tmpdir=${subjResultsFolder}
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
