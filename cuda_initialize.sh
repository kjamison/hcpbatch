#!/bin/bash

#export CUDA=/opt/local/cuda-6.5.14
export CUDA=/opt/local/cuda-5.5

CUDALIB=${CUDA}/lib64
CUDABIN=${CUDA}/bin

if [[ ! ":${LD_LIBRARY_PATH}:" == *:${CUDALIB}:* ]]; then
	export LD_LIBRARY_PATH=${CUDALIB}:${LD_LIBRARY_PATH}
fi

#if [[ ! ":${PATH}:" == *:${CUDABIN}:* ]]; then
#	export PATH=${CUDABIN}:${PATH}
#fi

