#!/bin/bash 

function StudySettings {

####################################################
function show_help_StudySettings {
	echo
	echo `basename ${BASH_SOURCE[0]}`" <WHICHSTUDY> [<WHICHSCANNER>]"
	echo `basename ${BASH_SOURCE[0]}`" <WHICHSTUDY>@<WHICHSCANNER>"
	cat <<END
	Exports study and scanner specific settings
END

}
####################################################


local to_export="StudyFolder ProjectName ScannerName DicomRoot GradientDistortionCoeffs EnvironmentScript TemplateSize
	StructuralUnwarpDir DwellTime StructuralDwellTime DeltaTE StructuralDeltaTE EPIDistortionCorrection
	TopUpConfig BrainSize T1wSampleSpacing T2wSampleSpacing DOF_EPI2T1 EPIScoutType
	PEpos_x PEneg_x PEpos_y PEneg_y PEpos PEneg UnwarpAxis DWIDwellTime
	GrayordinatesResolution HighResMesh LowResMesh SurfaceAtlasDIR GrayordinatesSpaceDIR
	SubcorticalGrayLabels FreeSurferLabels ReferenceMyelinMaps FSL_FIXDIR LogFileDir FSLSUBOPTIONS
	FinalfMRIResolution FinalDWIResolution SmoothingFWHM fMRI_HPF SessionGrep dcm2nii_inifile
	MotionCorrectionType 
	GrayordinatesResolution_32k LowResMesh_32k GrayordinatesTemplate_32k
	GrayordinatesResolution_59k LowResMesh_59k GrayordinatesTemplate_59k
"

unset ${to_export}

local whichstudy=`echo ${1}@ | cut -d@ -f1`
local whichscanner=$2
if [ "x${whichscanner}" = x ]; then
	whichscanner=`echo ${1}@ | cut -d@ -f2`
fi

local gdcdir="/home/range1-raid1/kjamison/hcp_pipeline/grad_coeffs/copied_from_scanners"
local gdcTrio=${gdcdir}/CMRR_Trio_coeff_AS05_PT3_20141111.grad
local gdcPrisma=${gdcdir}/CMRR_Prisma_coeff_AS82_20141111.grad
local gdc7T=${gdcdir}/CMRR_7TAS_coeff_SC72CD_20141111.grad
local gdcConnectomS=${gdcdir}/WUSTL_ConnectomS_coeff_SC72C_20141119.grad

EnvironmentScript="/home/range1-raid1/kjamison/Source/BatchPipeline/SetUpHCPPipeline.sh" #Pipeline environment script
dcm2nii_inifile="/home/range1-raid1/kjamison/Source/BatchPipeline/dcm2nii_hcp.ini"
FSL_FIXDIR="/home/range1-raid1/kjamison/Data/fix1.06"

GradientDistortionCoeffs="NONE"
DicomRoot=/home/range3-raid4/dicom
SessionGrep=

MotionCorrectionType=flirt

ProjectName=

local regex_hcp7t='[0-9]{6}_(mov|ret|diff|mov)[0-9]?_7T[a-z]?'
local regex_lifespan='LS7[0-9]{3}_[37]T[a-z]?'

local sessionregex=
local sessionregex_inv=

###########################################
###########################################
local studyarg=`echo $whichstudy | tr "[a-z]" "[A-Z]"`

ProjectName=$studyarg

case $studyarg in
	LIFESPAN )
		StudyFolder="/home/range1-raid1/kjamison/Data/Lifespan"
		DefaultScanner=
		sessionregex=${regex_lifespan}
		;;
	HCP3T )
		StudyFolder="/home/range1-raid1/kjamison/Data/HCP"
		DefaultScanner=ConnectomS
		sessionregex='[0-9]{6}_.+'
		sessionregex_inv=${regex_hcp7t}
		;;
	HCP7T )
		StudyFolder="/home/range1-raid1/kjamison/Data2/Phase2_7T"
		DicomRoot=/home/range3-raid4/dicom
		DefaultScanner=7TAS
		sessionregex=${regex_hcp7t}
		;;
	MBME )
		StudyFolder="/home/range1-raid1/kjamison/Data/MBME"
		DefaultScanner=Prisma
		MotionCorrectionType=mcflirt
		;;
	BSLERP )
		StudyFolder="/home/range1-raid1/kjamison/Data/BSLERP"
		DicomRoot=/home/naxos-raid2/dicom
		DefaultScanner=Prisma
		;;
	MPS )
		StudyFolder="/home/range1-raid1/kjamison/Data/MPS"
		DicomRoot=/home/range1-raid1/igor-data/LDN/connectome
		DefaultScanner=ConnectomS
		;;
	TEST10P5 )
		
		DefaultScanner=10T5
		StudyFolder="/home/range1-raid1/kjamison/Data/TEST10p5"
		;;
	HIGHRES )
		
		DefaultScanner=Prisma
		StudyFolder="/home/range1-raid1/kjamison/Data/HighRes"
		;;
	* )
		show_help_StudySettings;
		echo ""
		echo "**** Unknown study name: ${whichstudy} **** "
		echo ""
		unset ${to_export}
		return
esac

if [ "x${sessionregex}" = x ] && [ "x${sessionregex_inv}" = x ]; then
	sessionregex_inv="${regex_hcp7t}|${regex_lifespan}"
fi

if [ ! "x${sessionregex}" = x ]; then
	SessionGrep=" | grep -E -- '${sessionregex}'"
fi
if [ ! "x${sessionregex_inv}" = x ]; then
	SessionGrep="${SessionGrep} | grep -vE -- '${sessionregex_inv}'"
fi


whichscanner=`echo $whichscanner $DefaultScanner | awk '{print $1}'`
local scannerarg=`echo $whichscanner | tr "[a-z]" "[A-Z]"`
case $scannerarg in
	PRISMA )
		ScannerName=Prisma
		GradientDistortionCoeffs=$gdcPrisma
		;;
	7TAS )
		ScannerName=7TAS
		GradientDistortionCoeffs=$gdc7T
		;;
	CONNECTOMS )
		ScannerName=ConnectomS
		GradientDistortionCoeffs=$gdcConnectomS
		;;
	TRIO )
		ScannerName=Trio
		GradientDistortionCoeffs=$gdcTrio
		;;
	10T5 )
		ScannerName=10T5
		GradientDistortionCoeffs=
		;;
	* )
		show_help_StudySettings;
		echo ""
		echo "**** Unknown scanner name: ${whichscanner} **** "
		echo ""
		unset ${to_export}
		return
esac

######################################################################

StructuralUnwarpDir="z" #z appears to be best or "NONE" if not used

fMRI_HPF=2000

#Config Settings
BrainSize="150" #BrainSize in mm, 150 for humans

#AvgrdcSTRING="FIELDMAP" #Averaging and readout distortion correction methods: "NONE" = average any repeats with no readout correction "FIELDMAP" = average any repeats and use field map for readout correction "TOPUP" = average and distortion correct at the same time with topup/applytopup only works for 2 images currently
AvgrdcSTRING="NONE" # = Distortion correction for Structural pipeline

GrayordinatesResolution_32k="2" #Usually 2mm
LowResMesh_32k="32" #Usually 32k vertices
GrayordinatesTemplate_32k="91282_Greyordinates"

GrayordinatesResolution_59k="1.6" #Usually 2mm
LowResMesh_59k="59" #Usually 32k vertices
GrayordinatesTemplate_59k="170494_Greyordinates" #(Need to copy these in)

HighResMesh="164" #Usually 164k vertices

GrayordinatesResolution_32k=${GrayordinatesResolution_32k}
LowResMesh=${LowResMesh_32k}
GrayordinatesTemplate=${GrayordinatesTemplate_32k}
####################################################################
TemplateSize=0.8mm

T1wSampleSpacing="0.0000074" #DICOM field (0019,1018) in s or "NONE" if not used # 0.8mm Prisma
T2wSampleSpacing="0.0000021" #DICOM field (0019,1018) in s or "NONE" if not used # 0.8mm Prisma

#defaults... though these get set automatically in the functional pipeline wrapper script
PEpos_y=PA
PEneg_y=AP
PEpos_x=RL
PEneg_x=LR

UnwarpAxis=y
PEpos=${PEpos_y}
PEneg=${PEneg_y}


DOF_EPI2T1=6
FinalfMRIResolution=2.00
FinalDWIResolution=1.50

EPIScoutType="SBREF"
EPIDistortionCorrection="TOPUP"

#for Prisma and Skyra
DwellTime="0.00058" #Echo Spacing or Dwelltime of fMRI image
StructuralDwellTime="NONE"

DWIDwellTime=".00069" #DWI Dwell time (seconds) for Prisma lifespan

########### Not including IPAT
#3t
#EchoSpacing="0.69" #Echo Spacing in msec for DWI (divided by 1000 in basic_preproc.sh)
#7t
#EchoSpacing="0.25" #Echo Spacing in msec for DWI (divided by 1000 in basic_preproc.sh)

############# Not including IPAT = 1/(bpppe*npe)
# Christoph used .27 in script for 7THCP DWI
# Tim Brown used .32 in script for 7THCP fMRI
#	= this is what is extracted as "echospacing" in intradb
#7THCP (ipat2)          = .32 = .0003200061
#7TLS (ipat2)           = .32 = .0003200061
#3TLS (ipat1)           = .58 = .0005800087
#DWI 7THCP (ipat3)      = .27 = .0002733285
#DWI 7TLS (ipat3)       = .25 = .0002466694
#DWI 3TLS (ipat1)       = .69 = .0006899977
#MBME Prisma (ipat2)    = .245

############# Multiplying IPAT = ipat/(bpppe*npe) (this is shown on the scanner)
#7THCP (ipat2)          = .64 = .0006400122
#7TLS (ipat2)           = .64 = .0006400122
#3TLS (ipat1)           = .58 = .0005800087
#DWI 7THCP (ipat3)      = .82 = .0008199857
#DWI 7TLS (ipat3)       = .74 = .0007400084
#DWI 3TLS (ipat1)       = .69 = .0006899977
#MBME Prisma (ipat2)    = .49

DeltaTE="2.46" #GRE fieldmap: 2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
StructuralDeltaTE="NONE"

case ${studyarg}@${scannerarg} in
	BSLERP@* )
		BrainSize="130" #BrainSize in mm, 120-130 for babies
		FinalDWIResolution=1.50
		;;
	MBME@PRISMA )
	  	T1wSampleSpacing="0.0000023" #DICOM field (0019,1018) in s or "NONE" if not used # 0.8mm Prisma
  		T2wSampleSpacing="0.0000023" #DICOM field (0019,1018) in s or "NONE" if not used # 0.8mm Prisma
		DwellTime="0.00058" #Echo Spacing or Dwelltime of SE fieldmaps
		#I think this is what should be used in topup, but a different value may be needed for applytopup
		;;
	MPS@TRIO )
		FinalfMRIResolution=3.50
		DwellTime="0.00043" #Echo Spacing or Dwelltime of fMRI image
		#how to make sure GRE fieldmap is used....
		EPIDistortionCorrection="FIELDMAP"
		DeltaTE=2.46
		;;
	HCP3T@CONNECTOMS )
		FinalDWIResolution=1.25
		TemplateSize=0.7mm
		UnwarpAxis=x
		PEpos=${PEpos_x}
		PEneg=${PEneg_x}
		AvgrdcSTRING=FIELDMAP
		;;
	LIFESPAN@CONNECTOMS )
		TemplateSize=0.8mm
		UnwarpAxis=x
		PEpos=${PEpos_x}
		PEneg=${PEneg_x}
		FinalDWIResolution=1.50
		;;
	LIFESPAN@7TAS )
		DOF_EPI2T1=12
		DwellTime="0.00032" #Echo Spacing or Dwelltime of fMRI image
		FinalfMRIResolution=1.60
		DeltaTE="1.02" #GRE fieldmap: 2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
		DWIDwellTime=".0002466694"
		FinalDWIResolution=1.25
		;;
	HCP7T@7TAS )
		DOF_EPI2T1=12
		DwellTime="0.00032" #Echo Spacing or Dwelltime of fMRI image
		FinalfMRIResolution=1.60
		DeltaTE="1.02" #GRE fieldmap: 2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
		DWIDwellTime=".0002733285"
		FinalDWIResolution=1.05
		;;
	HIGHRES@* )
		TemplateSize=0.6mm
		;;
	* )
		;;
esac


SmoothingFWHM=${FinalfMRIResolution}

echo
echo "StudySettings: ${whichstudy}@${ScannerName}"
echo

# Requirements for this script
#  installed versions of: FSL5.0.2 or higher , FreeSurfer (version 5.2 or higher) , gradunwarp (python code from MGH)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript} &> /dev/null

  #Scan Settings


TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP

SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases" #(Need to rename make surf.gii and add 32k)
GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/${GrayordinatesTemplate}" #(Need to copy these in)
SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"

LogFileDir=`pwd`/logs_${whichstudy}
#LogFileDir=${StudyFolder}/logs
FSLSUBOPTIONS="-l ${LogFileDir}"

export ${to_export}

}

#must be a function to avoid passing local variables back to parent script
#must unset this function and any inside it, otherwise they are global
StudySettings $@
unset -f StudySettings
unset -f show_help_StudySettings

