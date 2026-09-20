#!/bin/bash
#This script uses pre-processed brain fMRI data and creates a general linear model using AFNI.
#It takes 1 run of a task as input and uses ME-ICA rejected components

#Check if the inputs are correct
if [ $# -ne 11 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the fMRI data you want to model for run 1"
  echo "Input 2 should be the demeaned motion parameters for run 1"
  echo "Input 3 should be the demeaned motion derivative parameters for run 1"
  echo "Input 4 should be the demeaned motor stimulus regressor"
  echo "Input 5 should be the motor stimulus regressor convolved with HRF TEMPORAL DERIVATIVE"
  echo "Input 6 should be the subject ID"
  echo "Input 7 should be the output directory"
  echo "Input 8 should be the mask"
  echo "Input 9 should be the rejected ICA components for run 1"
  echo "Input 10 should be the number of rejected ICA components for run 1"
  echo "Input 11 should be the end-tidal CO2 regressor"
  exit
fi

input_file1="${1}"
motion_file="${2}"
motion_deriv_file="${3}"
stim_file="${4}"
stim_der="${5}"
sub_ID="${6}"
output_dir="${7}"
mask="${8}"
rejComp_file="${9}"
num_ica="${10}"
CO2_file="${11}"

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

if [ ! -f "${output_dir}/${sub_ID}_denoised.nii.gz" ]
then

  # Create design matrix using 3dDeconvolve
  # Add the correct number of rejected ICA components to GLM
  run3dDeconvolve="3dDeconvolve -input ${input_file1} -polort 4 -num_stimts $((15+${num_ica}))"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 1 "${motion_file}[0]" -stim_label 1 MotionRx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 2 "${motion_file}[1]" -stim_label 2 MotionRy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 3 "${motion_file}[2]" -stim_label 3 MotionRz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 4 "${motion_file}[3]" -stim_label 4 MotionTx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 5 "${motion_file}[4]" -stim_label 5 MotionTy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 6 "${motion_file}[5]" -stim_label 6 MotionTz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 7 "${motion_deriv_file}[0]" -stim_label 7 MotionRx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 8 "${motion_deriv_file}[1]" -stim_label 8 MotionRy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 9 "${motion_deriv_file}[2]" -stim_label 9 MotionRz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 10 "${motion_deriv_file}[3]" -stim_label 10 MotionTx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 11 "${motion_deriv_file}[4]" -stim_label 11 MotionTy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 12 "${motion_deriv_file}[5]" -stim_label 12 MotionTz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 13 "${CO2_file}" -stim_label 13 CO2"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 14 "${stim_file}" -stim_label 14 MotorStim"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 15 "${stim_der}" -stim_label 15 MotorDeriv"

  for i in $(seq 1 1 ${num_ica});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${i})) "${rejComp_file}{$((${i}-1))}"\' -stim_label $((15+${i})) "Rej${i}""
  done

  run3dDeconvolve="${run3dDeconvolve} -x1D ${output_dir}/"${sub_ID}_matrix.1D" -x1D_stop" #save matrix but don't run analysis

  eval ${run3dDeconvolve}

  # Run GLM using 3dREMLfit
  3dREMLfit -input ${input_file1} \
    -matrix ${output_dir}/"${sub_ID}_matrix.1D" \
    -gltsym 'SYM: +MotorStim \ +MotorDeriv' MotorComb \
    -mask ${mask} -tout -rout -fout \
    -Rglt ${output_dir}/"${sub_ID}_glt.nii.gz" \
    -Rbeta ${output_dir}/"${sub_ID}_bcoef.nii.gz" \
    -Rbuck ${output_dir}/"${sub_ID}_bucket.nii.gz" \
    -Rfitts ${output_dir}/"${sub_ID}_fitts.nii.gz" \
    -Rerrts ${output_dir}/"${sub_ID}_errts.nii.gz"


else
  echo "** ALREADY RUN: subject=${sub_ID} **"
fi