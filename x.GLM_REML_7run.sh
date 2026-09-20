#!/bin/bash
#This script uses pre-processed brain fMRI data and creates a general linear model using AFNI.
#It takes 7 runs of the same task with unequal lengths as input and uses ME-ICA rejected components

#Check if the inputs are correct
if [ $# -ne 43 ]
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
  echo "Input 10 should be the fMRI data you want to model for run 4"
  echo "Input 11 should be the demeaned motion parameters for run 4"
  echo "Input 12 should be the demeaned motion derivative parameters for run 4"
  echo "Input 13 should be the fMRI data you want to model for run 5"
  echo "Input 14 should be the demeaned motion parameters for run 5"
  echo "Input 15 should be the demeaned motion derivative parameters for run 5"
  echo "Input 16 should be the fMRI data you want to model for run 6"
  echo "Input 17 should be the demeaned motion parameters for run 6"
  echo "Input 18 should be the demeaned motion derivative parameters for run 6"
  echo "Input 19 should be the fMRI data you want to model for run 7"
  echo "Input 20 should be the demeaned motion parameters for run 7"
  echo "Input 21 should be the demeaned motion derivative parameters for run 7"
  echo "Input 22 should be the demeaned motor stimulus regressor (all runs concatenated)"
  echo "Input 23 should be the motor stimulus regressor convolved with HRF TEMPORAL DERIVATIVE (all runs concatenated)"
  echo "Input 24 should be the subject ID"
  echo "Input 25 should be the output directory"
  echo "Input 26 should be the mask"
  echo "Input 27 should be the rejected ICA components for run 1"
  echo "Input 28 should be the number of rejected ICA components for run 1"
  echo "Input 29 should be the rejected ICA components for run 2"
  echo "Input 30 should be the number of rejected ICA components for run 2"
  echo "Input 31 should be the rejected ICA components for run 3"
  echo "Input 32 should be the number of rejected ICA components for run 3"
  echo "Input 33 should be the rejected ICA components for run 4"
  echo "Input 34 should be the number of rejected ICA components for run 4"
  echo "Input 35 should be the rejected ICA components for run 5"
  echo "Input 36 should be the number of rejected ICA components for run 5"
  echo "Input 37 should be the rejected ICA components for run 6"
  echo "Input 38 should be the number of rejected ICA components for run 6"
  echo "Input 39 should be the rejected ICA components for run 7"
  echo "Input 40 should be the number of rejected ICA components for run 7"
  echo "Input 41 should be the number of volumes in ses-01 runs"
  echo "Input 42 should be the number of volumes in ses-02 run"
  echo "Input 43 should be the end-tidal CO2 regressor (all runs concatentated)"
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
input_file4="${10}"
motion_file4="${11}"
motion_deriv_file4="${12}"
input_file5="${13}"
motion_file5="${14}"
motion_deriv_file5="${15}"
input_file6="${16}"
motion_file6="${17}"
motion_deriv_file6="${18}"
input_file7="${19}"
motion_file7="${20}"
motion_deriv_file7="${21}"
stim_file="${22}"
stim_der="${23}"
sub_ID="${24}"
output_dir="${25}"
mask="${26}"
rejComp_file1="${27}"
num_ica1="${28}"
rejComp_file2="${29}"
num_ica2="${30}"
rejComp_file3="${31}"
num_ica3="${32}"
rejComp_file4="${33}"
num_ica4="${34}"
rejComp_file5="${35}"
num_ica5="${36}"
rejComp_file6="${37}"
num_ica6="${38}"
rejComp_file7="${39}"
num_ica7="${40}"
vol1="${41}"
vol2="${42}"
CO2_file="${43}"

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

if [ ! -f "${output_dir}/${sub_ID}_errts.nii.gz" ]
then

  #Make temporary directory for concatenated inputs
  mkdir ${output_dir}/tmp
  tmp="${output_dir}/tmp"

  if [ ! -f ${tmp}/mot0_7runs.1D ]
  then
    # concatenate motion files
    cat "${motion_file1}" "${motion_file2}" "${motion_file3}" "${motion_file4}" "${motion_file5}" "${motion_file6}" "${motion_file7}" >> ${tmp}/motAll_7runs.1D
    cat "${motion_deriv_file1}" "${motion_deriv_file2}" "${motion_deriv_file3}" "${motion_deriv_file4}" "${motion_deriv_file5}" "${motion_deriv_file6}" "${motion_deriv_file7}" >> ${tmp}/motDerivAll_7runs.1D
    for i in $(eval echo "{0..5}")
    do
      1dcat ${tmp}/motAll_7runs.1D[${i}] >> ${tmp}/mot${i}_7runs.1D
      1dcat ${tmp}/motDerivAll_7runs.1D[${i}] >> ${tmp}/mot${i}_deriv_7runs.1D
    done

    # create empty sections for rejected ICA components; run 5 has vol2 number of volumes, all else are vol1
    for ((n=1; n<=$(( 5*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros234567_1.1D # after rej1
    for ((n=1; n<=${vol1}; n++)) do echo -e "0";done >> ${tmp}/zeros1_2.1D # before rej2
    for ((n=1; n<=$(( 4*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros34567_2.1D # after rej2
    for ((n=1; n<=$(( 2*${vol1} )); n++)) do echo -e "0";done >> ${tmp}/zeros12_3.1D # before rej3
    for ((n=1; n<=$(( 3*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros4567_3.1D # after rej3
    for ((n=1; n<=$(( 3*${vol1} )); n++)) do echo -e "0";done >> ${tmp}/zeros123_4.1D # before rej4
    for ((n=1; n<=$(( 2*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros567_4.1D # after rej4
    for ((n=1; n<=$(( 4*${vol1} )); n++)) do echo -e "0";done >> ${tmp}/zeros1234_5.1D # before rej5
    for ((n=1; n<=$(( 2*${vol1} )); n++)) do echo -e "0";done >> ${tmp}/zeros67_5.1D # after rej5
    for ((n=1; n<=$(( 4*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros12345_6.1D # before rej6
    for ((n=1; n<=${vol1}; n++)) do echo -e "0";done >> ${tmp}/zeros7_6.1D # after rej6
    for ((n=1; n<=$(( 5*${vol1} + ${vol2} )); n++)) do echo -e "0";done >> ${tmp}/zeros123456_7.1D # before rej3

    
    # make zeros23_1 be as many columns as rejected components 1 to match up later
    zeros234567_1="1dcat"
    for i in $(seq 1 1 ${num_ica1})
    do
      zeros234567_1="${zeros234567_1} ${tmp}/zeros234567_1.1D"
    done
    zeros234567_1="${zeros234567_1} >> ${tmp}/zeros234567_1all.1D"
    eval ${zeros234567_1}
    
    # make zeros1_2 be as many columns as rejected components 2 to match up later
    zeros1_2="1dcat"
    for i in $(seq 1 1 ${num_ica2})
    do
      zeros1_2="${zeros1_2} ${tmp}/zeros1_2.1D"
    done
    zeros1_2="${zeros1_2} >> ${tmp}/zeros1_2all.1D"
    eval ${zeros1_2}

    zeros34567_2="1dcat"
    for i in $(seq 1 1 ${num_ica2})
    do
      zeros34567_2="${zeros34567_2} ${tmp}/zeros34567_2.1D"
    done
    zeros34567_2="${zeros34567_2} >> ${tmp}/zeros34567_2all.1D"
    eval ${zeros34567_2}
    
    # make zeros12_3 be as many columns as rejected components 3 to match up later
    zeros12_3="1dcat"
    for i in $(seq 1 1 ${num_ica3})
    do
      zeros12_3="${zeros12_3} ${tmp}/zeros12_3.1D"
    done
    zeros12_3="${zeros12_3} >> ${tmp}/zeros12_3all.1D"
    eval ${zeros12_3}
    
    zeros4567_3="1dcat"
    for i in $(seq 1 1 ${num_ica3})
    do
      zeros4567_3="${zeros4567_3} ${tmp}/zeros4567_3.1D"
    done
    zeros4567_3="${zeros4567_3} >> ${tmp}/zeros4567_3all.1D"
    eval ${zeros4567_3}
    
    # make zeros12_3 be as many columns as rejected components 4 to match up later
    zeros123_4="1dcat"
    for i in $(seq 1 1 ${num_ica4})
    do
      zeros123_4="${zeros123_4} ${tmp}/zeros123_4.1D"
    done
    zeros123_4="${zeros123_4} >> ${tmp}/zeros123_4all.1D"
    eval ${zeros123_4}
    
    zeros567_4="1dcat"
    for i in $(seq 1 1 ${num_ica4})
    do
      zeros567_4="${zeros567_4} ${tmp}/zeros567_4.1D"
    done
    zeros567_4="${zeros567_4} >> ${tmp}/zeros567_4all.1D"
    eval ${zeros567_4}
    
    # make zeros12_3 be as many columns as rejected components 5 to match up later
    zeros1234_5="1dcat"
    for i in $(seq 1 1 ${num_ica5})
    do
      zeros1234_5="${zeros1234_5} ${tmp}/zeros1234_5.1D"
    done
    zeros1234_5="${zeros1234_5} >> ${tmp}/zeros1234_5all.1D"
    eval ${zeros1234_5}
    
    zeros67_5="1dcat"
    for i in $(seq 1 1 ${num_ica5})
    do
      zeros67_5="${zeros67_5} ${tmp}/zeros67_5.1D"
    done
    zeros67_5="${zeros67_5} >> ${tmp}/zeros67_5all.1D"
    eval ${zeros67_5}
    
    # make zeros12_3 be as many columns as rejected components 6 to match up later
    zeros12345_6="1dcat"
    for i in $(seq 1 1 ${num_ica6})
    do
      zeros12345_6="${zeros12345_6} ${tmp}/zeros12345_6.1D"
    done
    zeros12345_6="${zeros12345_6} >> ${tmp}/zeros12345_6all.1D"
    eval ${zeros12345_6}
    
    zeros7_6="1dcat"
    for i in $(seq 1 1 ${num_ica6})
    do
      zeros7_6="${zeros7_6} ${tmp}/zeros7_6.1D"
    done
    zeros7_6="${zeros7_6} >> ${tmp}/zeros7_6all.1D"
    eval ${zeros7_6}
    
    # make zeros12_3 be as many columns as rejected components 7 to match up later
    zeros123456_7="1dcat"
    for i in $(seq 1 1 ${num_ica7})
    do
      zeros123456_7="${zeros123456_7} ${tmp}/zeros123456_7.1D"
    done
    zeros123456_7="${zeros123456_7} >> ${tmp}/zeros123456_7all.1D"
    eval ${zeros123456_7}


    1dcat "${rejComp_file1}"\' >> ${tmp}/rejComp_file1_trans.1D
    1dcat "${rejComp_file2}"\' >> ${tmp}/rejComp_file2_trans.1D
    1dcat "${rejComp_file3}"\' >> ${tmp}/rejComp_file3_trans.1D
    1dcat "${rejComp_file4}"\' >> ${tmp}/rejComp_file4_trans.1D
    1dcat "${rejComp_file5}"\' >> ${tmp}/rejComp_file5_trans.1D
    1dcat "${rejComp_file6}"\' >> ${tmp}/rejComp_file6_trans.1D
    1dcat "${rejComp_file7}"\' >> ${tmp}/rejComp_file7_trans.1D

    cat ${tmp}/rejComp_file1_trans.1D ${tmp}/zeros234567_1all.1D >> ${tmp}/rejAll_run1_7runs.1D
    cat ${tmp}/zeros1_2all.1D ${tmp}/rejComp_file2_trans.1D ${tmp}/zeros34567_2all.1D >> ${tmp}/rejAll_run2_7runs.1D
    cat ${tmp}/zeros12_3all.1D ${tmp}/rejComp_file3_trans.1D ${tmp}/zeros4567_3all.1D >> ${tmp}/rejAll_run3_7runs.1D
    cat ${tmp}/zeros123_4all.1D ${tmp}/rejComp_file4_trans.1D ${tmp}/zeros567_4all.1D >> ${tmp}/rejAll_run4_7runs.1D
    cat ${tmp}/zeros1234_5all.1D ${tmp}/rejComp_file5_trans.1D ${tmp}/zeros67_5all.1D >> ${tmp}/rejAll_run5_7runs.1D
    cat ${tmp}/zeros12345_6all.1D ${tmp}/rejComp_file6_trans.1D ${tmp}/zeros7_6all.1D >> ${tmp}/rejAll_run6_7runs.1D
    cat ${tmp}/zeros123456_7all.1D ${tmp}/rejComp_file7_trans.1D >> ${tmp}/rejAll_run7_7runs.1D

    for i in $(seq 1 1 ${num_ica1})
    do
      1dcat ${tmp}/rejAll_run1_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run1_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica2})
    do
      1dcat ${tmp}/rejAll_run2_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run2_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica3})
    do
      1dcat ${tmp}/rejAll_run3_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run3_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica4})
    do
      1dcat ${tmp}/rejAll_run4_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run4_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica5})
    do
      1dcat ${tmp}/rejAll_run5_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run5_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica6})
    do
      1dcat ${tmp}/rejAll_run6_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run6_7runs.1D
    done
    for i in $(seq 1 1 ${num_ica7})
    do
      1dcat ${tmp}/rejAll_run7_7runs.1D[$((${i}-1))] >> ${tmp}/rej$((${i}-1))_run7_7runs.1D
    done

  fi

  # Create design matrix using 3dDeconvolve
  # Add the correct number of rejected ICA components to GLM
  run3dDeconvolve="3dDeconvolve -input ${input_file1} ${input_file2} ${input_file3} ${input_file4} ${input_file5} ${input_file6} ${input_file7} -local_times -polort 4 -num_stimts $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${num_ica5}+${num_ica6}+${num_ica7}))"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 1 "${tmp}/mot0_7runs.1D" -stim_label 1 MotionRx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 2 "${tmp}/mot1_7runs.1D" -stim_label 2 MotionRy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 3 "${tmp}/mot2_7runs.1D" -stim_label 3 MotionRz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 4 "${tmp}/mot3_7runs.1D" -stim_label 4 MotionTx"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 5 "${tmp}/mot4_7runs.1D" -stim_label 5 MotionTy"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 6 "${tmp}/mot5_7runs.1D" -stim_label 6 MotionTz"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 7 "${tmp}/mot0_deriv_7runs.1D" -stim_label 7 MotionRx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 8 "${tmp}/mot1_deriv_7runs.1D" -stim_label 8 MotionRy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 9 "${tmp}/mot2_deriv_7runs.1D" -stim_label 9 MotionRz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 10 "${tmp}/mot3_deriv_7runs.1D" -stim_label 10 MotionTx_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 11 "${tmp}/mot4_deriv_7runs.1D" -stim_label 11 MotionTy_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 12 "${tmp}/mot5_deriv_7runs.1D" -stim_label 12 MotionTz_d1"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 13 "${CO2_file}" -stim_label 13 CO2"
    run3dDeconvolve="${run3dDeconvolve} -stim_file 14 "${stim_file}" -stim_label 14 MotorStim"
  run3dDeconvolve="${run3dDeconvolve} -stim_file 15 "${stim_der}" -stim_label 15 MotorDeriv"

  for i in $(seq 1 1 ${num_ica1});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${i})) "${tmp}/rej$((${i}-1))_run1_7runs.1D" -stim_label $((15+${i})) "Rej${i}_Run1""
  done
  for i in $(seq 1 1 ${num_ica2});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${i})) "${tmp}/rej$((${i}-1))_run2_7runs.1D" -stim_label $((15+${num_ica1}+${i})) "Rej${i}_Run2""
  done
  for i in $(seq 1 1 ${num_ica3});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${i})) "${tmp}/rej$((${i}-1))_run3_7runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${i})) "Rej${i}_Run3""
  done
  for i in $(seq 1 1 ${num_ica4});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${num_ica3}+${i})) "${tmp}/rej$((${i}-1))_run4_7runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${num_ica3}+${i})) "Rej${i}_Run4""
  done
  for i in $(seq 1 1 ${num_ica5});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${i})) "${tmp}/rej$((${i}-1))_run5_7runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${i})) "Rej${i}_Run5""
  done
  for i in $(seq 1 1 ${num_ica6});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${num_ica5}+${i})) "${tmp}/rej$((${i}-1))_run6_7runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${num_ica5}+${i})) "Rej${i}_Run6""
  done
  for i in $(seq 1 1 ${num_ica7});
  do
    run3dDeconvolve="${run3dDeconvolve} -stim_file $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${num_ica5}+${num_ica6}+${i})) "${tmp}/rej$((${i}-1))_run7_7runs.1D" -stim_label $((15+${num_ica1}+${num_ica2}+${num_ica3}+${num_ica4}+${num_ica5}+${num_ica6}+${i})) "Rej${i}_Run7""
  done

  run3dDeconvolve="${run3dDeconvolve} -x1D ${output_dir}/"${sub_ID}_matrix.1D" -x1D_stop" #save matrix but don't run analysis

  eval ${run3dDeconvolve}

  # Run GLM using 3dREMLfit
  3dREMLfit -input "${input_file1} ${input_file2} ${input_file3} ${input_file4} ${input_file5} ${input_file6} ${input_file7}" \
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