#!/bin/bash

for i in `seq 1 2 10`; do
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $i` REST1_PA surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $i` REST2_AP surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $i` REST3_PA surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $i` REST4_AP surface surface &

	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $((i+1))` REST1_PA surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $((i+1))` REST2_AP surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $((i+1))` REST3_PA surface surface &
	bash hcpkj_runjob.sh `getline ~/Data2/goodsubj.txt $((i+1))` REST4_AP surface surface &
	
	sleep 1800;
done

