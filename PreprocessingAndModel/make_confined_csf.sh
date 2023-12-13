###!/bin/bash -e -u
# Author: Alexa Tompary, modified by Oded Bein
# This script renders and runs the design files 
# to preprocess all functional scans from both sessions

if [ $# -ne 2 ]; then
  echo "
usage: `basename $0` engram

This script opens the relevant files on fsleyes so that I could draw a more conservative csf roi
"
  exit
fi
engram=$1
group=$2

#if you don't want to run some part of the code:
run_this_part=1

#set engram
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
elif (( $engram == 0 )); then
	source ./scripts/PreprocessingAndModel/globalsC.sh
elif (( $engram == 2 )); then #hpc
	source ./scripts/PreprocessingAndModel/globalsC_hpc.sh
fi 

#all subjects in the study
declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
#participants that are excluded: 15CD, 29DT, 23SJ 


#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(2ZD 3RS 7MS 8PL 9IL 11CB 12AN 36AN) #5BS 6GC
elif (( $group == 2 )); then
	declare -a subjects=(8PL 9IL 11CB) #10BL 
elif (( $group == 3 )); then
	declare -a subjects=(13GT 14MR 18RA 19AB 20SA 24DL) #16DB 17VW 
elif (( $group == 4 )); then
	declare -a subjects=(19AB 20SA 24DL) #21MY 22JP
elif (( $group == 5 )); then
	declare -a subjects=(25AL 30RK 31JC 32CC 33ML 34RB)#26MM 28HM 
elif (( $group == 6 )); then
	declare -a subjects=(32CC 33ML 34RB) # 37IR
elif (( $group == 7 )); then
	declare -a subjects=(12AN 36AN) # 37IR
elif (( $group == 10 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(5BS 6GC 10BL)
elif (( $group == 11 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(16DB 17VW)
elif (( $group == 12 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(21MY 26MM)
elif (( $group == 13 )); then #these are the subjects that ran on my computer:
	declare -a subjects=(22JP) #(28HM 37IR) #22JP
fi

#declare -a subjects=(34RB)

#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_noSliceTimingCorrection

for subj in "${subjects[@]}"
do

echo "opening files for subject $subj"

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_roi_dir=$subjects_dir/$subj/$roi_dir/epi
sub_anat_dir=$subjects_dir/$subj/$anatomy_dir


echo $sub_roi_dir

# csf mask was defined as the following:
# 1. we overlayed the csf mask on the refAv epi space. we did it directly in epi space as it allowed to see the boundaries of csf roi as registered to the epi, and since
# the boundaries are clearly visible also in epi.
# 2. We chose a voxel in each hemisphere at the center of the central part of the lateral ventrical.
# 3. Then, we blew a sphere with a radius of 3 voxels around these voxels
# 4. we masked that sphere again with the csf mask, to further ensure that only csf voxels were included.
# 
# why didn't we do that for wm? because for wm it is more difficult to choose a representative roi - bc these wm have neurons intertwined etc, and signal might correlate with
# activity in different regions in different wm regions. So, we chose to take the average all wm as a regressor in the univariate analysis, but not to use it for the similarity.

#i used this line to open up the images, and I made the coord below:
fsleyes $sub_anat_dir/AvRefimage_fm $sub_anat_dir/AvRef_csf_thr1 -cm Red

done

if (( $run_this_part == 1 )); then

# then, after creating the csf sphere - see below - I re-opened all the files to check that the csf region looks good:
for subj in "${subjects[@]}"
do

echo "opening files for subject $subj"

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_roi_dir=$subjects_dir/$subj/$roi_dir/epi
sub_anat_dir=$subjects_dir/$subj/$anatomy_dir


echo $sub_roi_dir

fsleyes $sub_anat_dir/AvRefimage_fm $sub_anat_dir/AvRef_csf_thr1 -cm Red $sub_roi_dir/csf_3sphere

done


#comments from checking:
#8PL - needed to run again, I DID!
#all great now! 02/27/20

#19AB - tiny csf...	
declare -a coord	 
coord=(64 88 31 71 90 30 \ #2ZD 
	   63 82 30 68 88 27 \ #3RS
	   62 78 32 69 82 30 \ #5BS
	   63 78 31 71 78 31 \ #6GC
	   63 81 29 70 82 28 \ #7MS
	   64 82 31 70 82 31 \ #8PL
	   64 79 31 71 82 30 \ #9IL
	   65 81 28 71 80 29 \ #10BL
	   64 81 31 69 83 30 \ #11CB
	   63 80 28 69 81 28 \ #12AN
	   63 80 30 69 80 30 \ #13GT
	   63 80 32 70 81 31 \ #14MR	
	   64 80 30 69 83 28 \ #16DB
	   65 81 32 70 80 33 \ #17VW
	   64 81 29 69 84 27 \ #18RA
	   64 76 32 69 76 33 \ #19AB
	   65 90 24 68 85 26 \ #20SA
	   65 80 27 70 79 28 \ #21MY
	   64 80 28 71 78 31 \ #22JP
	   64 80 31 69 83 29 \ #24DL
	   66 81 28 71 82 28 \ #25AL
	   64 82 29 69 81 31 \ #26MM
	   64 79 32 70 79 32 \ #28HM
	   64 85 27 70 82 29 \ #30RK
	   64 86 29 70 83 29 \ #31JC
	   63 79 30 69 81 29 \ #32CC
	   64 80 28 70 80 29 \ #33ML
	   64 84 29 71 81 31 \ #34RB
	   63 77 31 70 76 31 \ #36AN
	   64 78 29 70 80 27 \ #37IR
	   
)

ks=3
	

#this loop will create the csf sphere for all participants	 
#for subj_num in $(seq 0 1 29)
for subj_num in 5
do
subj=${subjects[subj_num]}
starti=$(($subj_num*7))
echo "$subj, starti: $starti"

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_roi_dir=$subjects_dir/$subj/$roi_dir/epi
sub_anat_dir=$subjects_dir/$subj/$anatomy_dir


echo $sub_roi_dir

#make the lhemi:
xcoord=${coord[(($starti + 0))]}
ycoord=${coord[(($starti + 1))]}
zcoord=${coord[(($starti + 2))]}

echo "$subj, left hemi: $xcoord $ycoord $zcoord"

fslmaths \
$sub_anat_dir/AvRefimage_fm \
-roi $xcoord 1 $ycoord 1 $zcoord 1 0 1 \
$sub_roi_dir/lcsf_1vox

# creates a kernel using the 1-voxel region as input
fslmaths \
$sub_roi_dir/lcsf_1vox \
-kernel sphere $ks -fmean -thr .001 -bin \
$sub_roi_dir/lcsf_${ks}sphere

#make the rhemi:
xcoord=${coord[(($starti + 3))]}
ycoord=${coord[(($starti + 4))]}
zcoord=${coord[(($starti + 5))]}

echo "$subj, right hemi: $xcoord $ycoord $zcoord" 

fslmaths \
$sub_anat_dir/AvRefimage_fm \
-roi $xcoord 1 $ycoord 1 $zcoord 1 0 1 \
$sub_roi_dir/rcsf_1vox

# creates a kernel using the 1-voxel region as input
fslmaths \
$sub_roi_dir/rcsf_1vox \
-kernel sphere $ks -fmean -thr .001 -bin \
$sub_roi_dir/rcsf_${ks}sphere

#create one bilateral roi:
fslmaths $sub_roi_dir/rcsf_${ks}sphere -add $sub_roi_dir/lcsf_${ks}sphere $sub_roi_dir/csf_${ks}sphere

#apply csf mask just to be sure
fslmaths $sub_roi_dir/csf_${ks}sphere \
-mul $sub_anat_dir/AvRef_csf_thr1 \
$sub_roi_dir/csf_${ks}sphere
 	
done

fi #
########### this is the output from the screen as it ran:
# 2ZD, starti: 0
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/2ZD/rois/epi
# 2ZD, left hemi: 64 88 31
# 2ZD, right hemi: 71 90 30
# 3RS, starti: 7
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/3RS/rois/epi
# 3RS, left hemi: 63 82 30
# 3RS, right hemi: 68 88 27
# 5BS, starti: 14
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/5BS/rois/epi
# 5BS, left hemi: 62 78 32
# 5BS, right hemi: 69 82 30
# 6GC, starti: 21
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/6GC/rois/epi
# 6GC, left hemi: 63 78 31
# 6GC, right hemi: 71 78 31
# 7MS, starti: 28
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/7MS/rois/epi
# 7MS, left hemi: 63 81 29
# 7MS, right hemi: 70 82 28
# 8PL, starti: 35
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/8PL/rois/epi
# 8PL, left hemi: 64 82 31
# 8PL, right hemi: 70 92 31
# 9IL, starti: 42
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/9IL/rois/epi
# 9IL, left hemi: 64 79 31
# 9IL, right hemi: 71 82 30
# 10BL, starti: 49
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/10BL/rois/epi
# 10BL, left hemi: 65 81 28
# 10BL, right hemi: 71 80 29
# 11CB, starti: 56
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/11CB/rois/epi
# 11CB, left hemi: 64 81 31
# 11CB, right hemi: 69 83 30
# 12AN, starti: 63
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/12AN/rois/epi
# 12AN, left hemi: 63 80 28
# 12AN, right hemi: 69 81 28
# 13GT, starti: 70
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/13GT/rois/epi
# 13GT, left hemi: 63 80 30
# 13GT, right hemi: 69 80 30
# 14MR, starti: 77
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/14MR/rois/epi
# 14MR, left hemi: 63 80 32
# 14MR, right hemi: 70 81 31
# 16DB, starti: 84
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/16DB/rois/epi
# 16DB, left hemi: 64 80 30
# 16DB, right hemi: 69 83 28
# 17VW, starti: 91
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/17VW/rois/epi
# 17VW, left hemi: 65 81 32
# 17VW, right hemi: 70 80 33
# 18RA, starti: 98
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/18RA/rois/epi
# 18RA, left hemi: 64 81 29
# 18RA, right hemi: 69 84 27
# 19AB, starti: 105
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/19AB/rois/epi
# 19AB, left hemi: 64 76 32
# 19AB, right hemi: 69 76 33
# 20SA, starti: 112
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/20SA/rois/epi
# 20SA, left hemi: 65 90 24
# 20SA, right hemi: 68 85 26
# 21MY, starti: 119
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/21MY/rois/epi
# 21MY, left hemi: 65 80 27
# 21MY, right hemi: 70 79 28
# 22JP, starti: 126
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/22JP/rois/epi
# 22JP, left hemi: 64 80 28
# 22JP, right hemi: 71 78 31
# 24DL, starti: 133
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/24DL/rois/epi
# 24DL, left hemi: 64 80 31
# 24DL, right hemi: 69 83 29
# 25AL, starti: 140
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/25AL/rois/epi
# 25AL, left hemi: 66 81 28
# 25AL, right hemi: 71 82 28
# 26MM, starti: 147
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/26MM/rois/epi
# 26MM, left hemi: 64 82 29
# 26MM, right hemi: 69 81 31
# 28HM, starti: 154
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/28HM/rois/epi
# 28HM, left hemi: 64 79 32
# 28HM, right hemi: 70 79 32
# 30RK, starti: 161
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/30RK/rois/epi
# 30RK, left hemi: 64 85 27
# 30RK, right hemi: 70 82 29
# 31JC, starti: 168
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/31JC/rois/epi
# 31JC, left hemi: 64 86 29
# 31JC, right hemi: 70 83 29
# 32CC, starti: 175
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/32CC/rois/epi
# 32CC, left hemi: 63 79 30
# 32CC, right hemi: 69 81 29
# 33ML, starti: 182
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/33ML/rois/epi
# 33ML, left hemi: 64 80 28
# 33ML, right hemi: 70 80 29
# 34RB, starti: 189
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/34RB/rois/epi
# 34RB, left hemi: 64 84 29
# 34RB, right hemi: 71 81 31
# 36AN, starti: 196
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/36AN/rois/epi
# 36AN, left hemi: 63 77 31
# 36AN, right hemi: 70 76 31
# 37IR, starti: 203
# /Volumes/data/Bein/Repatime/repatime_scanner/SubData/37IR/rois/epi
# 37IR, left hemi: 64 78 29
# 37IR, right hemi: 70 80 27

#I register here the coord for each participant:
# declare -a sub_coord=(ZD RS BS GC MS PL IL BL CB AN \
#  					 GT MR DB VW RA AB SA MY JP DL \
#  					 AL MM HM RK JC CC ML RB AN2 IR)
#  					 
# declare -a sub_coord=(ZD RS BS GC MS PL IL BL CB AN GT MR DB VW RA AB SA MY JP DL AL MM HM RK JC CC ML RB AN2 IR)
# 
 