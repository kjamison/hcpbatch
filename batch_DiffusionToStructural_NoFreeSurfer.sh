#!/bin/bash

#For some studies or subjects (eg: infants), initial anatomical segmentation is 
# poor and FreeSurfer may not perform well
# - DiffusionToStructural.sh will fail is FreeSurfer output is not present
# - DiffusionToStructural.sh will generate a bad nodif_brain_mask 
#
# 1. Run DiffPreprocPipeline_PostEddy.sh in echo mode to show the full
#	command-line for DiffusionToStructural.sh
# 2. Add "--nofreesurfer=1" to the end of the DiffusionToStructural command-line
#	arguments and execute
# 3. After DiffusionToStructural is finished, coreg diffusion's automatic brain
#	mask into downsampled structural space to use that instead
#################################################

STUDYNAME=$1; shift

Subject=$1

################
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${SCRIPTDIR}/batch_StudySettings.sh `echo $STUDYNAME | tr "@" " "`
if [ -z ${StudyFolder} ]; then
  exit 1
fi
##############

DegreesOfFreedom=${DOF_EPI2T1}

GdFlag=0
if [ ! ${GradientDistortionCoeffs} = "NONE" ]; then
	GdFlag=1
fi

#runcmd=echo
#${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PostEddy.sh --path=${StudyFolder} --subject=${Subject} --gdcoeffs=${$GradientDistortionCoeffs} --dof="${DegreesOfFreedom" --printcom="${runcmd}"

outdir=${StudyFolder}/${Subject}/Diffusion
outdirT1w=${StudyFolder}/${Subject}/T1w/Diffusion

T1wFolder="${StudyFolder}/${Subject}/T1w" #Location of T1w images
T1wImage="${T1wFolder}/T1w_acpc_dc"
T1wRestoreImage="${T1wFolder}/T1w_acpc_dc_restore"
T1wRestoreImageBrain="${T1wFolder}/T1w_acpc_dc_restore_brain"
BiasField="${T1wFolder}/BiasField_acpc_dc"
FreeSurferBrainMask="${T1wFolder}/brainmask_fs"
RegOutput="${outdir}"/reg/"Scout2T1w"
QAImage="${outdir}"/reg/"T1wMulEPI"
DiffRes=`${FSLDIR}/bin/fslval ${outdir}/data/data pixdim1`
DiffRes=`printf "%0.2f" ${DiffRes}`

#DiffRes=${FinalDWIResolution}

DataDirectory="${outdir}"/data
DiffToStructDirectory="${outdir}"/reg

FreeSurferBrainMask=${T1wRestoreImageBrain}

#FATarget=${T1wRestoreImageBrain}
FATarget=${StudyFolder}/${Subject}/T1w/Diffusion_3T/dti_FA_ero1

diff2str=
use_nofreesurfer=1

useFA=1
if [ ! "x${useFA}" = x ]; then
	${runcmd} dtifit_dir ${DataDirectory} dti
	${runcmd} fslmaths "$DataDirectory"/nodif_brain_mask -ero "$DataDirectory"/nodif_brain_mask_ero1
	fafile=${DataDirectory}/dti_FA
	${runcmd} fslmaths ${fafile} -mas "$DataDirectory"/nodif_brain_mask_ero1 ${fafile}_ero1

	fa2str="$DiffToStructDirectory"/fa2str.mat
	${runcmd} $FSLDIR/bin/flirt -ref ${FATarget} -in ${fafile}_ero1 -dof ${DegreesOfFreedom} -omat ${fa2str}

	diff2str=${fa2str}
fi

if [ "x${diff2str}" = x ]; then
	if [ -d ${T1wFolder}/${Subject}/mri/transforms/ ] &&
	   [ ! -e ${T1wFolder}/${Subject}/mri/transforms/eye.dat ]; then
		cat <<EOF > ${T1wFolder}/${Subject}/mri/transforms/eye.dat
${Subject}
1
1
1
1 0 0 0
0 1 0 0
0 0 1 0
0 0 0 1
round
EOF
	fi
fi

${runcmd} ${HCPPIPEDIR_dMRI}/DiffusionToStructural.sh \
	--t1folder="${T1wFolder}" \
	--subject="${Subject}" \
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
	--diffresol=${DiffRes} \
	--applyxfm=${diff2str} \
	--nofreesurfer=${use_nofreesurfer}

#If structural brainmask is not good quality, coreg automatic diffusion brainmask
# to structural image, maintaining native diffusion resolution
#${runcmd} ${FSLDIR}/bin/flirt -in "$DataDirectory"/nodif_brain_mask -ref "$T1wRestoreImage"_${DiffRes} -applyxfm -init "$DiffToStructDirectory"/diff2str.mat -interp nearestneighbour -out "$outdirT1w"/nodif_brain_mask

#DiffToStruct also masks data with structural brainmask... should we regenerate it?
# or maybe re-run whole diff2struct with FreeSurferBrainMask=coreg'd diff brainmask (at struct resolution)

