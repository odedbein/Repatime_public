###!/bin/bash -e -u
# Author:Oded Bein
# This script renders and runs the design files,
# then runs level1 LSS models on all encoding trials

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

#participants that are excluded: 15CD, 29DT, 23SJ 

#set participants group:
# if (( $group == 0 )); then
# #all of them:
# 	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
#  					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
#  					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
# elif (( $group == 1 )); then
# 	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN) #5BS 6GC
# elif (( $group == 2 )); then
# 	declare -a subjects=(13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL) #10BL 
# elif (( $group == 3 )); then
# 	declare -a subjects=(25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR) #16DB 17VW 
# fi

if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL) # 6GC 7MS 8PL) #2ZD 
elif (( $group == 2 )); then
	declare -a subjects=(6GC 7MS) #(9IL 10BL 11CB 12AN)
elif (( $group == 3 )); then
	declare -a subjects=(8PL 2ZD) #(13GT 14MR 16DB 17VW 18RA)
elif (( $group == 4 )); then
	declare -a subjects=(9IL 11CB) #(19AB 20SA 21MY 22JP 24DL)
elif (( $group == 5 )); then
	declare -a subjects=(25AL 26MM 28HM 30RK 31JC) 
elif (( $group == 6 )); then
	declare -a subjects=(32CC 33ML 34RB 36AN 37IR)
fi

#declare -a subjects=(2ZD)


#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_noSliceTimingCorrection
smoothing=no_smooth

for subj in "${subjects[@]}"
do
	sub_dir=$subjects_dir/$subj
	sub_data_dir=$subjects_dir/$subj/data/processed #fm corrected images are there
	sub_feat_dir=$subjects_dir/$subj/${preproc_dir}
	echo $sub_data_dir

	#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
	#run_this_part=1
	#if (( $run_this_part == 1 )); then
	#fi #ends the run this part if - move if don't want to run all script

	## ENCODING
	for l in {1..6}; do #{1..6};
	echo "registering subj ${subj} list${l}"

		for r in {1..5}; do #
	
			scan_name=encoding_l${l}_rep${r}
			feat_folder=$sub_feat_dir/${scan_name}_${smoothing}.feat
			#register to AvRef
			if [ ! -e "$feat_folder/reg/example_func2AvRef.mat" ]; then	
				echo "
				no reg to AvRef for list${l}_rep${r} - creating a transformation matrix.
				will not create a QA image - check the registration"
		
				subj_reg_dir=$feat_folder/reg
				curr_scan=$subj_reg_dir/example_func

				flirt \
				-in $curr_scan \
				-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
				-out $subj_reg_dir/example_func2AvRef \
				-omat $subj_reg_dir/example_func2AvRef.mat \
				-cost corratio \
				-dof 6 \
				-searchrx -90 90 -searchry -90 90 -searchrz -90 90 \
				-interp trilinear

				#inverse the affine matrix
				convert_xfm -inverse -omat $subj_reg_dir/AvRef2example_func.mat $subj_reg_dir/example_func2AvRef.mat
			fi
			
			#register data to AvRef:
			scan=$sub_data_dir/${scan_name}_fm
			flirt \
			-in $scan \
			-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
			-applyxfm -init $feat_folder/reg/example_func2AvRef.mat \
			-out ${scan}2AvRef
		
		done #reps loop
	done #lists loop
done #subj loop