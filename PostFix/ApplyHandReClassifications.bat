Subjlist="102311 131217 137128 145834 167036 176542 177645 178142 181232 191841 196144 197348 205220 212419 214019 251833 365343 547046 690152 770352 782561 859671 899885 901139 910241"
#Subjlist="102311"
StudyFolder="/media/myelin/brainmappers/Connectome_Project/7T_FixTraining"

FunctionalNames="REST_REST1_PA REST_REST2_AP REST_REST3_PA REST_REST4_AP"
#FunctionalNames="REST_REST1_PA"

HighPass="2000"
GitRepo="/media/2TBB/Connectome_Project/Pipelines"

for Subject in ${Subjlist} ; do
  for FunctionalName in ${FunctionalNames} ; do
    "$GitRepo"/ApplyHandReClassifications.sh ${StudyFolder} ${Subject} ${FunctionalName} ${HighPass}
    echo "set -- ${StudyFolder} ${Subject} ${FunctionalName} ${HighPass}"
  done
done

