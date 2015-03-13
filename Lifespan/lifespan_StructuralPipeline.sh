#!/bin/bash

set -e

Subject_all=$1 #Space delimited list of subject IDs


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/lifespan_PreFreeSurferPipeline.sh "${Subject_all}"
. ${DIR}/lifespan_FreeSurferPipeline.sh "${Subject_all}"
. ${DIR}/lifespan_PostFreeSurferPipeline.sh "${Subject_all}"
