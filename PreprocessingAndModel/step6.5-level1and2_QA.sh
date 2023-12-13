#!/bin/bash -u
# Author: Oded Bein
# This script runs fslview to watch all the scans, and deletes all redundant files after running the prep for preprocessing
###
# Things recommended by Mumford to check in both levels:
# 1. that all zstats exist
# 2. no errors in the log, can use grep for that
# 3. look through the logs
#
# Things recommended by Mumford to check in the 2nd level:
#the filtered_func_data - if something is wrong, it might be all bright or all dark etc
#but, can look at it also just for the group level

#this script creates one file for all participants

#checked:
#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)

#parameters for analysis:
run_this_part=1
smoothing=no_smooth
task=encoding
curr_model=Univar_eachPositionModel 

#sliceTiming correction
preproc_type=noSliceTimingCorrection

csfwm_type=_with_wmcsf_3sphere 


engram=0
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi

#create qa file for all participants
qadir=$proj_dir/results/qa_temp
mkdir -p $qadir
outhtml=$qadir/${task}_${curr_model}_${smoothing}_${preproc_type}${csfwm_type}.html

rm $outhtml
#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "running QA 6.5 on level1 and level2 models for subject $subj"
echo "checking $task, ${curr_model}, $smoothing"

sub_dir=$subjects_dir/$subj
sub_analysis_dir=$sub_dir/$analysis_dir
curr_model_dir=$sub_analysis_dir/$task/${preproc_type}/$smoothing/${curr_model}${csfwm_type}

echo $curr_model_dir

#check for errrors in log files:
echo "level1 errors/tstat files:"
grep 'error' $curr_model_dir/*.feat/report_log.html
grep 'Error' $curr_model_dir/*.feat/report_log.html
grep 'ERROR' $curr_model_dir/*.feat/report_log.html
grep 'CHECK' $curr_model_dir/*.feat/report_log.html
grep 'check' $curr_model_dir/*.feat/report_log.html

#check that all tstats exist - note that each analysis might have a different number of zstats:
ls $curr_model_dir/*.feat/stats/tstat*.nii.gz | wc -l


if (( $run_this_part == 1 )); then

### ENCODING #######

#first level
echo "<p>=============<p>" >> $outhtml  
echo "<p> subj $subj $curr_model_dir <br>" >> $outhtml   
for l in {1..6}; do #{1..6}
	for r in {1..5}; do

		scan_name=encoding_list${l}_rep${r}
		subj_feat_dir=$curr_model_dir/${scan_name}.feat

		# Put design info into html file
		echo "<p>=============<p>" >> $outhtml  
		echo "<p> ${scan_name} <br>" >> $outhtml  
		#echo "<IMG BORDER=0 SRC=$subj_feat_dir/design.png WIDTH=70%%></BODY></HTML> " >> $outhtml
		echo "<IMG BORDER=0 SRC=$subj_feat_dir/design.png></BODY></HTML> " >> $outhtml
		echo "<IMG BORDER=0 SRC=$subj_feat_dir/mc/design_cov.png></BODY></HTML> " >> $outhtml
	

	done
done
	
#second level
echo "level2 errors/zstat files:"
grep 'error' $curr_model_dir.gfeat/report_log.html
grep 'Error' $curr_model_dir.gfeat/report_log.html
grep 'ERROR' $curr_model_dir.gfeat/report_log.html
grep 'CHECK' $curr_model_dir/*.feat/report_log.html
grep 'check' $curr_model_dir/*.feat/report_log.html

#check that all zstats exist - note that each analysis might have a different number of zstats:
ls $curr_model_dir.gfeat/cope*/stats/zstat*.nii.gz | wc -l

echo "<p>=============<p>" >> $outhtml  
echo "<p> subj $subj $curr_model_dir second level <br>" >> $outhtml
echo "<p><IMG BORDER=0 SRC=$curr_model_dir.gfeat/design.png></BODY></HTML> " >> $outhtml 
echo "<p><IMG BORDER=0 SRC=$curr_model_dir.gfeat/inputreg/masksum_overlay.png WIDTH=100%%></BODY></HTML> " >> $outhtml
echo "<p><IMG BORDER=0 SRC=$curr_model_dir.gfeat/inputreg/maskunique_overlay.png WIDTH=100%%></BODY></HTML> " >> $outhtml
	


#open the qa file
open $outhtml

