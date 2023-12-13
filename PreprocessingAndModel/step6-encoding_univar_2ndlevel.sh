###!/bin/bash -e -u
# Author:Oded Bein
# This script renders and runs the design files,
# then runs level1 event model on all encoding runs

#deleting dirs?
delete_prev_dir=0
if (( $delete_prev_dir == 1 )); then
	echo "you're deleting previous feat dirs"
fi
run_this_part=1
#input parameters:
engram=$1
group=$2

#set engram
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
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
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(2ZD 3RS 5BS) #2ZD
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
	declare -a subjects=(9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR) 
fi
#for debugging - just have one subj:
#declare -a subjects=(3RS)


# some definitions:
smoothing=no_smooth 
model=Univar_eachPositionModel 
curr_analysis=$model 
preproc_type=noSliceTimingCorrection
csfwm_type=_with_wmcsf_3sphere 

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "analyzing subject $subj"

sub_dir=$subjects_dir/$subj

#make design dir - where fsf files will be stored
subj_design_dir=$sub_dir/design_dir/encoding/univariate
mkdir -p $subj_design_dir


#which first level to take:
output_dir=$sub_dir/$enc_dir/${preproc_type}/$smoothing/$model${csfwm_type}
#mkdir -p $output_dir

echo $output_dir

#name of the gfeat folder - different variable if you want to change it, but I'd recommend having it the same as first level
results_dir=$sub_dir/$enc_dir/${preproc_type}/$smoothing/${curr_analysis}${csfwm_type}

#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
#run_this_part=1
#if (( $run_this_part == 1 )); then
#fi #ends the run this part if - move if don't want to run all script

## ENCODING render the templates for each list and each rep


#create the model fsf file:
cat $fsl_templates/encoding/encoding_${curr_analysis}_2ndLevel.fsf.template \
	| sed "s|fsldir|$FSLDIR|g" \
	| sed "s|output_dir|$output_dir|g" \
	| sed "s|results_dir|${results_dir}|g" \
	> $subj_design_dir/${curr_analysis}_2ndLevel${smoothing}${csfwm_type}.fsf



if (( $delete_prev_dir == 1 )); then
	rm -rf ${output_dir}.gfeat
fi

if (( $run_this_part == 1 )); then
#run feat:
if [ ! -d "${results_dir}.gfeat" ]; then

	echo "running feat second level $model for ${subj}"
	feat $subj_design_dir/${curr_analysis}_2ndLevel${smoothing}${csfwm_type}.fsf
	sleep 5
	scripts/PreprocessingAndModel/wait-for-feat.sh ${results_dir}.gfeat
fi

fi
		
done #participants_loop
