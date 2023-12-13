#!/bin/bash -u
# Author: Oded Bein
# This script runsfslview to watch all the scans, and deletes all redundant files after running the prep for preprocessing
# before deleting, make sure that the prep was fine, and you are happy with the fm correction
if [ $# -ne 1 ]; then
  echo "
usage: `basename $0` subj

This script deletes all kind of files after running the prep for preprocessing, and compresses the CBI data folder
before running, make sure that the prep was fine, and you are happy with the fm correction

"
  exit
fi

subj=$@

source ./scripts/PreprocessingAndModel/globals.sh
sub_dir=$subjects_dir/$subj
sub_cbi_dir=$subjects_dir/$subj/CBIdata #should exist - that's where I exctracted CBI data to
sub_data_dir=$subjects_dir/$subj/$data_dir

#check if worked well:
echo "
Pulling up FSLVIEW for all scans subject $subj. 
examine the brains by running a movie, and see whether the fieldmap correction worked well.
When finished checking, close the FSLVIEW window"

run_this_part=1

if (( $run_this_part == 1 )); then

# encoding
for list in {1..6}; do
	for rep in {1..5}; do
		file_name=$sub_data_dir/encoding_l${list}_rep${rep}
		fslview ${file_name} ${file_name}_fm
		
	done
done

answer_enc="no"
echo "are all encoding scans good? answer yes or no"
read answer_enc


if [ "$answer_enc" == "yes" ]; then
	echo "deleting all not fm corrected images"
	for list in {1..6}; do
		for rep in {1..5}; do
			file_name=$sub_data_dir/encoding_l${list}_rep${rep}
			rm -r ${file_name}.nii.gz
		
		done
	done
fi

fi #ends the run this part if - move if don't want to run all script



