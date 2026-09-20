#!/bin/bash
#This script uses subject-level beta coefficient maps from the task regressor and its derivative to create a group-level general linear model using AFNI.

#Check if the inputs are correct
if [ $# -ne 7 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the input folder for the beta coef maps in MNI space"
  echo "Input 2 should be the task regressor beta coef file names"
  echo "Input 3 should be the task regressor derivative beta coef file names"
  echo "Input 4 should be the brain mask"
  echo "Input 5 should be the subject IDs"
  echo "Input 6 should be the output prefix"
  echo "Input 7 should be the output directory"
  exit
fi

input_prefix="${1}"
beta_suffix="${2}"
beta_deriv_suffix="${3}"
brain_mask="${4}"
sub_IDs="${5}"
output_prefix="${6}"
output_dir="${7}"

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

if [ ! -f ${output_dir}/"3dMVM_${output_prefix}.nii.gz" ]
then

datatable_file="${output_dir}/datatable.txt"
echo -e "Subj\tComponent\tInputFile" > "${datatable_file}"

for subject in ${sub_IDs}
do
      beta="${input_prefix}/${subject}_${beta_suffix}.nii.gz"
      beta_deriv="${input_prefix}/${subject}_${beta_deriv_suffix}.nii.gz"
              
      echo -e "${subject}_${task}\tStim\t${beta}"   >> "${datatable_file}"
      echo -e "${subject}_${task}\tDeriv\t${beta_deriv}" >> "${datatable_file}"
done

3dMVM -prefix "${output_folder}/3dMVM_${version}" \
      -mask "${brain_mask}" \
      -wsVars Component \
      -num_glt 1 \
      -gltLabel 1 'StimPlusDeriv' \
      -gltCode 1 'Component : 1*Stim 1*Deriv' \
      -dataTable @"${datatable_file}"

else
  echo "** ALREADY RUN: ${output_prefix} **"
fi