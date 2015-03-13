#!/bin/bash

Subject_all=`ls /home/range1-raid1/kjamison/Data2/Phase2_7T`
ScanName_all="REST1_LR REST1_RL REST2_LR REST2_RL"

EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script
. ${EnvironmentScript} &> /dev/null

for subj in $Subject_all; do

	for ScanName in $ScanName_all; do

		Subject=${subj}_3T

		TaskName=`echo ${ScanName} | sed 's/_[APLR]\+$//'`

		SessFolder=`echo ${ScanName} | sed 's/[0-9]\+_[APLR]\+$//'`

		dof_epi2t1=12

		PEpos=RL
		PEneg=LR
		UnwarpAxis=x

		#PEpos=PA
		#PEneg=AP
		#UnwarpAxis=y

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


		outdir=/home/range1-raid1/kjamison/Data/HCP_coreg_test/${Subject}/rfMRI_${ScanName}


		T1wFolder=/hcp/hcpdb/HCP_500/arc001/${Subject}/RESOURCES/Structural_preproc/T1w
		fMRIFolder=/hcp/hcpdb/HCP_500/arc001/${Subject}/RESOURCES/rfMRI_${ScanName}_preproc/rfMRI_${ScanName}

		WD=${fMRIFolder}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased

		T1wImage=${T1wFolder}/T1w_acpc_dc
		T1wBrainImage=${T1wFolder}/T1w_acpc_dc_restore_brain
		ScoutInputName=${fMRIFolder}/Scout_gdc
		ScoutInputFile=`basename $ScoutInputName`
		T1wBrainImageFile=`basename $T1wBrainImage`

		
		echo "${Subject} ${ScanName} ${PEdir} ${UnwarpDir}"
		#continue

		mkdir -p ${outdir}

		wmsegfile=${outdir}/../T1w_acpc_dc_restore_fast_wmseg.nii.gz
    		if [ `$FSLDIR/bin/imtest ${wmsegfile}` = 0 ] ; then
			wmsegstr=
		else
			wmsegstr="--wmseg=${wmsegfile}"
		fi

		${FSLDIR}/bin/applywarp --rel --interp=spline -i ${ScoutInputName} -r ${ScoutInputName} -w ${WD}/WarpField.nii.gz -o ${outdir}/${ScoutInputFile}_undistorted_init

		${FSLDIR}/bin/imcp ${outdir}/${ScoutInputFile}_undistorted_init ${outdir}/${ScoutInputFile}_undistorted

		${HCPPIPEDIR_fMRIVol}/epi_reg_dof --dof=${dof_epi2t1} --epi=${outdir}/${ScoutInputFile}_undistorted --t1=${T1wImage} --t1brain=${WD}/${T1wBrainImageFile} --out=${outdir}/${ScoutInputFile}_undistorted ${wmsegstr}

		${FSLDIR}/bin/flirt -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${T1wImage} -out ${outdir}/epi2${T1wName}_initflirt -init ${outdir}/${ScoutInputFile}_undistorted_init.mat -applyxfm

		${FSLDIR}/bin/flirt -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${T1wImage} -out ${outdir}/epi2${T1wName}_bbr -init ${outdir}/${ScoutInputFile}_undistorted.mat -applyxfm

		wmseg_out=${outdir}/${ScoutInputFile}_undistorted_fast_wmseg.nii.gz
		cp -f ${wmseg_out} ${wmsegfile} 

	break
	done
	break
done
