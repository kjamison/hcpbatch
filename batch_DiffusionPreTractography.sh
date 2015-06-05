#!/bin/bash 

set -e

Subjlist=$1
StudyFolder="/home/range1-raid1/kjamison/Data/Lifespan" #Location of Subject folders (named by subjectID)
EnvironmentScript="/home/range1-raid1/kjamison/Source/PipelineBatch/SetUpHCPPipeline.sh" #Pipeline environment script

#Set up pipeline environment variables and software
. ${EnvironmentScript} &> /dev/null

# Log the originating call
echo "$@"

#Assume that submission nodes have OPENMP enabled (needed for eddy - at least 8 cores suggested for HCP data)
#if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q verylong.q"
#fi

PRINTCOM=""

RUN=
for Subject in $Subjlist ; do
	#${RUN} ${HCPPIPEDIR}/DiffusionTractography/PreTractography.sh ${StudyFolder} ${Subject}
	${RUN} ${HCPPIPEDIR}/DiffusionTractography/RunMatrix1.sh ${StudyFolder} ${Subject}
	#${RUN} ${HCPPIPEDIR}/DiffusionTractography/RunMatrix2.sh ${StudyFolder} ${Subject}
	#${RUN} ${HCPPIPEDIR}/DiffusionTractography/RunMatrix3.sh ${StudyFolder} ${Subject}
done

