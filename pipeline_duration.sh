#!/bin/bash


#Subjlist="137128 547046 365343" #"196144" 

Subjlist=$@
StudyFolder="/home/range1-raid1/kjamison/Data2/Phase2_7T" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/hcp_pipeline/SetUpHCPPipeline.sh" #Pipeline environment script

if [ "X$Subjlist" == X ]; then
  Subjlist=`ls ${StudyFolder}`
fi


###########################################

function parsetime {
	hh=`echo $1 | sed 's/://g' | cut -c "1 2" | bc`
	mm=`echo $1 | sed 's/://g' | cut -c "3 4" | bc`
	ss=`echo $1 | sed 's/://g' | cut -c "5 6" | bc`

	if (( $hh > 12 )); then
		hh=`echo $hh - 12 | bc`
		ampm=PM
	elif (( $hh == 12 )); then
		ampm=PM
	elif (( $hh == 0 )); then
    hh=12
		ampm=AM
	else
		hh=`echo $hh | bc`
    ampm=AM
	fi

	printf "%s:%02d %s" ${hh} ${mm} ${ampm}
	return 0
}

function parsedate {
	yyyy=`echo $1 | sed 's#-/##g' | cut -c "1 2 3 4"`
	mm=`echo $1 | sed 's#-/##g' | cut -c "5 6"`
	dd=`echo $1 | sed 's#-/##g' | cut -c "7 8"`
	
	printf "%s-%s-%s" ${yyyy} ${mm} ${dd}
	return 0
}

function filemod_elapse {
  file1=$1
  file2=$2

  #if [ ! -e ${file1} ]; then
    #return 0
  #elif [ ! -e ${file2} ]; then
    #return 0
  #fi

  t1date=
  t1time=
  t2date=
  t2time=
  s1=
  s2=?
  s3=?
  t1=0
  t2=0

  if [ X${file1} != X ] && [ -e ${file1} ]; then
    t1date=`stat --format="%y" ${file1} | awk '{print $1}' | sed 's/-//g'`
    t1time=`stat --format="%y" ${file1} | awk '{print $2}' | sed 's/://g'`
    t1=`stat --format="%Y" ${file1}`
    s1=`parsedate $t1date`
    s2=`parsetime $t1time | sed 's/ //g'`
  fi

  if [ X${file2} != X ] && [ -e ${file2} ]; then
    t2date=`stat --format="%y" ${file2} | awk '{print $1}' | sed 's/-//g'`
    t2time=`stat --format="%y" ${file2} | awk '{print $2}' | sed 's/://g'`
    t2=`stat --format="%Y" ${file2}`
    if [ -z ${s1} ]; then
      s1=`parsedate $t2date`
    fi
    s3=`parsetime $t2time | sed 's/ //g'`
  fi

  timestr=`printf "%s-%s" ${s2} ${s3}`
  fullstr=`printf "%-18s %-15s" "${timestr}" ${s1}`
  
  if (( $t1 == 0 || $t2 == 0 )); then
    dur=0
    durstr=`printf "%10s" "?"`
  else
    dur=`echo "scale=2; ( $t2 - $t1 )/(60*60)" | bc`
    durstr=`printf "%10.2f%s" $dur " hr"`
  fi

  printf "%15s           %s\n" "$durstr" "$fullstr"
  return 0
}

###########################################

SessFolder="REST"

PEpos=PA
PEneg=AP

#Tasklist=(1_PA 2_AP 3_PA 4_AP)
#PhaseEncodinglist="y -y y -y"

AtlasSpaceFolder="MNINonLinear"
ResultsFolder="Results"

#PA = +y,   AP = -y
#Tasklist=(REST1 REST2 REST3 REST4 REST1algo1 REST1algo2 REST1algo3 REST1algo4)
#PhaseEncodinglist="y -y y -y y y y y"

#ScanName_all="REST1algo1_PA REST1algo2_PA REST1algo3_PA REST1algo4_PA"

#ScanName_all="REST1_PA REST2_AP REST3_PA REST4_AP"

ScanName_all="MOVIE1_AP MOVIE2_PA MOVIE3_PA MOVIE4_AP"

for Subject in $Subjlist ; do
  i=0
 # for fMRIName in $Tasklist ; do

  #for ii in ${!Tasklist[@]} ; do

    #UnwarpDir=`echo $PhaseEncodinglist | cut -d " " -f $((ii+1))`    
    #if [ ${UnwarpDir} == "y" ]; then
    #  PEdir=${PEpos}
    #else
    #  PEdir=${PEneg}
    #fi

    #fMRIName="${SessFolder}_${Tasklist[$ii]}_${PEdir}"

#############
    for ScanName in $ScanName_all; do
        TaskName=`echo ${ScanName} | sed 's/_[APLR]\+$//'`

        SessFolder=`echo ${ScanName} | sed 's/[0-9]\+_[APLR]\+$//'`

        if [[ ${ScanName} == *_${PEpos} ]]; then
	        PEdir=${PEpos}
	        UnwarpDir=y
        elif [[ ${ScanName} == *_${PEneg} ]]; then
	        PEdir=${PEneg}
	        UnwarpDir=-y
        else
	        echo "unknown PE direction: "${ScanName}
	        exit 0
        fi

        fMRIName="${SessFolder}_${ScanName}"

        niidir="${StudyFolder}/${Subject}/unprocessed/${SessFolder}"
#############



    subjAtlasSpaceFolder="${StudyFolder}"/"${Subject}"/"${AtlasSpaceFolder}"
    subjResultsFolder="${subjAtlasSpaceFolder}"/"${ResultsFolder}"/"${fMRIName}"
    SessionFolder="${StudyFolder}"/"${Subject}"/"${fMRIName}"

    if [ ! -e ${SessionFolder} ]
    then
      continue
    fi
    echo
    echo "${SessionFolder}"

    firstmat="MAT_0000"
    if [ -e ${SessionFolder}/MotionMatrices ]; then
      lastmat=`ls ${SessionFolder}/MotionMatrices | grep 'MAT_[0-9]\+$' | tail -n 1`
      if [ X${lastmat} != X ]; then
        mctime=`filemod_elapse "${SessionFolder}/MotionMatrices/${firstmat}" "${SessionFolder}/MotionMatrices/${lastmat}"`
      else
        mctime=`filemod_elapse "${SessionFolder}/MotionMatrices/${firstmat}"`
      fi
    else
      mctime=
    fi

    topupdir="${SessionFolder}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased"
    if [ -e $topupdir ]; then
      f1=`ls ${topupdir} | grep '^T1w_acpc_dc'`
      if [ X${f1} != X ]; then
        dctime=`filemod_elapse ${topupdir}/${f1} ${topupdir}/log.txt`
      else
        dctime=`filemod_elapse`
      fi
    else
      dctime=
    fi

    resampledir="${SessionFolder}/OneStepResampling"
    if [ -e ${resampledir} ]; then
      pre1=`ls ${resampledir}/prevols | grep '^vol0000\.' | head -n 1`
      pre2=`ls ${resampledir}/prevols | grep '^vol[0-9]\+\.' | tail -n 1`
      pre2num=`echo $pre2 | sed 's/vol//' | sed 's/[^0-9]\+$//' | bc`
      post2=`ls ${resampledir}/postvols | grep "^vol${pre2num}\."`
      
      jac=`ls ${SessionFolder} | grep '^Jacobian_MNI.*\.nii'`

      f1str=
      f2str=
      if [ X${pre1} != X ]; then
        f1str=${resampledir}/prevols/${pre1}
      fi
      #if [ X${post2} != X ]; then
      #  f2str=${resampledir}/postvols/${post2}
      #fi

      if [ X${jac} != X ]; then
        f2str=${SessionFolder}/${jac}
      fi

      resampletime=`filemod_elapse ${f1str} ${f2str}`
    else
      resampletime=
    fi

    printf "  %-8s %s\n" "moco" "${mctime}"
    printf "  %-8s %s\n" "topup" "${dctime}"
    printf "  %-8s %s\n" "resample" "${resampletime}"

    if [ ! -e ${subjResultsFolder} ]
    then
      continue
    fi
 
    
    #echo "${subjResultsFolder}"

    if [ -e ${subjResultsFolder}/RibbonVolumeToSurfaceMapping ]; then
        f1=`ls ${subjResultsFolder}/RibbonVolumeToSurfaceMapping | grep '^ribbon_only\.nii'`
        f2=`ls ${subjResultsFolder} | grep "^${fMRIName}_Atlas\.dtseries\.nii"`
        if [ X${f1} != X ]; then
            if [ X${f2} != X ]; then
                surftime=`filemod_elapse ${subjResultsFolder}/RibbonVolumeToSurfaceMapping/${f1} ${subjResultsFolder}/${f2}`
            else
                surftime=`filemod_elapse ${subjResultsFolder}/RibbonVolumeToSurfaceMapping/${f1}`
            fi
            
        else
            surftime=
        fi
    else
        surftime=
    fi

    printf "  %-8s %s\n" "surface" "${surftime}"

    f1="hpfstart.txt"
    f2=`ls ${subjResultsFolder} | grep "^${fMRIName}_hp[0-9]\+"\.nii`
    if [ X${f2} != X ]; then
        hpftime=`filemod_elapse ${subjResultsFolder}/${f1} ${subjResultsFolder}/${f2}`
    else
        hpftime=`filemod_elapse ${subjResultsFolder}/${f1}`
    fi
    

    icadir=`remove_ext ${f2}`
    icafile1=`printf "%s/%s.ica/filtered_func_data.ica/report/head.html" ${subjResultsFolder} ${icadir}`
    #icafile2=`printf "%s/%s.ica/filtered_func_data.ica/report/00index.html" ${subjResultsFolder} ${icadir}`
    icafile2=`printf "%s/%s.ica/mc/prefiltered_func_data_mcf.par" ${subjResultsFolder} ${icadir}`
    icatime=`filemod_elapse $icafile1 $icafile2`

    printf "  %-8s %s\n" "hpf" "${hpftime}"    
    printf "  %-8s %s\n" "melodic" "${icatime}"
    
  done
done

echo


