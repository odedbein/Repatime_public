###!/bin/bash -e -u
# Author:Oded Bein
# This script runs the checks for bet and AvRefImage for all subjects

#all subjects in the study
#already checked: 2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT \
declare -a subjects=(14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
# 
# 
# engram=0
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi
# #LOOP FOR ALL SUBJECTS
# for subj in "${subjects[@]}"
# do
# 
# sub_dir=$subjects_dir/$subj
# sub_data_dir=$subjects_dir/$subj/$data_dir
# 
# echo "viewing bet for $subj"
# 
# fsleyes $sub_dir/$anatomy_dir/mprage.nii.gz -cm Greyscale $sub_dir/$anatomy_dir/mprage_brain.nii.gz -cm Hot
# 
# done

#already checked: 2ZD
declare -a subjects=(3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT \
 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir

echo "viewing average ref image for $subj"

#check if worked well:
file_name=$sub_dir/$anatomy_dir/AvRefimage_fm
answer_av="no"
echo "Pulling up FSLVIEW; examine the average brains. When finished checking, close the FSLVIEW window"

yes
echo "did averaging the ref images worked? type yes or no"

read answer_av

#remove the temp directory
if [ "$answer_av" == "no" ]; then
	echo "you didin't like the Refs averaging, consider what to do"
else
	rm -r ${file_name}_tmp
fi

done
