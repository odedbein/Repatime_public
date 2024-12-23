#!/bin/bash -u
# Author: Oded Bein
# This script runs fslview to watch all the scans, and deletes all redundant files after running the prep for preprocessing
# before deleting, make sure that the prep was fine, and you are happy with the fm correction
# if [ $# -ne 1 ]; then
#   echo "
# usage: `basename $0` subj
# 
# This script looks at motion and registration after preprocessing
# 
# "
#   exit
# fi

engram=$1
group=$2

run_this_part=0

#set engram
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
elif (( $engram == 0 )); then
	source ./scripts/PreprocessingAndModel/globalsC.sh
elif (( $engram == 2 )); then #hpc
	source ./scripts/PreprocessingAndModel/globalsC_hpc.sh
fi 

#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT \
 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
#participants that are excluded: 15CD, 29DT, 23SJ 

#run bet before:
#22JP - list 5 and 6 were bad
#26MM - ran with bet before from order test 5
#10BL - ran with bet before
#i ran the entire participant with bet before.
#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(3RS 5BS 6GC 7MS 9IL 8PL) #2ZD 
elif (( $group == 2 )); then
	declare -a subjects=(6GC 7MS)
elif (( $group == 3 )); then
	declare -a subjects=(9IL 8PL) #10BL 11CB
elif (( $group == 4 )); then
	declare -a subjects=(19AB 20SA 24DL) #21MY 22JP
elif (( $group == 5 )); then
	declare -a subjects=(25AL 30RK 31JC)#26MM 28HM 
elif (( $group == 6 )); then
	declare -a subjects=(33ML 34RB 32CC) # 37IR
elif (( $group == 7 )); then
	declare -a subjects=(12AN 36AN) # 37IR
elif (( $group == 10 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(5BS 6GC 10BL 16DB 17VW)
elif (( $group == 11 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(16DB 17VW)
elif (( $group == 12 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(22JP)
elif (( $group == 13 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(21MY 26MM 22JP 28HM 37IR)
fi

#for debugging - just have one subj:
declare -a subjects=(2ZD)

 
#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_noSliceTimingCorrection #preproc_noHPfilter_noSliceTimingCorrection

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "running QA 2.5 on preproc for subject $subj"

sub_dir=$subjects_dir/$subj
sub_motion_dir=$sub_dir/$analysis_dir/motion_assess
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_analysis_dir=$sub_dir/$analysis_dir
outhtml=$sub_analysis_dir/qa/preproc_motion_QA.html

#rm $outhtml


echo $sub_data_dir
if (( $run_this_part == 1 )); then
#create a motion file:
echo "creating motion file for all scans"

#if (( $run_this_part == 1 )); then
# encoding
for l in {1..3}; do #{1..6}
	for r in {1..3}; do
	
		scan_name=encoding_l${l}_rep${r}
		subj_feat_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth.feat

		if (( $run_this_part == 1 )); then
		# Put motion info into html file
		echo "<p>=============<p>" >> $outhtml   
		echo "<p> ${scan_name} <br>" >> $outhtml  
		echo "<IMG BORDER=0 SRC=$subj_feat_dir/mc/disp.png WIDTH=70%%></BODY></HTML> " >> $outhtml
		echo "<IMG BORDER=0 SRC=$subj_feat_dir/mc/rot.png WIDTH=70%%></BODY></HTML> " >> $outhtml
		echo "<IMG BORDER=0 SRC=$subj_feat_dir/mc/trans.png WIDTH=70%%></BODY></HTML> " >> $outhtml   
		# Put reg images into html file
		echo "<p> example_func2highres <br><IMG BORDER=0 SRC=$subj_feat_dir/reg/example_func2highres.png WIDTH=100%%></BODY></HTML> " >> $outhtml
		echo "<p> example_func2standard <br><IMG BORDER=0 SRC=$subj_feat_dir/reg/example_func2standard.png WIDTH=100%%></BODY></HTML> " >> $outhtml
		echo "<p> highres2standard <br><IMG BORDER=0 SRC=$subj_feat_dir/reg/highres2standard.png WIDTH=100%%></BODY></HTML> " >> $outhtml
		fi #ends run this part
		
		if [ ! -f $subj_feat_dir/mc/MC_Column1.txt ]; then
			echo "Saving MC regregssors ${scan_name}"
			#splitting par file from FEAT into six motion regressors
			for num in 1 2 3 4 5 6; do
				cat $subj_feat_dir/mc/prefiltered_func_data_mcf.par \
				| tr -s ' ' | cut -d ' ' -f ${num} \
				> $subj_feat_dir/mc/MC_Column${num}.txt
			done
		fi
	
	done
done

#fi #

echo "<h1> motion and registration QA file <h1>" >> $outhtml


#open the motion and registration file that we just created
open $outhtml
#open the motion outliers file
outhtml=$sub_analysis_dir/qa/bold_outliermotion_QA.html
open $outhtml
#open the reg2AvRef file
outhtml=$sub_analysis_dir/qa/reg2AvRef_QA.html
open $outhtml

#you also want to look at one image from each day in fslview more carefully. All the epi's are the same, so look at one of them
#and for the rest, it's okay to only look at the edges images:
#check if worked well:

fi  #ends run this part


echo "
Pulling up FSLEYES for scans subject $subj. 
examine the brains by changing transparency, to check registration.
When finished checking, close the FSLVIEW window"


scan_name=scan_name=encoding_l1_rep1
subj_feat_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth.feat
fsleyes $subj_feat_dir/reg/highres $subj_feat_dir/reg/example_func2highres -cm red-yellow -dr 1 30000
fsleyes $subj_feat_dir/reg/standard $subj_feat_dir/reg/highres2standard $subj_feat_dir/reg/example_func2standard -cm red-yellow -dr 1 30000

done
