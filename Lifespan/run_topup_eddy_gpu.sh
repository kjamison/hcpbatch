#!/bin/sh

#Running topup/eddy with phase encoding being AP and PA. The data directory is expected as an argument
#Assumes that *AP* and *PA* images exist, and also respective *AP*.bval, *PA*.bvec, etc. Need to run basic_preproc.sh first!
#Stamatios Sotiropoulos, FMRIB Analysis Group, 2011

set -e
echo -e "\n START: run_topup_eddy_gpu"

#FSLGPU=/usr/local/fsl_gpu/fsl
FSLGPU=$FSLDIR

#topup_config_file=~clenglet/Sources/eddy/fsl/topup_b02b0.cnf
topup_config_file=${HCPPIPEDIR}/eddy/topup_b02b0.cnf

subjdir=$1
bet2threddy=$2

rawdir=${subjdir}/rawdata
topupdir=${subjdir}/topup
eddydir=${subjdir}/eddy

echo "Running topup"
${FSLGPU}/bin/topup --imain=${topupdir}/AP_PA_b0 --datain=${topupdir}/acqparams.txt --config=${topup_config_file} --out=${topupdir}/topup_AP_PA_b0 -v

dimt=`${FSLDIR}/bin/fslval ${topupdir}/AP_b0 dim4`
dimt=$(($dimt + 1))

echo "Applying topup to get a hifi b0"
${FSLGPU}/bin/applytopup --imain=${topupdir}/AP_b0,${topupdir}/PA_b0 --topup=${topupdir}/topup_AP_PA_b0 --datain=${topupdir}/acqparams.txt --inindex=1,$dimt --out=${topupdir}/hifib0

imrm ${topupdir}/AP
imrm ${topupdir}/PA
imrm ${topupdir}/AP_b0
imrm ${topupdir}/PA_b0

echo "Running BET on the hifi b0"
bet2 ${topupdir}/hifib0 ${topupdir}/nodif_brain -m -f ${bet2threddy}

${FSLDIR}/bin/imcp ${topupdir}/nodif_brain_mask ${eddydir}/

echo "Running eddy"
${HCPPIPEDIR}/eddy/eddy_cuda_55 --imain=${eddydir}/AP_PA --mask=${eddydir}/nodif_brain_mask --index=${eddydir}/index.txt --acqp=${eddydir}/acqparams.txt --bvecs=${eddydir}/bvecs --bvals=${eddydir}/bvals --fwhm=5 --topup=${topupdir}/topup_AP_PA_b0 --out=${eddydir}/eddy_unwarped --wss --repol -v

#/usr/local/fsl_gpu_eddy/fsl/bin/eddy_gpu --imain=${subjdir}/AP_PA --mask=${subjdir}/nodif_brain_mask --index=${subjdir}/index.txt --acqp=${subjdir}/acqparams.txt --bvecs=${subjdir}/bvecs --bvals=${subjdir}/bvals --fwhm=5 --topup=${subjdir}/topup_AP_PA_b0 --out=${subjdir}/eddy_unwarped -v
