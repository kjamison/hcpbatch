cmd="bash batch_dicom_init.sh mbme ~/range3hcp/20150427-ST001-MBMETEST/ SUBJ01 "

SE="34,35"

eval "$cmd REST2_2.5mm_MB4R2ME3_6_8pf_PA   BOLD=29 SE=$SE"
eval "$cmd REST2_2.5mm_PA                  BOLD=31 SE=$SE"
eval "$cmd REST2_2.0mm_PA                  BOLD=33 SE=$SE"
eval "$cmd REST2_3.0mm_PA                  BOLD=37 SE=$SE"
eval "$cmd REST2_3.0mm_MB4R2ME3_7_8pf_PA   BOLD=39 SE=$SE"

