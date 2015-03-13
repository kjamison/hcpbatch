#!/bin/bash


machines="atlas6 atlas7 atlas8 euclid"
#machines="atlas5 atlas6 atlas7 atlas8 gpu4hcp euclid asaf"
#machines="atlas7"

for m in $machines; do
	cpustat $m
done

