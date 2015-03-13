#!/bin/sh

set -e
echo -e "\n START: basic_preproc_merge_gpu"

#Preprocessing for topup/eddy with phase encoding being AP and PA. The data directory is expected as an argument
#Assumes that *AP* and *PA* images exist, and also respective *AP*.bval, *PA*.bvec, etc. Need to specify the echo spacing (in msecs), as a second argument.
#Stamatios Sotiropoulos, FMRIB Analysis Group, 2011

isodd(){
    echo "$(( $1 % 2 ))"
}


subjdir=$1
inputdir=$2
echo_spacing=$3
b0dist=$4  #Choose one b0 every at least 5 DWIs.

rawdir=${subjdir}/rawdata
topupdir=${subjdir}/topup
eddydir=${subjdir}/eddy


echo Merging AP and PA images

if [ -f ${subjdir}/AP.nii* ]; then
    rm ${subjdir}/AP.nii*
fi

if [ -f ${subjdir}/PA.nii* ]; then
    rm ${subjdir}/PA.nii*
fi

${FSLDIR}/bin/fslmerge -t ${rawdir}/AP `echo ${inputdir}/*AP*.nii*`
${FSLDIR}/bin/fslmerge -t ${rawdir}/PA `echo ${inputdir}/*PA*.nii*`

paste `echo ${inputdir}/*AP*.bval` | sed 's/[\t]//g' >${rawdir}/AP.bval
paste `echo ${inputdir}/*AP*.bvec` | sed 's/[\t]//g' >${rawdir}/AP.bvec
paste `echo ${inputdir}/*PA*.bval` | sed 's/[\t]//g' >${rawdir}/PA.bval
paste `echo ${inputdir}/*PA*.bvec` | sed 's/[\t]//g' >${rawdir}/PA.bvec

dimx=`${FSLDIR}/bin/fslval ${rawdir}/AP dim1`
dimy=`${FSLDIR}/bin/fslval ${rawdir}/AP dim2`
dimz=`${FSLDIR}/bin/fslval ${rawdir}/AP dim3`
dimt=`${FSLDIR}/bin/fslval ${rawdir}/AP dim4`

nPEsteps=$dimy
#Total_readout=Echo_spacing*(#of_PE_steps-1)
ro_time=`echo "${echo_spacing} * ( ${nPEsteps} - 1 )" | bc -l`
ro_time=`echo "scale=6; ${ro_time} / 1000" | bc -l` #Compute Total_readout in secs with up to 6 decimal places
echo "Total readout time is $ro_time secs"


if [ -f ${rawdir}/acqparams.txt ]; then
    rm ${rawdir}/acqparams.txt
fi

if [ -f ${rawdir}/preproc.txt ]; then
    rm ${rawdir}/preproc.txt
fi

if [ -f ${rawdir}/index.txt ]; then
    rm ${rawdir}/index.txt
fi

if [ `isodd $dimz` -eq 1 ];then
    echo "Add one slice to data to get even number of slices"
    fslroi ${rawdir}/AP ${rawdir}/APz 0 $dimx 0 $dimy 0 1 0 $dimt
    fslmaths ${rawdir}/APz -mul 0 ${rawdir}/APz
    fslmerge -z ${rawdir}/AP ${rawdir}/APz ${rawdir}/AP
    fslmerge -z ${rawdir}/PA ${rawdir}/APz ${rawdir}/PA
    rm ${rawdir}/APz.*
    #echo "Remove one slice from data to get even number of slices"
    #fslroi ${rawdir}/LR ${rawdir}/LRn 0 -1 0 -1 1 -1
    #fslroi ${rawdir}/RL ${rawdir}/RLn 0 -1 0 -1 1 -1
    #imrm ${rawdir}/LR
    #imrm ${rawdir}/RL
    #mv ${rawdir}/LRn.nii.gz ${rawdir}/LR.nii.gz
    #mv ${rawdir}/RLn.nii.gz ${rawdir}/RL.nii.gz
fi


APbvals=`cat ${rawdir}/AP.bval`

echo "Extracting b0s from AP volume and creating index file"
count=0
count2=0
count3=$(($b0dist + 1))
for i in $APbvals 
do  #Consider a b=0 a volume that has a bvalue<100 and is at least 50 volumes away from the previous
    if [ $i -lt 100 ] && [ $count3 -gt $b0dist ]; then  
	cnt=`$FSLDIR/bin/zeropad $count2 4`
	echo "Extracting AP Volume $count as a b=0. Measured b=$i" >>${rawdir}/preproc.txt
	fslroi ${rawdir}/AP ${rawdir}/AP_b0_$cnt $count 1
	echo 0 1 0 $ro_time >> ${rawdir}/acqparams.txt
	count2=$(($count2 + 1))
	count3=0
    fi
    echo $count2 >>${rawdir}/index.txt
    count3=$(($count3 + 1))
    count=$(($count + 1))
done

echo "Merging b0 images"
${FSLDIR}/bin/fslmerge -t ${rawdir}/AP_b0 `${FSLDIR}/bin/imglob ${rawdir}/AP_b0_????.*`



PAbvals=`cat ${rawdir}/PA.bval`

echo "Extracting b0s from PA volume and creating index file"
PAcount=$count2
count=0
count2=0
count3=$(($b0dist + 1))
for i in $PAbvals
do #Consider a b=0 a volume that has a bvalue<100 and is at least 50 volumes away from the previous
    if [ $i -lt 100 ] && [ $count3 -gt $b0dist ]; then  
	cnt=`$FSLDIR/bin/zeropad $count2 4`
	echo "Extracting PA Volume $count as a b=0. Measured b=$i" >>${rawdir}/preproc.txt
	fslroi ${rawdir}/PA ${rawdir}/PA_b0_$cnt $count 1
	echo 0 -1 0 $ro_time >> ${rawdir}/acqparams.txt
	count2=$(($count2 + 1))
	count3=0
    fi
    echo $(($count2 + $PAcount)) >>${rawdir}/index.txt
    count3=$(($count3 + 1))
    count=$(($count + 1))
done

echo "Merging b0 images"
${FSLDIR}/bin/fslmerge -t ${rawdir}/PA_b0 `${FSLDIR}/bin/imglob ${rawdir}/PA_b0_????.*`


echo "Perform Final Merge"

${FSLDIR}/bin/fslmerge -t ${rawdir}/AP_PA_b0 ${rawdir}/AP_b0 ${rawdir}/PA_b0 
${FSLDIR}/bin/fslmerge -t ${rawdir}/AP_PA ${rawdir}/AP.nii* ${rawdir}/PA.nii*
 
paste ${rawdir}/AP.bval ${rawdir}/PA.bval | sed 's/[\t]//g' >${rawdir}/bvals
paste ${rawdir}/AP.bvec ${rawdir}/PA.bvec | sed 's/[\t]//g' >${rawdir}/bvecs

#######################################
${FSLDIR}/bin/imrm `${FSLDIR}/bin/imglob ${rawdir}/AP_b0_????.*`
${FSLDIR}/bin/imrm `${FSLDIR}/bin/imglob ${rawdir}/PA_b0_????.*`

${FSLDIR}/bin/imrm ${rawdir}/AP
${FSLDIR}/bin/imrm ${rawdir}/PA

exit 0
################################################################################################
## Move files to appropriate directories 
################################################################################################
echo "Move files to appropriate directories"
mv ${rawdir}/preproc.txt ${topupdir} #aka extractedb0.txt 
mv ${rawdir}/acqparams.txt ${topupdir}
${FSLDIR}/bin/immv ${rawdir}/AP_PA_b0 ${topupdir}
${FSLDIR}/bin/immv ${rawdir}/AP_b0 ${topupdir}
${FSLDIR}/bin/immv ${rawdir}/PA_b0 ${topupdir}

cp ${topupdir}/acqparams.txt ${eddydir}
mv ${rawdir}/index.txt ${eddydir}
mv ${rawdir}/series_index.txt ${eddydir}
${FSLDIR}/bin/immv ${rawdir}/AP_PA ${eddydir}
mv ${rawdir}/bvals ${eddydir}
mv ${rawdir}/bvecs ${eddydir}
mv ${rawdir}/AP.bv?? ${eddydir}
mv ${rawdir}/PA.bv?? ${eddydir}

echo -e "\n END: basic_preproc_merge_gpu"


