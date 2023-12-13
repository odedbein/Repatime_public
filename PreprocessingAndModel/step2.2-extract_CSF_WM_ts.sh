##!/bin/bash -e -u
# Author: Oded Bein
# This script extracts the timeseries of the CSF and the White matter to use ase regressors in any later model
#make sure that FAST was run before, and that preprocessing was run, we need the registration.
if [ $# -ne 2 ]; then
  echo "
usage: `basename $0` engram

This script extracts the timeseries of the CSF and the White matter to use ase regressors in any later model

"
  exit
fi
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
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT \
 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
#participants that are excluded: 15CD, 29DT, 23SJ 


#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL)
elif (( $group == 2 )); then
	declare -a subjects=(24DL 25AL 26MM)
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

#declare -a subjects=(22JP)

#csf sphere size:
ks=3
#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
run_this_part=0

#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_noSliceTimingCorrection 
#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "analyzing step2.2-extract_csf_wm for subject $subj"

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_analysis_dir=$sub_dir/$analysis_dir
sub_anatomy_dir=$sub_dir/$anatomy_dir
fs_dir=$sub_dir/data/autorecon #freesurfer dir
sub_roi_dir=$sub_dir/$roi_dir/epi
echo $sub_data_dir

if (( $run_this_part == 1 )); then	
################################################
#make a more conservative brain edge mask. Alexa did it with thresholding the mean_func to 5000.
#I want to do it on the AvRefImage, because this is the space where eventually all ROIs will be.
#the average reference image creates weird intensities which makes it difficult to have a good brain mask based on that,
#or to run bet on it. To go around that, I register the mean_func of the frist run on day1 to the AvRefImage, then thresholding that.

#apply the transformation matrix:
scan=$sub_dir/$preproc_dir/similarity_post_l1_no_smooth.feat/mean_func
flirt \
-in $scan \
-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
-applyxfm -init $sub_dir/$preproc_dir/similarity_post_l1_no_smooth.feat/reg/example_func2AvRef.mat \
-out $sub_dir/$anatomy_dir/mean_func2RefAv

#now create the brain mask, in the AvRef space - Alexa did 5000, I looked at my image and seemed too strict, may be related to scanner differences. so I took 3000.
fslmaths $sub_dir/$anatomy_dir/mean_func2RefAv -thr 3000 -bin $sub_dir/$anatomy_dir/epi_mask


################################################
#make a constrained CSF mask in the mprage space, if doesn't exist:
#create a nifti file for the aparc+aseg.mgz file that has all the lables(no hipp subfields):
#this file has both entorhinal and parahipp. However, note that the entorhinal is very inclusive.
if [ ! -f "$fs_dir/rois/aseg2mprage.nii.gz" ]; then
	mri_convert \
	-rl  $fs_dir/mri/rawavg.mgz \
	-rt nearest $fs_dir/mri/aseg.mgz \
	$fs_dir/rois/aseg2mprage.nii.gz
fi

if [ ! -f "$sub_dir/$anatomy_dir/mprage_fs_csf.nii.gz" ]; then
	fslmaths $fs_dir/rois/aseg2mprage -thr 4 -uthr 4 -bin $sub_dir/$anatomy_dir/lmprage_fs_csf
	fslmaths $fs_dir/rois/aseg2mprage -thr 43 -uthr 43 -bin $sub_dir/$anatomy_dir/rmprage_fs_csf
	fslmaths $sub_dir/$anatomy_dir/lmprage_fs_csf -add $sub_dir/$anatomy_dir/rmprage_fs_csf $sub_dir/$anatomy_dir/mprage_fs_csf
fi

if [ ! -f "$sub_dir/$anatomy_dir/mprage_fs_wm.nii.gz" ]; then
	fslmaths $fs_dir/rois/aseg2mprage -thr 2 -uthr 2 -bin $sub_dir/$anatomy_dir/lmprage_fs_wm
	fslmaths $fs_dir/rois/aseg2mprage -thr 41 -uthr 41 -bin $sub_dir/$anatomy_dir/rmprage_fs_wm
	fslmaths $sub_dir/$anatomy_dir/lmprage_fs_wm -add $sub_dir/$anatomy_dir/rmprage_fs_wm $sub_dir/$anatomy_dir/mprage_fs_wm
fi


#apply the transformation to AvRef
#if [ ! -f "$sub_dir/$anatomy_dir/AvRef_csf_thr1.nii.gz" ]; then
flirt \
-in $sub_dir/$anatomy_dir/mprage_fs_csf \
-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
-applyxfm -init $sub_dir/$anatomy_dir/mprage2AvRef.mat \
-out $sub_dir/$anatomy_dir/AvRef_csf_thr1

#threshold and binarize
fslmaths $sub_dir/$anatomy_dir/AvRef_csf_thr1 -thr 1 -bin $sub_dir/$anatomy_dir/AvRef_csf_thr1

#apply the epi mask on the csf - we'll only have signal in these voxels:
fslmaths $sub_dir/$anatomy_dir/AvRef_csf_thr1 -mul $sub_dir/$anatomy_dir/epi_mask $sub_dir/$anatomy_dir/AvRef_csf_thr1

#if (( $run_this_part == 1 )); then	
#fi #ends the run this part if - move if don't want to run all script

##### ENCODING: #######
for l in {1..6}; do #{1..6}

	for r in {1..5}; do #{1..5}

		scan_name=encoding_l${l}_rep${r}
		subj_preproc_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth.feat
		
		if [ ! -f "${subj_preproc_dir}/wm_csf/epi_csf_${ks}sphere_meants.txt" ]; then	
		echo "making csf/wm regressors for encoding scan list $l rep $r" 
		mkdir ${subj_preproc_dir}/wm_csf
		#transform csf from mprage to scan space:
		flirt \
			-in $sub_dir/$anatomy_dir/mprage_fs_csf \
			-ref $subj_preproc_dir/example_func \
			-applyxfm -init $subj_preproc_dir/reg/highres2example_func.mat \
			-out ${subj_preproc_dir}/wm_csf/epi_csf
		#threshold and binarize
		fslmaths ${subj_preproc_dir}/wm_csf/epi_csf -thr 1 -bin ${subj_preproc_dir}/wm_csf/epi_csf
	
		#transform wm from mprage to scan space:
		flirt \
			-in $sub_dir/$anatomy_dir/mprage_fs_wm \
			-ref $subj_preproc_dir/example_func \
			-applyxfm -init $subj_preproc_dir/reg/highres2example_func.mat \
			-out ${subj_preproc_dir}/wm_csf/epi_wm
		#threshold and binarize
		fslmaths ${subj_preproc_dir}/wm_csf/epi_wm -thr 1 -bin ${subj_preproc_dir}/wm_csf/epi_wm
	
		#extract the time series from both
		fslmeants -i ${subj_preproc_dir}/filtered_func_data \
				  -m ${subj_preproc_dir}/wm_csf/epi_csf \
				  -o ${subj_preproc_dir}/wm_csf/epi_csf_meants.txt
	
		fslmeants -i ${subj_preproc_dir}/filtered_func_data \
				  -m ${subj_preproc_dir}/wm_csf/epi_wm \
				  -o ${subj_preproc_dir}/wm_csf/epi_wm_meants.txt
		#fi  #run this part
		
		#make csf sphere:
		echo "making csf sphere regressor for encoding scan list $l rep $r" 
		#I marked it on the AvRef space, so first register it to the specific scan space, that shouldn't change much:
		
		#transform csf from mprage to scan space:
		flirt \
			-in $sub_roi_dir/csf_${ks}sphere \
			-ref $subj_preproc_dir/example_func \
			-applyxfm -init $subj_preproc_dir/reg/AvRef2example_func.mat \
			-out ${subj_preproc_dir}/wm_csf/epi_csf_${ks}sphere
			
		#extract the time series from both
		fslmeants -i ${subj_preproc_dir}/filtered_func_data \
				  -m ${subj_preproc_dir}/wm_csf/epi_csf_${ks}sphere \
				  -o ${subj_preproc_dir}/wm_csf/epi_csf_${ks}sphere_meants.txt 
		fi #if file doesn't exist	  
	done #repetition
	
done #lists

fi #run this part

done #participants

