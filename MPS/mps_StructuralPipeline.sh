#!/bin/bash

set -e

Subject_all=$1 #Space delimited list of subject IDs


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/mps_PreFreeSurferPipeline.sh "${Subject_all}"
. ${DIR}/mps_FreeSurferPipeline.sh "${Subject_all}"
. ${DIR}/mps_PostFreeSurferPipeline.sh "${Subject_all}"
