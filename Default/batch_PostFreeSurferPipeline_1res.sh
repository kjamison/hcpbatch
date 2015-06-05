#!/bin/bash 

STUDYNAME=$1
Subjlist=$2 #Space delimited list of subject IDs
surfaceRes1=$3

################
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${SCRIPTDIR}/batch_StudySettings.sh `echo $STUDYNAME | tr "@" " "`
if [ -z ${StudyFolder} ]; then
	exit 1
fi
##############

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"


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
		export GrayordinatesTemplate=${GrayordinatesTemplate_59k}
		export GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/${GrayordinatesTemplate}"
		;;
	* ) 
		;;
esac

########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the FreeSurfer Pipeline

######################################### DO WORK ##########################################


for Subject in $Subjlist ; do

  FSFolder="$StudyFolder"/"$Subject"/MNINonLinear/
  HighResFolder="$StudyFolder"/"$Subject"/MNINonLinear/fsaverage_LR164k
  mkdir -p ${HighResFolder}

  for i in `find $FSFolder -maxdepth 1 -type f | grep 164k`; do
    ln -sf $i ${HighResFolder}/`basename $i`
  done

  ${FSLDIR}/bin/fsl_sub ${QUEUE} ${FSLSUBOPTIONS} \
     ${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline_1res.sh \
      --path="$StudyFolder" \
      --subject="$Subject" \
      --surfatlasdir="$SurfaceAtlasDIR" \
      --grayordinatesdir="$GrayordinatesSpaceDIR" \
      --grayordinatesres="$GrayordinatesResolution" \
      --hiresmesh="$HighResMesh" \
      --lowresmesh="$LowResMesh" \
      --subcortgraylabels="$SubcorticalGrayLabels" \
      --freesurferlabels="$FreeSurferLabels" \
      --refmyelinmaps="$ReferenceMyelinMaps" \
      --printcom=$PRINTCOM

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
  
   echo "set -- --path="$StudyFolder" \
      --subject="$Subject" \
      --surfatlasdir="$SurfaceAtlasDIR" \
      --grayordinatesdir="$GrayordinatesSpaceDIR" \
      --grayordinatesres="$GrayordinatesResolution" \
      --hiresmesh="$HighResMesh" \
      --lowresmesh="$LowResMesh" \
      --subcortgraylabels="$SubcorticalGrayLabels" \
      --freesurferlabels="$FreeSurferLabels" \
      --refmyelinmaps="$ReferenceMyelinMaps" \
      --printcom=$PRINTCOM"
      
   echo ". ${EnvironmentScript}"
done

