## Whole-brain precision functional mapping of a proximal upper-extremity motor task
This analysis code is shared alongside the manuscript found here: 

Relevant data files can be found on OpenNeuro: 

## Code
### MRI pre-processing and registration
All anatomical and functional MRI pre-processing and registration scripts can be found at https://github.com/BrightLab-ANVIL/PreProc_BRAIN

Detailed information on tedana and multi-echo fMRI analysis can be found at https://tedana.readthedocs.io

Code used to create, automatically classify, and conservatively orthogonalize ME-ICA regressors can be found at https://github.com/BrightLab-ANVIL/MotorMEICAModeling

### Subject-level fMRI analysis
x.GLM_REML_1run.sh: Subject-level modeling with 1 run (Used for: Each run of Medium torque, hand grasp task)

x.GLM_REML_2run.sh: Subject-level modeling with 2 runs (Used for: Analysis of 2 runs of Low and High torque tasks in all subjects, 2 runs of Medium torque task in sub-05)

x.GLM_REML_3run.sh: Subject-level modeling with 3 runs (Used for: Analysis of 3 runs of Medium torque task in all subjects other than sub-05)

x.GLM_REML_6run.sh: Subject-level modeling with 6 runs (Used for: Analysis of all 6 shoulder abduction runs in sub-05)

x.GLM_REML_7run.sh: Subject-level modeling with 7 runs (Used for: Analysis of all 7 shoulder abduction runs in all subjects other than sub-05)

x.SubjectROI.sh: Creation of subject-specific ROIs from top 10% of F-statistics

x.CombMotorBeta.sh: Calculation of combined motor beta coefficient

### Group-level fMRI analysis
x.GLM_Group_3dMVM.sh: Group-level modeling
