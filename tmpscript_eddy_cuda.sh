
PATH=/usr/local/cuda-6.5/bin:/usr/local/cuda-5.5/bin:$PATH
if [ `arch` = "x86_64" ]; then
        if [ -z "$LD_LIBRARY_PATH" ]; then
                LD_LIBRARY_PATH=/usr/local/cuda-6.5/lib64:/usr/local/cuda-5.5/lib64
        else
                LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-6.5/lib64:/usr/local/cuda-5.5/lib64
        fi
fi
export LD_LIBRARY_PATH
export PATH

export CUDA=/usr/local/cuda-6.5
eddy55=/home/range1-raid1/kjamison/Data/Pipelines/eddy/eddy_cuda_55
eddy65=/home/range1-raid1/kjamison/Data/Pipelines/eddy/eddy_cuda_65

workingdir=${HOME}/Data/Lifespan/LS7345/Diffusion/eddy
topupdir=`dirname ${workingdir}`/topup
#time ${eddy55} --imain=${workingdir}/Pos_Neg --mask=${workingdir}/nodif_brain_mask --index=${workingdir}/index.txt --acqp=${workingdir}/acqparams.txt --bvecs=${workingdir}/Pos_Neg.bvecs --bvals=${workingdir}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${workingdir}/eddy_unwarped_images --flm=quadratic --sep_offs_move --nvoxhp=2000 -v
time ${eddy65} --imain=${workingdir}/Pos_Neg --mask=${workingdir}/nodif_brain_mask --index=${workingdir}/index.txt --acqp=${workingdir}/acqparams.txt --bvecs=${workingdir}/Pos_Neg.bvecs --bvals=${workingdir}/Pos_Neg.bvals --fwhm=0 --topup=${topupdir}/topup_Pos_Neg_b0 --out=${workingdir}/eddy_unwarped_images --flm=quadratic --sep_offs_move --nvoxhp=2000 --ff=10 --rms -v
time bedpostx_gpu /home/range1-raid1/kjamison/Data/Lifespan/LS7345/T1w/Diffusion -n 3 --rician --model=2
