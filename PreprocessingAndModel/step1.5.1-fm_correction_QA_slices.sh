#!/bin/bash -u
# Author: Oded Bein

if [ $# -ne 1 ]; then
  echo "
usage: `basename $0` subj

This script takes one slice from one uncorrected scan and one slice from every corrected scan, and put them all together so that they are easy to compare

"
  exit
fi

engram=$@
#engram=1
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi

run_this_part=0
qa_file=check_fm_corr
#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)

#(2ZD 3RS 5BS 6GC 7MS) (8PL 9IL 10BL 11CB 12AN) (13GT 14MR 16DB 17VW 18RA) 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC   32CC 33ML 34RB 36AN 37IR
declare -a subjects=(25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
#declare -a subjects=(3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN)
#declare -a subjects=(13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL)
#LOOP FOR ALL SUBJECTS
#declare -a subjects=(2ZD)

if (( $run_this_part == 1 )); then

	for subj in "${subjects[@]}"
	do

		echo "analyzing subject $subj"

		sub_dir=$subjects_dir/$subj
		sub_data_dir=$subjects_dir/$subj/$data_dir
		subj_qa_dir=$subjects_dir/$subj/$analysis_dir/qa
		mkdir $subj_qa_dir

		#take the uncorrected slice of the first encoding scan, just for reference:
		list=1
		rep=1
		file_name=$sub_data_dir/encoding_l${list}_rep${rep}
		mkdir $sub_data_dir/temp
		fslsplit ${file_name} $sub_data_dir/temp/temp
		#take the middle to be our reference (enc had 76, will take 38)
		cp $sub_data_dir/temp/temp0038.nii.gz ${subj_qa_dir}/${qa_file}.nii.gz 
		echo ${subj_qa_dir}/${qa_file}.nii.gz 

		# encoding
		exmple_slice=38
		for list in {1..6}; do
			echo "encoding list $list"
			for rep in {1..5}; do
				file_name=$sub_data_dir/encoding_l${list}_rep${rep}_fm
				fslsplit ${file_name} $sub_data_dir/temp/temp
				fslmerge -t ${subj_qa_dir}/${qa_file} \
							${subj_qa_dir}/${qa_file} $sub_data_dir/temp/temp00${exmple_slice} 
			done
		done


		#remove the temp dir
		rm -r $sub_data_dir/temp


	done #ends the participants loop

fi #

#### this part views all of them, participant by participant:


#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)

declare -a subjects=(25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
 					 
for subj in "${subjects[@]}"
do

subj_qa_dir=$subjects_dir/$subj/$analysis_dir/qa

echo "opening image for subject $subj"
fsleyes ${subj_qa_dir}/${qa_file}

done
					 
#fi #ends the run this part if - move if don't want to run all script

