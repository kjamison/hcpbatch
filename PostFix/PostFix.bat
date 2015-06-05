Subjlist="102311 131217 137128 145834 167036 176542 177645 178142 181232 191841 196144 197348 205220 212419 214019 251833 365343 547046 690152 770352 782561 859671 899885 901139 910241"
#Subjlist="102311"
StudyFolder="/media/myelin/brainmappers/Connectome_Project/7T_FixTraining"

FunctionalNames="REST_REST1_PA REST_REST2_AP REST_REST3_PA REST_REST4_AP"
#FunctionalNames="REST_REST1_PA"

GitRepo="/media/2TBB/Connectome_Project/Pipelines"
HighPass="2000"
Caret7_Command="wb_command"
TemplateSceneDualScreen="/media/myelin/brainmappers/Connectome_Project/HCP_Phase2/Scripts/ICA_Classification_DualScreenTemplate.scene"
TemplateSceneSingleScreen="/media/myelin/brainmappers/Connectome_Project/7T_FixTraining/Scripts/ICA_Classification_SingleScreenTemplate.scene"

NotReady=""
Done=""
for Subject in ${Subjlist} ; do
  for FunctionalName in ${FunctionalNames} ; do
    if [ -e ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/${FunctionalName}_Atlas_hp${HighPass}_clean.dtseries.nii ]; then
      if [ ! -e ${StudyFolder}/${Subject}/MNINonLinear/Results/${FunctionalName}/${Subject}_${FunctionalName}_ICA_Classification_singlescreen.scene ] ; then
        fsl_sub -q veryshort.q "$GitRepo"/PostFix.sh ${StudyFolder} ${Subject} ${FunctionalName} ${GitRepo} ${HighPass} ${Caret7_Command} ${TemplateSceneDualScreen} ${TemplateSceneSingleScreen}
        echo "set -- ${StudyFolder} ${Subject} ${FunctionalName} ${GitRepo} ${HighPass} ${Caret7_Command} ${TemplateSceneDualScreen} ${TemplateSceneSingleScreen}"
      else
        Done=`echo "$Done""$Subject"" ""$FunctionalName"" "`
      fi
    else
      NotReady=`echo "$NotReady""$Subject"" ""$FunctionalName"" "`
    fi
  done
done
echo "These Subjects and Runs Are Not Ready: ""$NotReady"
echo "These Subjects and Runs Are Done: ""$Done"
