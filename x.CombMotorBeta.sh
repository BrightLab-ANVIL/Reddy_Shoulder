#!/bin/bash
#This script creates a combined motor beta coef map from beta coef maps of a motor task regressor and its derivative

#Check if the inputs are correct
if [ $# -ne 7 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the input folder for the beta coef maps"
  echo "Input 2 should be the task regressor beta coef file name (.nii.gz file)"
  echo "Input 3 should be the task regressor derivative beta coef file name (.nii.gz file)"
  echo "Input 4 should be the task regressor (.1D file)"
  echo "Input 5 should be the derivative of the task regressor (.1D file)"
  echo "Input 6 should be the output folder"
  echo "Input 7 should be the output file prefix"
  exit
fi

input_folder="${1}"
stim_bcoef="${2}"
deriv_bcoef="${3}"
stim_reg="${4}"
deriv_reg="${5}"
output_folder="${6}"
output_prefix="${7}"

# calculate a combined motor time series
3dcalc -a ${stim_bcoef} \
  -b ${stim_reg} \
  -c ${deriv_bcoef} \
  -d ${deriv_reg} \
  -expr 'a*b + c*d' \
  -prefix "${output_folder}/${output_prefix}_MotorComb_TS.nii.gz"
    
# now get a new beta coef map from the combined motor time series by finding the range
fslmaths "${output_folder}/${output_prefix}_MotorComb_TS.nii.gz" -Tmax "${output_folder}/${output_prefix}_MotorComb_TS_max.nii.gz"
fslmaths "${output_folder}/${output_prefix}_MotorComb_TS.nii.gz" -Tmin "${output_folder}/${output_prefix}_MotorComb_TS_min.nii.gz"
fslmaths "${output_folder}/${output_prefix}_MotorComb_TS_max.nii.gz" -sub "${output_folder}/${output_prefix}_MotorComb_TS_min.nii.gz" \
    "${output_folder}/${output_prefix}_MotorComb_bcoef.nii.gz"
       