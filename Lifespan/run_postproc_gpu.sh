#!/bin/sh

subjdir=$1
bet2thrfinal=$2

echo "Preparing directory for bedpostX"
mkdir -p ${subjdir}/data

eddydir=${subjdir}/eddy

cp ${eddydir}/AP.bval ${subjdir}/data/bvals
cp ${eddydir}/AP.bvec ${subjdir}/data/bvecs

dimt=`${FSLDIR}/bin/fslval ${eddydir}/eddy_unwarped dim4`
dimt=`echo "scale=0; ${dimt} / 2" | bc -l`

fslroi ${eddydir}/eddy_unwarped ${subjdir}/data1 0 $dimt
fslroi ${eddydir}/eddy_unwarped ${subjdir}/data2 $dimt -1
fslmaths ${subjdir}/data1 -add ${subjdir}/data2 -div 2 ${subjdir}/data/data

bet2 ${subjdir}/data/data ${subjdir}/data/nodif_brain -m -f ${bet2thrfinal}

imrm ${subjdir}/data1
imrm ${subjdir}/data2

mkdir -p ${subjdir}/data.bedpostX

echo "Checking bedpostX directory"
bedpostx_datacheck ${subjdir}/data

