. ~/Source/BatchPipeline/SetUpHCPPipeline.sh

fMRIFolder=/home/range1-raid1/kjamison/Data/mayo_data/subj03/REST1_mcflirt
NameOffMRI=REST1_20vol
ScoutName=Scout
MovementRegressor="Movement_Regressors" #No extension, .txt appended
MotionMatrixFolder="MotionMatrices"
MotionMatrixPrefix="MAT_"


PipelineScripts=$HCPPIPEDIR_fMRIVol

RUN=

#RUN=echo


#mcflirt: 		.par file is rad_x rad_y rad_z mm_x mm_y mm_z
#mcflirt_acc.sh: 	.par file is mm_x mm_y mm_z deg_x deg_y deg_z
#otherwise they are the same
#awk 'BEGIN{pi=atan2(0,-1)}{printf "%.6f %.6f %.6f %.6f %.6f %.6f\n",$4,$5,$6,$1*180/pi,$2*180/pi,$3*180/pi}' ${output}.par > ${output}/mc2.par


fMRIFolder=/home/range1-raid1/kjamison/Data/mayo_data/subj03/REST1_mcflirt

RUN=
mkdir -p "$fMRIFolder"/MotionCorrection_FLIRTbased
${RUN} "$PipelineScripts"/MotionCorrection_FLIRTbased.sh \
    "$fMRIFolder"/MotionCorrection_FLIRTbased \
    "$fMRIFolder"/"$NameOffMRI"_gdc \
    "$fMRIFolder"/"$ScoutName"_gdc \
    "$fMRIFolder"/"$NameOffMRI"_mc \
    "$fMRIFolder"/"$MovementRegressor" \
    "$fMRIFolder"/"$MotionMatrixFolder" \
    "$MotionMatrixPrefix" \
    mcflirt
