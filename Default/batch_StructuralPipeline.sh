#!/bin/bash

set -e

STUDYNAME=$1
Subject_all=$2 #Space delimited list of subject IDs


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/batch_PreFreeSurferPipeline.sh $STUDYNAME "${Subject_all}"
. ${DIR}/batch_FreeSurferPipeline.sh $STUDYNAME "${Subject_all}"
. ${DIR}/batch_PostFreeSurferPipeline.sh $STUDYNAME "${Subject_all}"

