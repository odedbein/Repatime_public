###!/bin/bash -e -u
# Author:Oded Bein
# This script band pass filter the res4d file. I chose to take the residuals from the EchPos
#model, to account for any effect of the task. Then, I bandpass filter to low frequency. Tompary did
#.01-.1Hz. My events are every 24s, which are e .04Hz, so I did .01-.035
#I learned that the fsl bndp command is not suitible for anything 
#other than highpass filtering, so I used 3dBandpass from Afni.
#see: https://neurostars.org/t/bandpass-filtering-different-outputs-from-fsl-and-nipype-custom-function/824/3
#for more information.

# but, if you want to use fsl'd bnfp, the command requires the filter in sigma units:
#sigma=1/(2*TR*freq)
#so, for my 2-s TR, it'll be 25-7.14, which are the values you see below
# bflow=25.0
# bfhigh=7.14

bflow=.01
bfhigh=.035
bflow_name=01
bfhigh_name=035


#delete previous dirs?
delete_prev_dir=0
if (( $delete_prev_dir == 1 )); then
	echo "you're deleting previous feat dirs"
fi

#input parameters:
engram=$1
group=$2

#set engram
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
elif (( $engram == 0 )); then
	source ./scripts/PreprocessingAndModel/globalsC.sh
elif (( $engram == 2 )); then #hpc
	source ./scripts/PreprocessingAndModel/globalsC_hpc.sh
fi 


#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)

#currently running: (2ZD 3RS 5BS 6GC 7MS) (8PL 9IL 10BL 11CB 12AN) (13GT 14MR 16DB 17VW 18RA)
#(19AB 20SA 21MY 22JP 24DL) (25AL 26MM 28HM 30RK 31JC) (32CC 33ML 34RB 36AN 37IR)

#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR) #2ZD 
elif (( $group == 1 )); then
	declare -a subjects=(2ZD 3RS 5BS)
elif (( $group == 2 )); then
	declare -a subjects=(6GC 7MS 8PL)
elif (( $group == 3 )); then
	declare -a subjects=(9IL 10BL 11CB)
elif (( $group == 4 )); then
	declare -a subjects=(12AN 13GT 14MR)
elif (( $group == 5 )); then
	declare -a subjects=(16DB 17VW 18RA) 
elif (( $group == 6 )); then
	declare -a subjects=(19AB 20SA 21MY)
elif (( $group == 7 )); then
	declare -a subjects=(30RK 31JC 32CC)
elif (( $group == 8 )); then
	declare -a subjects=(33ML 34RB 36AN)
elif (( $group == 9 )); then
	declare -a subjects=(22JP 28HM 37IR)
elif (( $group == 10 )); then
	declare -a subjects=(24DL 25AL 26MM)
elif (( $group == 11 )); then
	declare -a subjects=(2ZD 3RS 5BS 19AB 20SA 21MY) 
elif (( $group == 12 )); then
	declare -a subjects=(6GC 7MS 8PL 30RK 31JC 32CC)
elif (( $group == 13 )); then
	declare -a subjects=(9IL 10BL 11CB 22JP 28HM 37IR)
elif (( $group == 14 )); then
	declare -a subjects=(12AN 13GT 14MR 24DL 25AL 26MM)
elif (( $group == 15 )); then
	declare -a subjects=(16DB 17VW 18RA 33ML 34RB 36AN) 
elif (( $group == 16 )); then
	declare -a subjects=(32CC) 
fi


#for debugging - just have one subj:#
declare -a subjects=(34RB)

#smoothing:
smoothing=no_smooth
sm_kernel=0

#sliceTiming correction
preproc_type=noSliceTimingCorrection

#set preproc dir accordingly:
preproc_dir=${analysis_dir}/preproc_${preproc_type}
model=Univar_eachPositionModel
onset_model= #nothing to add for the onsetflie, keep empty
allcopes=($(seq 1 1 8))
csfwm_type=_with_wmcsf_3sphere #_with_csfwm

#if you don't want to run some part of the code:
run_this_part=1

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "analyzing subject $subj"

sub_dir=$subjects_dir/$subj
sub_motion_dir=$sub_dir/$analysis_dir/motion_assess
sub_data_dir=$subjects_dir/$subj/$preproc_dir # pre-processed scans are there
sub_analysis_dir=$sub_dir/$analysis_dir
onsets_dir=$subjects_dir/$subj/onsets/univariate/encoding

echo $sm_kernel

#make a folder for all of the directories (eventually, one per model), in which i save the output
output_dir=$sub_dir/$enc_dir/${preproc_type}/$smoothing/$model${csfwm_type}
echo $output_dir
#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
#if (( $run_this_part == 1 )); then
#fi #ends the run this part if - move if don't want to run all script

## ENCODING render the templates for each list and each rep
for l in 6; do #;{1..6}
echo "bandpass filtering $model${csfwm_type} for ${subj} encoding list${l}"

	for r in {1..5}; do #{1..5} 
		scan_name=encoding_list${l}_rep${r}.feat
		#bandpass filter:
		3dBandpass \
		-prefix ${output_dir}/${scan_name}/stats/bp \
		-band $bflow $bfhigh \
		${output_dir}/${scan_name}/stats/res4d.nii.gz
		
		#convert to nifti:
		3dAFNItoNIFTI \
		-prefix ${output_dir}/${scan_name}/stats/bp_filtered${bflow_name}hz${bfhigh_name}hz_res4d.nii.gz \
		${output_dir}/${scan_name}/stats/bp+orig.BRIK
		sleep 1
		
		#delete the afni files, to save space:
		rm ${output_dir}/${scan_name}/stats/bp+orig.BRIK
		rm ${output_dir}/${scan_name}/stats/bp+orig.HEAD
		
		
		mkdir ${output_dir}/${scan_name}/stats/reg_AvRef
		echo "registering to AvRef for ${subj} encoding list${l} rep${r}"
		#register to AvRef:
		feat_folder=$sub_data_dir/encoding_l${l}_rep${r}_${smoothing}.feat #preprocessed data are here
		scan=${output_dir}/${scan_name}/stats/bp_filtered${bflow_name}hz${bfhigh_name}hz_res4d
		flirt \
		-in $scan \
		-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
		-applyxfm -init ${feat_folder}/reg/example_func2AvRef.mat \
		-out ${output_dir}/${scan_name}/stats/reg_AvRef/bp_filtered${bflow_name}hz${bfhigh_name}hz_res4d

			
	done #reps loop
done #lists loop

done #participants loop


#fslbandpass - don't use, it's not good for band pass, only for hyghpass - see abovw:
# fslmaths  ${output_dir}/${scan_name}/stats/res4d \
# 			-bptf $bflow $bfhigh \
# 			${output_dir}/${scan_name}/stats/bp_filtered${bflow_name}hz${bfhigh_name}hz_res4d
