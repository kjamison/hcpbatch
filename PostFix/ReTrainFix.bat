Subjlist="102311 131217 137128 145834 167036 176542 177645 178142 181232 191841 196144 197348 205220 212419 214019 251833 365343 547046 690152 770352 782561 859671 899885 901139 910241"
#Subjlist="102311"
StudyFolder="/media/myelin/brainmappers/Connectome_Project/7T_FixTraining"

FunctionalNames="REST_REST1_PA REST_REST2_AP REST_REST3_PA REST_REST4_AP"
#FunctionalNames="REST_REST1_PA"
HighPass="2000"
GitRepo="/media/2TBB/Connectome_Project/Pipelines"
OutputNameString="REST1+REST2+REST3+REST4"
#ValidationString="REST3+REST4"


FIXreTrainSTRING=""
for Subject in ${Subjlist} ; do
  for FunctionalName in ${FunctionalNames} ; do
    #Naming Conventions
    AtlasFolder="${StudyFolder}/${Subject}/MNINonLinear"
    ResultsFolder="${AtlasFolder}/Results/${FunctionalName}"
    ICAFolder="${ResultsFolder}/${FunctionalName}_hp${HighPass}.ica/filtered_func_data.ica"
    FIXFolder="${ResultsFolder}/${FunctionalName}_hp${HighPass}.ica"

    FIXreTrainSTRING=`echo "$FIXreTrainSTRING""$FIXFolder"" "`
  done
done

echo "${GitRepo}/fix1.06/fix -t ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass} -l $FIXreTrainSTRING"
${GitRepo}/fix1.06/fix -t ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass} -l $FIXreTrainSTRING

${GitRepo}/fix1.06/fix -C ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass}.RData ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass}_validation $FIXreTrainSTRING

#Independent Classification Check
#${GitRepo}/fix1.06/fix -C ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass}.RData${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass}_validation_with_${ValidationString} $FIXreTrainSTRING

#Leave One Out Testing
#${GitRepo}/fix1.06/fix -t ${GitRepo}/fix1.06/training_files/HCP_PhaseII_${OutputNameString}_hp${HighPass} -l $FIXreTrainSTRING

