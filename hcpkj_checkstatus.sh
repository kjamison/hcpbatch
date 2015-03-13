#!/bin/bash

searchsubj=$1

u=$USER
m=`hostname -s`

StudyFolder="/home/range1-raid1/kjamison/Data2/Phase2_7T" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script

#Set up pipeline environment variables and software
. ${EnvironmentScript} > /dev/null

PipelineScripts=${HCPPIPEDIR_fMRIVol}
PipelineSurfaceScripts=${HCPPIPEDIR_fMRISurf}
GlobalScripts=${HCPPIPEDIR_Global}
GlobalBinaries=${HCPPIPEDIR_Bin}

scriptnames="gdc|${GlobalScripts}/GradientDistortionUnwarp.sh
moco|${PipelineScripts}/MotionCorrection_FLIRTbased.sh
topup|${PipelineScripts}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh
resamp|${PipelineScripts}/OneStepResampling.sh
norm|${PipelineScripts}/IntensityNormalization.sh
surface|${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh
hpf|bptf
melodic|${FSL_FIXDIR}/hcp_fix"

cpusum=`ps aux | tail -n +2 | awk '{print $3}' | awk 'BEGIN{printf 0}{printf "+(%s)",$1}' | tr '\n' '+' | awk '{print $0}' | bc`
memsum=`ps aux | tail -n +2 | awk '{print $4}' | awk 'BEGIN{printf 0}{printf "+(%s)",$1}' | tr '\n' '+' | awk '{print $0}' | bc`

cpustr=`printf "%.1f\n" $cpusum`
memstr=`printf "%.2f\n" $memsum`

#echo "$cpusum $memsum $cpustr $memstr"
#exit 0
for s in $scriptnames; do
	sname=`echo $s | awk -F\| '{print $1}'`
	sscript=`echo $s | sed 's/^[^|]\+|//'`
	#echo $sscript
	ps -u $u auxww | grep -v 'grep\|fsl_sub' | grep -v `basename $0` | grep "${sscript}" | sed "s#.*${StudyFolder}/\([^/]\+\)/\([^.]\+\)/.*\$#\1 \2#gi" | sed 's#.*--subject=\([^\s]\+\).*--fmriname=\([^ \t]\+\).*$#\1 \2#gi' | sed "s/^/$m\t$sname\t$cpustr\t$memstr /"
done

if [ X$searchsubj != X ]; then
	ps -u $u auxww | grep -v 'grep\|fsl_sub' | grep -v `basename $0` | grep "${searchsubj}" | sed "s#.*${StudyFolder}/\([^/]\+\)/\([^.]\+\)/.*\$#\1 \2#g" | sed 's#.*--subject=\([^\s]\+\).*--fmriname=\([^ \t]\+\).*$#\1 \2#gi' | sed "s/^/$m $searchsubj $cpustr $memstr /"

fi

