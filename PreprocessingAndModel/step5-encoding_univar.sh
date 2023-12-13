###!/bin/bash -e -u
# Author:Oded Bein
# This script renders and runs the design files,
# then runs level1 event model on all encoding runs

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


#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
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
fi

#for debugging - just have one subj:
#declare -a subjects=(2ZD)

#smoothing:
smoothing=no_smooth  
sm_kernel=0


#sliceTiming correction
preproc_type=noSliceTimingCorrection

#set preproc dir accordingly:
preproc_dir=${analysis_dir}/preproc_${preproc_type}

#set model:
whichmodel=eachPos #FIR #eventModel #eachPos #RT
model=Univar_eachPositionModel
onset_model= #nothing to add for the onsetflie, keep empty
allcopes=($(seq 1 1 11))
	
	
#include csfwm in the model - cho
csfwm_type=_with_wmcsf_3sphere

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

echo $sub_data_dir


#make design dir - where fsf files will be stored
subj_design_dir=$sub_dir/design_dir/encoding/univariate/${preproc_type}/$smoothing
mkdir -p $subj_design_dir

#make a folder for all of the directories (eventually, one per model), in which i save the output
output_dir=$sub_dir/$enc_dir/${preproc_type}/$smoothing/$model${csfwm_type}
if (( $delete_prev_dir == 1 )); then
	echo "deleting dirs subject $subj"
	rm -rf $output_dir
	rm -rf ${output_dir}.gfeat
fi

mkdir -p $output_dir


#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want

#if (( $run_this_part == 1 )); then
#fi #ends the run this part if - move if don't want to run all script

## ENCODING render the templates for each list and each rep
for l in {1..6}; do #;{1..6}

	for r in {1..5}; do #{1..5} 
	
		scan_name=encoding_l${l}_rep${r}
		#if (( $run_this_part == 1 )); then
		feat_folder=$sub_data_dir/${scan_name}_no_smooth.feat #where preprocessed data are
		#create the model fsf file:
		onsetsfile=encoding_list${l}_rep${r}${onset_model}

		cat $fsl_templates/encoding/encoding_${model}${csfwm_type}.fsf.template \
			| sed "s|inputscan|$feat_folder/filtered_func_data|g" \
			| sed "s|project_dir|$proj_dir|g" \
			| sed "s|fsldir|$FSLDIR|g" \
			| sed "s|output_dir|${output_dir}/encoding_list${l}_rep${r}|g" \
			| sed "s|subj|$subj|g" \
			| sed "s|numvol|77|g" \
			| sed "s|smooth_ker|$sm_kernel|g" \
			| sed "s|scanname|$scan_name|g" \
			| sed "s|onsetsfile|$onsets_dir/$onsetsfile|g" \
			| sed "s|featfolder|$feat_folder|g" \
			> $subj_design_dir/list${l}_rep${r}_${model}${csfwm_type}.fsf
	
		
		#run feat:
		if [ ! -d "$output_dir/encoding_list${l}_rep${r}.feat" ]; then

			echo "running feat first level $model${csfwm_type} for ${subj} encoding list${l} rep${r}"
			feat $subj_design_dir/list${l}_rep${r}_${model}${csfwm_type}.fsf
			sleep 5
			scripts/PreprocessingAndModel/wait-for-feat.sh $output_dir/encoding_list${l}_rep${r}.feat

			#copy the reg folder - need it for later:
			subj_reg_dir=$feat_folder/reg
			  if [ ! -f "$output_dir/encoding_list${l}_rep${r}.feat/reg/example_func2standard.mat" ]; then
				  echo "copy reg folder $smoothing for ${subj} encoding list${l} rep${r}"
				  mkdir $output_dir/encoding_list${l}_rep${r}.feat/reg
				  cp $subj_reg_dir/example_func2AvRef.mat $output_dir/encoding_list${l}_rep${r}.feat/reg/example_func2standard.mat

				  #copy the AvRef image to be the ref image for the dummy registration
				  cp $sub_dir/$anatomy_dir/AvRefimage_fm.nii.gz $output_dir/encoding_list${l}_rep${r}.feat/reg/standard.nii.gz
			  fi
		
		#fi	#ends the run this part if
		
		fi #ends the if there is a feat dir
	
	done #reps loop
done #lists loop

done #participants loop
