# hcpbatch
Flexible wrapper for [HCP pipeline](https://github.com/Washington-University/Pipelines) batch jobs.  Adapted from [HCP example scripts](https://github.com/Washington-University/Pipelines/tree/master/Examples/Scripts) that are provided with the pipeline.
Some of these wrapper scripts rely on features added to [my personal fork of the HCP pipelines](https://github.com/kjamison/Pipelines), and will not work with the official distribution.

Before running, you will need to edit these files for your own installation:

* `SetUpHCPPipeline.sh` : points to local pipeline installation, FSL binaries, etc...
* `batch_StudySettings.sh` : specifies study- or scanner-specific settings (study root directory, final volume and surface resolutions, gradient coefficients, etc...)


General syntax for calling these scripts is:
`bash <scriptname> <studyname>@<magnetname> <subjectID> ...`

If your DICOM session is `<dicomfolder>/scan1` `<dicomfolder>/scan2` etc., these scripts will import and convert your dicoms into an HCP-friendly file structure:

```
dicomfolder=/path/to/dicomstorage/mysession
subjectid=101202
study=lifespan@prisma
bash batch_dicom_init.sh $study $dicomfolder $subjectid REST1_AP BOLD=7 SE=8,10
bash batch_anat_dicom_init.sh $study $dicomfolder $subjectid T1=12 T2=14
bash batch_diffusion_dicom_init.sh $study $dicomfolder $subjectid 16 18 20 22
```

After importing and converting dicoms, you can execute the structural, diffusion, and functional preprocessing pipelines as follows:
```
bash batch_StructuralPreprocessing.sh $study $subjectid
#Note: You MUST run and complete the structural pipeline before running the diffusion and functional pipelines.
bash batch_DiffusionPreprocessing.sh $study $subjectid
bash batch_FunctionalPreprocessing.sh $study $subjectid
```


You can also invoke these for multiple subjects to run serially, e.g.,:

`bash batch_FunctionalPreprocessing.sh lifespan@prisma "101202 303404 505606"`
