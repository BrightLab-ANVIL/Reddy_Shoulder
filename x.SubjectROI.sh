#!/bin/bash
#This script creates a subject-specific ROI from the top X% of statistics within a mask

#Check if the inputs are correct
if [ $# -ne 6 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the input folder for the statistic file"
  echo "Input 2 should be the input statistic (ex. Fstat, tstat) file prefix in func space (don't include .nii.gz)"
  echo "Input 3 should be the binarized region mask in func space"
  echo "Input 4 should be the name of the region"
  echo "Input 5 should be the percentile to threshold at (ex. input '90' for top 10% stats)"
  echo "Input 6 should be the output folder"
  exit
fi

input_folder="${1}"
input_stat="${2}"
mask="${3}"
mask_name="${4}"
above="${5}"
output_folder="${6}"


3dcalc -a ${input_folder}/${input_stat}.nii.gz -b ${mask} -expr 'a*b' -prefix ${input_folder}/${input_stat}_${mask_name}.nii.gz # extract mask area of stat file
fslmaths ${input_folder}/${input_stat}_${mask_name}.nii.gz -thrP ${above} ${output_folder}/${input_stat}_${mask_name}.nii.gz # find top X% of stats within mask
