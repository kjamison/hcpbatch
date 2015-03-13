#!/bin/bash

maindir=~kjamison/Data/HCP_coreg_test

Subject_all=`ls $maindir`
ScanName_all="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"
costfunc=corratio
#costfunc=normmi
costfunc=bbregister

for Subject in ${Subject_all}; do
	for ScanName in ${ScanName_all}; do
		dir6=/hcp/hcpdb/HCP_500/arc001/${Subject}/RESOURCES/${ScanName}_preproc/${ScanName}
		dir12=${maindir}/${Subject}/${ScanName}

		scout6=${dir6}/Scout2T1w.nii.gz
		scout12=${dir12}/reg12_Scout2T1w.nii.gz

		if [ ! -e $scout6 ] || [ ! -e $scout12 ]; then
			continue
		fi

		brainfile=${dir6}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/T1w_acpc_dc_restore_brain.nii.gz

		costfile6=${dir6}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/EPItoT1w.dat.mincost
		costfile12=${dir12}/reg12_DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/EPItoT1w.dat.mincost

		if [ $costfunc = bbregister ]; then
			cost6=`cat ${costfile6} | awk '{print $1}'`
			cost12=`cat ${costfile12} | awk '{print $1}'`
		else
			cost6=`flirtcost -in $scout6 -ref $brainfile -cost ${costfunc}`
			cost12=`flirtcost -in $scout12 -ref $brainfile -cost ${costfunc}`
		fi

		costdiff=`echo "scale=7; 100*($cost6 - $cost12)/$cost6" | bc`
		printf "%10s %-15s %10.4f %10.4f (%10.4f)\n" $Subject $ScanName $cost6 $cost12 $costdiff
	done
done
