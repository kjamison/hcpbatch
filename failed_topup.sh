#!/bin/bash

HCPPIPEDIR=/home/range1-raid1/kjamison/anvu-hcp/Pipelines
GlobalBinaries=${HCPPIPEDIR}/global/binaries
GlobalConfig=${HCPPIPEDIR}/global/config
WD=/home/range1-raid1/kjamison/anvu-keith/Phase2_7T/365343/REST_7T_task1PA/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/FieldMap
TopupConfig=${GlobalConfig}/b02b0.cnf
txtfname=${WD}/acqparams.txt

cmd="${GlobalBinaries}/topup --imain=${WD}/BothPhases --datain=$txtfname --config=${TopupConfig} --out=${WD}/Coefficents --iout=${WD}/Magnitudes --fout=${WD}/TopupField --dfout=${WD}/WarpField --rbmout=${WD}/MotionMatrix --jacout=${WD}/Jacobian -v --subsamp=1,1,1,1,1,1,1,1,1"

echo $cmd
#$cmd

