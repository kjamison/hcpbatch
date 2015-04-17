#!/bin/bash

Subject_all=LSKJ_3T
#ScanName_all="REST1_AP REST1_PA REST2_AP REST2_PA"
ScanName_all="REST1_AP"

T1wName=T1w_Prisma
#T1wName=T1w_Skyra

EnvironmentScript="/home/range1-raid1/kjamison/Source/BatchPipeline/SetUpHCPPipeline.sh" #Pipeline environment script
. ${EnvironmentScript} &> /dev/null

for subj in $Subject_all; do

	for ScanName in $ScanName_all; do

		Subject=${subj}

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


		fMRIFolder=/home/range1-raid1/kjamison/Data/Lifespan/${Subject}/REST_${ScanName}

		WD=${fMRIFolder}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased
		
		T1wFolder=/home/range1-raid1/kjamison/Data/Lifespan/${Subject}/${T1wName}
		outdir=${fMRIFolder}/epi2${T1wName}

		T1wImage=${T1wFolder}/T1w_acpc_dc
		T1wBrainImage=${T1wFolder}/T1w_acpc_dc_restore_brain
		ScoutInputName=${fMRIFolder}/Scout_gdc
		ScoutInputFile=`basename $ScoutInputName`
		T1wBrainImageFile=`basename $T1wBrainImage`

		
		echo "${Subject} ${ScanName} ${PEdir} ${UnwarpDir}"
		#continue


		mkdir -p ${outdir}

		wmsegfile=${T1wFolder}/T1w_acpc_dc_restore_fast_wmseg.nii.gz

    		if [ `$FSLDIR/bin/imtest ${wmsegfile}` = 0 ] ; then
			wmsegstr=
		else
			wmsegstr="--wmseg=${wmsegfile}"
		fi

		${FSLDIR}/bin/applywarp --rel --interp=spline -i ${ScoutInputName} -r ${ScoutInputName} -w ${WD}/WarpField.nii.gz -o ${outdir}/${ScoutInputFile}_undistorted_init

		${FSLDIR}/bin/imcp ${outdir}/${ScoutInputFile}_undistorted_init ${outdir}/${ScoutInputFile}_undistorted

		${FSLDIR}/bin/flirt -dof ${dof_epi2t1} -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${WD}/${T1wBrainImageFile} -omat ${outdir}/${ScoutInputFile}_undistorted_init.mat
		$FSLDIR/bin/applywarp -i ${outdir}/${ScoutInputFile}_undistorted_init -r ${WD}/${T1wBrainImageFile} -o ${outdir}/epi_initflirt --premat=${outdir}/${ScoutInputFile}_undistorted_init.mat --interp=spline

		${FSLDIR}/bin/flirt -dof ${dof_epi2t1} -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${WD}/${T1wBrainImageFile} -omat ${outdir}/${ScoutInputFile}_undistorted_init_mi.mat -bins 256 -cost normmi
		$FSLDIR/bin/applywarp -i ${outdir}/${ScoutInputFile}_undistorted_init -r ${WD}/${T1wBrainImageFile} -o ${outdir}/epi_initflirt_mi --premat=${outdir}/${ScoutInputFile}_undistorted_init_mi.mat --interp=spline


		continue

		${FSLDIR}/bin/flirt -dof ${dof_epi2t1} -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${T1wImage} -init ${outdir}/${ScoutInputFile}_undistorted_init.mat -cost bbr -omat ${outdir}/${ScoutInputFile}_undistorted.mat -schedule ${FSLDIR}/etc/flirtsch/bbr.sch -wmseg ${wmsegfile} -out ${outdir}/epi_bbr

		echo ${WD}/${T1wBrainImageFile} 
		echo ${T1wImage}
		continue
		${HCPPIPEDIR_fMRIVol}/epi_reg_dof --dof=${dof_epi2t1} --epi=${outdir}/${ScoutInputFile}_undistorted_init --t1=${T1wImage} --t1brain=${WD}/${T1wBrainImageFile} --out=${outdir}/${ScoutInputFile}_undistorted ${wmsegstr}

		${FSLDIR}/bin/flirt -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${T1wImage} -out ${outdir}/epi2${T1wName}_initflirt -init ${outdir}/${ScoutInputFile}_undistorted_init.mat -applyxfm

		${FSLDIR}/bin/flirt -in ${outdir}/${ScoutInputFile}_undistorted_init -ref ${T1wImage} -out ${outdir}/epi2${T1wName}_bbr -init ${outdir}/${ScoutInputFile}_undistorted.mat -applyxfm

		wmseg_out=${outdir}/${ScoutInputFile}_undistorted_fast_wmseg.nii.gz
		cp -f ${wmseg_out} ${wmsegfile} 

	done
done
