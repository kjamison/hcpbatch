#!/bin/bash

#Subject_all=`ls /home/range1-raid1/kjamison/Data2/Phase2_7T`

#Subject_all="177645 178142 181232 191841 196144 197348 205220"
#Subject_all="212419 214019 "251833 365343 547046 690152"
#Subject_all="770352 782561 859671 899885 901139 910241"

#ScanName_all="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"

Subject_all=$1
ScanName_all=$2

dof_epi2t1=12

EnvironmentScript="/home/range1-raid1/kjamison/Source/BatchPipeline/SetUpHCPPipeline.sh"

. ${EnvironmentScript} &> /dev/null

for Subject in $Subject_all; do

	for ScanName in $ScanName_all; do

		echo "$Subject $ScanName"

		UnprocDir=/hcp/hcpdb/HCP_500/arc001/${Subject}_3T/RESOURCES/${ScanName}_unproc
		PreprocDir=/hcp/hcpdb/HCP_500/arc001/${Subject}_3T/RESOURCES/${ScanName}_preproc
		T1wDir=/hcp/hcpdb/HCP_500/arc001/${Subject}_3T/RESOURCES/Structural_preproc/T1w

		WDorig=${PreprocDir}/${ScanName}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased

		ScanDir=/home/range1-raid1/kjamison/Data/HCP_coreg_test/${Subject}_3T/${ScanName}

		WD=${ScanDir}/reg${dof_epi2t1}_DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased

		xfmsDir=${ScanDir}

		mkdir -p $WD

		rm -f ${WD}/WarpField.nii.gz
		rm -f ${WD}/Jacobian.nii.gz

		ln -s ${WDorig}/WarpField.nii.gz ${WD}/WarpField.nii.gz
		ln -s ${WDorig}/Jacobian.nii.gz ${WD}/Jacobian.nii.gz

		#for POSTTOPUP can leave SEPhaseNeg/Pos, unwarpdir, echospacing blank

		${HCPPIPEDIR_fMRIVol}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh \
		--workingdir=${WD} \
		--scoutin=${PreprocDir}/${ScanName}/Scout_gdc \
		--t1=${T1wDir}/T1w_acpc_dc \
		--t1restore=${T1wDir}/T1w_acpc_dc_restore \
		--t1brain=${T1wDir}/T1w_acpc_dc_restore_brain \
		--fmapmag= \
		--fmapphase= \
		--echodiff=NONE \
		--SEPhaseNeg=${UnprocDir}/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz \
		--SEPhasePos=${UnprocDir}/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz \
		--echospacing=0.000580002668012 \
		--unwarpdir=-x \
		--biasfield=${T1wDir}/BiasField_acpc_dc \
		--freesurferfolder=${T1wDir} \
		--freesurfersubjectid=${Subject} \
		--gdcoeffs=${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad \
		--method=POSTTOPUP \
		--topupconfig=${HCPPIPEDIR_Config}/b02b0.cnf \
		--dof=${dof_epi2t1} \
		--ojacobian=${ScanDir}/reg${dof_epi2t1}_Jacobian \
		--qaimage=${ScanDir}/reg${dof_epi2t1}_T1wMulEPI \
		--oregim=${ScanDir}/reg${dof_epi2t1}_Scout2T1w \
		--owarp=${xfmsDir}/reg${dof_epi2t1}_${ScanName}2str


	done
done

