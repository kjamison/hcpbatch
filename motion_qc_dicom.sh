#!/bin/bash


#SUBJID=$1
#scantype=$2

#SUBJID=LS7030_3T
scantype=REST

dicomroot=~/range3hcp;
motionqc_root=~/Data/motion_qc/Lifespan

. ~/hcp_pipeline/SetUpHCPPipeline.sh

PipelineScripts=${HCPPIPEDIR_PreFS}
GlobalScripts=${HCPPIPEDIR_Global}

for mcdir in `find $motionqc_root -maxdepth 4 -type d | grep MOTIONOUTLIER_DATA`;
do

	session=`echo $mcdir | sed "s#^.\+/motion_qc/Lifespan/\([^/]\+\)/.\+#\1#"`
	scannum=`echo $mcdir | sed "s#^.\+_SCAN\([0-9]\+\)_.\+#\1#"`

	echo "#########################################"
	echo
	echo $session $scannum
	echo
	date
	echo
	echo "#########################################"
	sessdir=`ls $dicomroot | grep -E "$session\$"`;

	dcmfile1=
	for d in $sessdir;
	do
		#scandir=`ls $dicomroot/$d | grep -vi SBRef | grep -m1 $scantype`
		scanstr=`printf "SE%03d-\n" $scannum`
		scandir=`ls $dicomroot/$d | grep $scantype | grep -m1 $scanstr`

		numdcm=`ls $dicomroot/$d/$scandir | grep -E "dcm\$" | wc -l`
		if [ "X${scandir}" = X ] || [ ${numdcm} -eq 0 ]; then
			continue;
		fi
		dcmfile1=`ls $dicomroot/$d/$scandir | grep -m1 -E "dcm\$"`
		#echo $numdcm $dicomroot/$d/$scandir/$dcm1
		break;
	done

	if [ "X${dcmfile1}" = X ]; then
		continue;
	fi
	dcmfile1=${dicomroot}/$d/${scandir}/$dcmfile1

	if [[ $session == *_3T* ]]; then
		gradfile=~/hcp_pipeline/grad_coeffs/CMRR_Prisma_coeff_AS82_full.grad
	elif [[ $session = *_7T* ]]; then
		gradfile=~/hcp_pipeline/grad_coeffs/7TAS_coeff_SC72CD_full.grad
	else
		echo "unknown scanner type"
		continue;
	fi

	niifile=${session}_SCAN${scannum}_${scantype}.nii
	niifile_gdc=${session}_SCAN${scannum}_${scantype}_gdc.nii

	procdir=${motionqc_root}/${session}/preproc

	tmporig=$procdir/tmp
	tmporient=$procdir/tmp_std
	im2std_mat=$procdir/im2std.mat
	OutputTransform=$procdir/${session}_SCAN${scannum}_${scantype}_gdc_warp

	mcnewdir=$procdir/motion_qc

	if [ -n "" ]; then

	rm -Rf $procdir

	mkdir -p $procdir

	dcm2nii_filename --rename $niifile -b ~/hcp_pipeline/dcm2nii_hcp.ini -g N -o $procdir $dcmfile1


	FSLOUTPUTTYPE=NIFTI_GZ
	fslroi $procdir/$niifile $procdir/tmp 0 1


	${FSLDIR}/bin/fslreorient2std ${tmporig} > ${im2std_mat}
	${FSLDIR}/bin/fslreorient2std ${tmporig} ${tmporient}


	${GlobalScripts}/GradientDistortionUnwarp.sh \
	--workingdir=${procdir} \
	--coeffs=${gradfile} \
	--in=${tmporient} \
	--out=${tmporient}_gdc \
	--owarp=${OutputTransform}

	FSLOUTPUTTYPE=NIFTI
	${FSLDIR}/bin/applywarp --rel --interp=spline -i ${procdir}/${niifile} -r ${tmporient} --premat=${im2std_mat} -w ${OutputTransform} -o ${procdir}/${niifile_gdc}

	rm -f fullWarp_abs.* trilinear.* ${procdir}/tmp*

	echo "Starting mcflirt: ${procdir}/${niifile_gdc}"
	mkdir -p $mcnewdir
	ln -s $procdir/${niifile_gdc} ${mcnewdir}/fmri.nii
	mcflirt -in ${mcnewdir}/fmri -out ${mcnewdir}/fmri_mcf -spline_final -mats -plots -rmsrel -rmsabs -stats

	fi

	
	FSLOUTPUTTYPE=NIFTI
	mcnewdir_tmp=${mcnewdir}/motion_outliers
	mkdir -p ${mcnewdir_tmp}
	bash ~/Data/motion_qc/motion_qc.sh fmri ${mcnewdir} ${mcnewdir} ${mcnewdir}/Xmo.txt ${mcnewdir_tmp}
done




