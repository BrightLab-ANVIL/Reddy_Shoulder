#!/bin/bash
#This script uses pre-processed brain fMRI data and creates a general linear model using AFNI.
#It takes 2 runs of the same task as input and uses ME-ICA rejected components

#Check if the inputs are correct
if [ $# -ne 17 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the fMRI data you want to model for run 1"
  echo "Input 2 should be the demeaned motion parameters for run 1"
  echo "Input 3 should be the demeaned motion derivative parameters for run 1"
  echo "Input 4 should be the fMRI data you want to model for run 2"
  echo "Input 5 should be the demeaned motion parameters for run 2"
  echo "Input 6 should be the demeaned motion derivative parameters for run 2"
  echo "Input 7 should be the demeaned motor stimulus regressor (both runs concatenated)"
  echo "Input 8 should be the motor stimulus regressor convolved with HRF TEMPORAL DERIVATIVE (both runs concatenated)"
  echo "Input 9 should be the subject ID"
  echo "Input 10 should be the output directory"
  echo "Input 11 should be the mask"
  echo "Input 12 should be the rejected ICA components for run 1"
  echo "Input 13 should be the number of rejected ICA components for run 1"
  echo "Input 14 should be the rejected ICA components for run 2"
  echo "Input 15 should be the number of rejected ICA components for run 2"
  echo "Input 16 should be the number of volumes in each run"
  echo "Input 17 should be the end-tidal CO2 regressor (both runs concatentated)"
  exit
fi

input_file1="${1}"
motion_file1="${2}"
motion_deriv_file1="${3}"
input_file2="${4}"
motion_file2="${5}"
motion_deriv_file2="${6}"
stim_file="${7}"
stim_der="${8}"
sub_ID="${9}"
output_dir="${10}"
mask="${11}"
rejComp_file1="${12}"
num_ica1="${13}"
rejComp_file2="${14}"
num_ica2="${15}"
vol="${16}"
CO2_file="${17}"

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

if [ ! -f "${output_dir}/${sub_ID}_denoised.nii.gz" ]
then

  #Make temporary directory for concatenated inputs
  mkdir ${output_dir}/tmp
  tmp="${output_dir}/tmp"

  if [ ! -f ${tmp}/mot0_2runs.1D ]
  then
    # concatenate motion files
    for i in $(eval echo "{0..5}")
    do
      1dcat -stack "${motion_file1}[${i}]" "${motion_file2}[${i}]" >> ${tmp}/mot${i}_2runs.1D
      1dcat -stack "${motion_deriv_file1}[${i}]" "${motion_deriv_file2}[${i}]" >> ${tmp}/mot${i}_deriv_2runs.1D
    done

    # create empty half for rejected ICA components
    for ((n=1; n<=${vol}; n++)) do echo -e "0";done >> ${tmp}/zeros.1D
    for i in $(seq 1 1 ${num_ica1})
    do
      1dcat -stack "${rejComp_file1}{$((${i}-1))}\'" ${tmp}/zeros.1D >> ${tmp}/rej$((${i}-1))_run1_2runs.1D
    done
    for i in $(seq 1 1 ${num_ica2})
    do
      1dcat -stack ${tmp}/zeros.1D "${rejComp_file2}{$((${i}-1))}\'" >> ${tmp}/rej$((${i}-1))_run2_2runs.1D
    done

  fi

  # Create design matrix using 3dDeconvolve
  # Add the correct number of rejected ICA components to GLM
  run3dDeconvolve="3dDeconvolve -input ${input_file1} ${input_file2} -local_times -polort 4 -num_stimts $((15+${num_ica1}+${num_ica2}))"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 1 "${tmp}/mot0_2runs.1D" -stim_label 1 MotionRx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 2 "${tmp}/mot1_2runs.1D" -stim_label 2 MotionRy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 3 "${tmp}/mot2_2runs.1D" -stim_label 3 MotionRz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 4 "${tmp}/mot3_2runs.1D" -stim_label 4 MotionTx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 5 "${tmp}/mot4_2runs.1D" -stim_label 5 MotionTy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 6 "${tmp}/mot5_2runs.1D" -stim_label 6 MotionTz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 7 "${tmp}/mot0_deriv_2runs.1D" -stim_label 7 MotionRx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 8 "${tmp}/mot1_deriv_2runs.1D" -stim_label 8 MotionRy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 9 "${tmp}/mot2_deriv_2runs.1D" -stim_label 9 MotionRz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 10 "${tmp}/mot3_deriv_2runs.1D" -stim_label 10 MotionTx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 11 "${tmp}/mot4_deriv_2runs.1D" -stim_label 11 MotionTy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 12 "${tmp}/mot5_deriv_2runs.1D" -stim_label 12 MotionTz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 13 "${CO2_file}" -stim_label 13 CO2"
    run3dDeconvolve="${run3dDeconvolve} -stim_file 14 "${stim_file}" -stim_label 14 MotorStim"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 15 "${stim_der}" -stim_label 15 MotorDeriv"

  for i in $(seq 1 1 ${num_ica1});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${i})) "${tmp}/rej$((${i}-1))_run1_2runs.1D" -stim_label $((15+${i})) "Rej${i}_Run1""
  done
  for i in $(seq 1 1 ${num_ica2});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${i})) "${tmp}/rej$((${i}-1))_run2_2runs.1D" -stim_label $((15+${num_ica1}+${i})) "Rej${i}_Run2""
  done

  run3dDeconvolve="${run3dDeconvolve} -x1D ${output_dir}/"${sub_ID}_matrix.1D" -x1D_stop" #save matrix but don't run analysis

  eval ${run3dDeconvolve}

  # Run GLM using 3dREMLfit
  3dREMLfit -input "${input_file1} ${input_file2}" \
    -matrix ${output_dir}/"${sub_ID}_matrix.1D" \
    -gltsym 'SYM: +MotorStim \ +MotorDeriv' MotorComb \
    -mask ${mask} -tout -rout -fout \
    -Rglt ${output_dir}/"${sub_ID}_glt.nii.gz" \
    -Rbeta ${output_dir}/"${sub_ID}_bcoef.nii.gz" \
    -Rbuck ${output_dir}/"${sub_ID}_bucket.nii.gz" \
    -Rfitts ${output_dir}/"${sub_ID}_fitts.nii.gz" \
    -Rerrts ${output_dir}/"${sub_ID}_errts.nii.gz"

  #Delete temporary directory
  rm -r ${tmp}

else
  echo "** ALREADY RUN: subject=${sub_ID} **"
fi