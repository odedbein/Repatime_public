###!/bin/bash -e -u
# Author: Alexa Tompary, modified by Oded Bein
# This script renders and runs the design files 
# to preprocess all functional scans from both sessions

if [ $# -ne 1 ]; then
echo "
usage: `basename $0` engram

This script runs flirt to register everything to the AvRef scan
(the average ref scan of the first similarity_pre scan of both days)
"
exit
fi
#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT \
14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
#ran already: 2ZD
#currently running: 3RS (5BS 6GC 7MS 8PL 9IL 10BL 11CB) (12AN 13GT 14MR 16DB 17VW 18RA 19AB) (20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK)
declare -a subjects=(22JP)

#subj=$1
engram=$@

if (( $engram == 1 )); then
source ./scripts/PreprocessingAndModel/globalsCengram.sh
#name of files for the slice dir:
sldr_fname='_data'
else
source ./scripts/PreprocessingAndModel/globalsC.sh
sldr_fname='_Volumes_data'
fi

for subj in "${subjects[@]}"
do

echo "reg to AvRef subject $subj"

sub_dir=$subjects_dir/$subj
sub_motion_dir=$sub_dir/$analysis_dir/motion_assess
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_analysis_dir=$sub_dir/$analysis_dir
outhtml=$sub_analysis_dir/qa/reg2AvRef_QA.html
rm $outhtml

echo "<h1> registration to AvRef QA file <h1>" >> $outhtml

echo $sub_data_dir

#make qa dir
if [ ! -d $sub_analysis_dir/qa ]; then
mkdir $sub_analysis_dir/qa
fi

#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
run_this_part=1

if (( $run_this_part == 1 )); then
##### mprage: register to the AvRef #######

echo "registering mprage to AvRef image using BBR" 
#it's recommended to register from low to high res - so register the ref to the mprage, then invert
epi_reg --epi=$sub_dir/$anatomy_dir/AvRefimage_fm \
--t1=$sub_dir/$anatomy_dir/mprage \
--t1brain=$sub_dir/$anatomy_dir/mprage_brain \
--out=$sub_dir/$anatomy_dir/AvRef2mprage

#inverse the affine matrix
convert_xfm -inverse -omat $sub_dir/$anatomy_dir/mprage2AvRef.mat $sub_dir/$anatomy_dir/AvRef2mprage.mat

#create an image to check registration:
cd $sub_dir/$anatomy_dir
slicesdir -o $sub_dir/$anatomy_dir/mprage $sub_dir/$anatomy_dir/AvRef2mprage
#copy into the QA file
sldr_image_name=$sub_dir/$anatomy_dir/slicesdir/${sldr_fname}_Bein_Repatime_repatime_scanner_SubData_${subj}_data_anatomy_mprage_to_${sldr_fname}_Bein_Repatime_repatime_scanner_SubData_${subj}_data_anatomy_AvRef2mprage.png
# Put reg image files into html file for review later on
echo "<p>=============<p>" >> $outhtml   
echo "<p> AvRef2mprage <br><IMG BORDER=0 SRC=$sldr_image_name WIDTH=100%%></BODY></HTML> " \
>> $outhtml

fi #move this if for the run part

if (( $run_this_part == 1 )); then

##### ENCODING: register to the AvRef #######
echo "registering encoding scans to AvRef image using flirt" 
scan_names=""
for l in {1..6}; do #{1..6}

	for r in {1..5}; do 

	scan_name=encoding_l${l}_rep${r}
	subj_reg_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth.feat/reg
	curr_scan=$subj_reg_dir/example_func


	#write up the file names to use later in slicesdir
	scan_names+=" $sub_dir/$anatomy_dir/AvRefimage_fm $subj_reg_dir/example_func2AvRef"

	done #repetition

done #lists

#create an image to check registration:
if [ ! -d $sub_analysis_dir/qa/encoding ]; then
mkdir $sub_analysis_dir/qa/encoding
fi
cd $sub_analysis_dir/qa/encoding
slicesdir -o $scan_names
#copy into the QA file
for l in {1..6}; do

	for r in {1..5}; do 

	sldr_image_name=$sub_analysis_dir/qa/encoding/slicesdir/${sldr_fname}_Bein_Repatime_repatime_scanner_SubData_${subj}_data_anatomy_AvRefimage_fm_to_${sldr_fname}_Bein_Repatime_repatime_scanner_SubData_${subj}_analysis_preproc_encoding_l${l}_rep${r}_no_smooth.feat_reg_example_func2AvRef.png # Put reg image files into html file for review later on
	echo "<p>=============<p>" >> $outhtml
	echo "<p> encoding l${l} rep${r} <br><IMG BORDER=0 SRC=$sldr_image_name WIDTH=100%%></BODY></HTML> " \
	>> $outhtml

	done #repetition

done #lists

fi #