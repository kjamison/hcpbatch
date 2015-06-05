Subjlist="102311 131217 137128 145834 167036 176542 177645 178142 181232 191841 196144 197348 205220 212419 214019 251833 365343 547046 690152 770352 782561 859671 899885 901139 910241"
#Subjlist="102311"
StudyFolder="/media/myelin/brainmappers/Connectome_Project/7T_FixTraining"

FunctionalNames="REST_REST1_PA REST_REST2_AP REST_REST3_PA REST_REST4_AP"
GitRepo="/media/2TBB/Connectome_Project/Pipelines"
HighPass="2000"
Caret7_Command="wb_view"
for Subject in ${Subjlist} ; do
  for FunctionalName in ${FunctionalNames} ; do
    if [ -s ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/NonMatching.txt ] ; then
      NonMatching=`cat ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/NonMatching.txt`
      #NonMatching=`cat ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/ReclassifyAsSignal.txt`
      echo "${Caret7_Command} -scene-load ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/${Subject}_${FunctionalName}_ICA_Classification_singlescreen.scene 1 &"
      #echo "firefox ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/${FunctionalName}_hp${HighPass}.ica/filtered_func_data.ica/report/00index.html &"
      echo "nautilus ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName} &"
      echo "${NonMatching}"
    fi
  done
done

