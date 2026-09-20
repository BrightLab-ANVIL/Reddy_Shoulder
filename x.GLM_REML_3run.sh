#!/bin/bash
#This script uses pre-processed brain fMRI data and creates a general linear model using AFNI.
#It takes 3 runs of the same task with unequal lengths as input and uses ME-ICA rejected components

#Check if the inputs are correct
if [ $# -ne 24 ]
then
  echo "Insufficient inputs"
  echo "Input 1 should be the fMRI data you want to model for run 1"
  echo "Input 2 should be the demeaned motion parameters for run 1"
  echo "Input 3 should be the demeaned motion derivative parameters for run 1"
  echo "Input 4 should be the fMRI data you want to model for run 2"
  echo "Input 5 should be the demeaned motion parameters for run 2"
  echo "Input 6 should be the demeaned motion derivative parameters for run 2"
  echo "Input 7 should be the fMRI data you want to model for run 3"
  echo "Input 8 should be the demeaned motion parameters for run 3"
  echo "Input 9 should be the demeaned motion derivative parameters for run 3"
  echo "Input 10 should be the demeaned motor stimulus regressor (all runs concatenated)"
  echo "Input 11 should be the motor stimulus regressor convolved with HRF TEMPORAL DERIVATIVE (all runs concatenated)"
  echo "Input 12 should be the subject ID"
  echo "Input 13 should be the output directory"
  echo "Input 14 should be the mask"
  echo "Input 15 should be the rejected ICA components for run 1"
  echo "Input 16 should be the number of rejected ICA components for run 1"
  echo "Input 17 should be the rejected ICA components for run 2"
  echo "Input 18 should be the number of rejected ICA components for run 2"
  echo "Input 19 should be the rejected ICA components for run 3"
  echo "Input 20 should be the number of rejected ICA components for run 3"
  echo "Input 21 should be the number of volumes in run 1"
  echo "Input 22 should be the number of volumes in run 2"
  echo "Input 23 should be the number of volumes in run 3"
  echo "Input 24 should be the end-tidal CO2 regressor (all runs concatentated)"
  exit
fi

input_file1="${1}"
motion_file1="${2}"
motion_deriv_file1="${3}"
input_file2="${4}"
motion_file2="${5}"
motion_deriv_file2="${6}"
input_file3="${7}"
motion_file3="${8}"
motion_deriv_file3="${9}"
stim_file="${10}"
stim_der="${11}"
sub_ID="${12}"
output_dir="${13}"
mask="${14}"
rejComp_file1="${15}"
num_ica1="${16}"
rejComp_file2="${17}"
num_ica2="${18}"
rejComp_file3="${19}"
num_ica3="${20}"
vol1="${21}"
vol2="${22}"
vol3="${23}"
CO2_file="${24}"

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

  if [ ! -f ${tmp}/mot0_3runs.1D ]
  then
    # concatenate motion files
    cat "${motion_file1}" "${motion_file2}" "${motion_file3}" >> ${tmp}/motAll_3runs.1D
    cat "${motion_deriv_file1}" "${motion_deriv_file2}" "${motion_deriv_file3}" >> ${tmp}/motDerivAll_3runs.1D
    for i in $(eval echo "{0..5}")
    do
      1dcat ${tmp}/motAll_3runs.1D[${i}] >> ${tmp}/mot${i}_3runs.1D
      1dcat ${tmp}/motDerivAll_3runs.1D[${i}] >> ${tmp}/mot${i}_deriv_3runs.1D
    done

    # create empty sections for rejected ICA components
    for ((n=1; n<=${vol1}; n++)) do echo -e "0";done >> ${tmp}/zeros1_2.1D # before rej2
    for ((n=1; n<=${vol3}; n++)) do echo -e "0";done >> ${tmp}/zeros3_2.1D # after rej2
    for ((n=1; n<=$((${vol2}+${vol3})); n++)) do echo -e "0";done >> ${tmp}/zeros23_1.1D # after rej1
    for ((n=1; n<=$((${vol1}+${vol2})); n++)) do echo -e "0";done >> ${tmp}/zeros12_3.1D # before rej3

    # make zeros1_2 be as many columns as rejected components 2 to match up later
    zeros1_2="1dcat"
    for i in $(seq 1 1 ${num_ica2})
    do
      zeros1_2="${zeros1_2} ${tmp}/zeros1_2.1D"
    done
    zeros1_2="${zeros1_2} >> ${tmp}/zeros1_2all.1D"
    eval ${zeros1_2}

    # make zeros3_2 be as many columns as rejected components 2 to match up later
    zeros3_2="1dcat"
    for i in $(seq 1 1 ${num_ica2})
    do
      zeros3_2="${zeros3_2} ${tmp}/zeros3_2.1D"
    done
    zeros3_2="${zeros3_2} >> ${tmp}/zeros3_2all.1D"
    eval ${zeros3_2}
    
    # make zeros23_1 be as many columns as rejected components 1 to match up later
    zeros23_1="1dcat"
    for i in $(seq 1 1 ${num_ica1})
    do
      zeros23_1="${zeros23_1} ${tmp}/zeros23_1.1D"
    done
    zeros23_1="${zeros23_1} >> ${tmp}/zeros23_1all.1D"
    eval ${zeros23_1}
    
    # make zeros12_3 be as many columns as rejected components 3 to match up later
    zeros12_3="1dcat"
    for i in $(seq 1 1 ${num_ica3})
    do
      zeros12_3="${zeros12_3} ${tmp}/zeros12_3.1D"
    done
    zeros12_3="${zeros12_3} >> ${tmp}/zeros12_3all.1D"
    eval ${zeros12_3}

    1dcat "${rejComp_file1}"\' >> ${tmp}/rejComp_file1_trans.1D
    1dcat "${rejComp_file2}"\' >> ${tmp}/rejComp_file2_trans.1D
    1dcat "${rejComp_file3}"\' >> ${tmp}/rejComp_file3_trans.1D

    cat ${tmp}/rejComp_file1_trans.1D ${tmp}/zeros23_1all.1D >> ${tmp}/rejAll_run1_3runs.1D
    cat ${tmp}/zeros1_2all.1D ${tmp}/rejComp_file2_trans.1D ${tmp}/zeros3_2all.1D >> ${tmp}/rejAll_run2_3runs.1D
    cat ${tmp}/zeros12_3all.1D ${tmp}/rejComp_file3_trans.1D >> ${tmp}/rejAll_run3_3runs.1D

    for i in $(seq 1 1 ${num_ica1})
    do
      1dcat ${tmp}/rejAll_run1_3runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run1_3runs.1D
    done
    for i in $(seq 1 1 ${num_ica2})
    do
      1dcat ${tmp}/rejAll_run2_3runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run2_3runs.1D
    done
    for i in $(seq 1 1 ${num_ica3})
    do
      1dcat ${tmp}/rejAll_run3_3runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run3_3runs.1D
    done

  fi

  # Create design matrix using 3dDeconvolve
  # Add the correct number of rejected ICA components to GLM
  run3dDeconvolve="3dDeconvolve -input ${input_file1} ${input_file2} ${input_file3} -local_times -polort 4 -num_stimts $((15+${num_ica1}+${num_ica2}+${num_ica3}))"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 1 "${tmp}/mot0_3runs.1D" -stim_label 1 MotionRx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 2 "${tmp}/mot1_3runs.1D" -stim_label 2 MotionRy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 3 "${tmp}/mot2_3runs.1D" -stim_label 3 MotionRz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 4 "${tmp}/mot3_3runs.1D" -stim_label 4 MotionTx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 5 "${tmp}/mot4_3runs.1D" -stim_label 5 MotionTy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 6 "${tmp}/mot5_3runs.1D" -stim_label 6 MotionTz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 7 "${tmp}/mot0_deriv_3runs.1D" -stim_label 7 MotionRx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 8 "${tmp}/mot1_deriv_3runs.1D" -stim_label 8 MotionRy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 9 "${tmp}/mot2_deriv_3runs.1D" -stim_label 9 MotionRz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 10 "${tmp}/mot3_deriv_3runs.1D" -stim_label 10 MotionTx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 11 "${tmp}/mot4_deriv_3runs.1D" -stim_label 11 MotionTy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 12 "${tmp}/mot5_deriv_3runs.1D" -stim_label 12 MotionTz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 13 "${CO2_file}" -stim_label 13 CO2"
    run3dDeconvolve="${run3dDeconvolve} -stim_file 14 "${stim_file}" -stim_label 14 MotorStim"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 15 "${stim_der}" -stim_label 15 MotorDeriv"

  for i in $(seq 1 1 ${num_ica1});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${i})) "${tmp}/rej$((${i}-1))_run1_3runs.1D" -stim_label $((15+${i})) "Rej${i}_Run1""
  done
  for i in $(seq 1 1 ${num_ica2});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${i})) "${tmp}/rej$((${i}-1))_run2_3runs.1D" -stim_label $((15+${num_ica1}+${i})) "Rej${i}_Run2""
  done
  for i in $(seq 1 1 ${num_ica3});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${i})) "${tmp}/rej$((${i}-1))_run3_3runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${i})) "Rej${i}_Run3""
  done

  run3dDeconvolve="${run3dDeconvolve} -x1D ${output_dir}/"${sub_ID}_matrix.1D" -x1D_stop" #save matrix but don't run analysis

  eval ${run3dDeconvolve}

  # Run GLM using 3dREMLfit
  3dREMLfit -input "${input_file1} ${input_file2} ${input_file3}" \
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