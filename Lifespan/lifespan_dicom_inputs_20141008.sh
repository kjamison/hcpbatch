#!/bin/bash

#"$0 <subjid> REST REST1_AP <SBscan> <MBscan> <PASEscan> <APSEscan>"
cmd=`dirname $0`/lifespan_dicom_init.sh
cmd="bash $cmd"

${cmd} LS7059_3T REST REST1_AP 11 12 9 10
${cmd} LS7059_3T REST REST1_PA 13 14 9 10
${cmd} LS7059_3T REST REST2_PA 25 26 23 24
${cmd} LS7059_3T REST REST2_AP 27 28 23 24

${cmd} LS7071_3T REST REST1_AP 11 12 9 10
${cmd} LS7071_3T REST REST1_PA 13 14 9 10
${cmd} LS7071_3T REST REST2_AP 33 34 31 32
${cmd} LS7071_3T REST REST2_PA 35 36 31 32

