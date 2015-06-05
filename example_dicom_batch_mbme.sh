cmd="bash Default/batch_dicom_init.sh mbme ~/range3hcp/20150427-ST001-jamison_mbme1/ subjEK "

#eval "$cmd rfMRI_REST1_2mm_PA                  BOLD=12 SE=13,14"
#eval "$cmd rfMRI_REST1_MB4R2ME3_2.5mm6_8pf_PA  BOLD=16 SE=13,14"
#eval "$cmd rfMRI_REST1_2.5mm_PA                BOLD=18 SE=13,14"

eval "$cmd REST2_2.5mm_MB4R2ME3_6_8pf_PA  BOLD=29 SE=34,35"
eval "$cmd REST2_2.5mm_PA 	       BOLD=31 SE=34,35"
eval "$cmd REST2_2.0mm_PA 	       BOLD=33 SE=34,35"
eval "$cmd REST2_3.0mm_PA 	       BOLD=37 SE=34,35"
eval "$cmd REST2_3.0mm_MB4R2ME3_7_8pf_PA    BOLD=39 SE=34,35"


