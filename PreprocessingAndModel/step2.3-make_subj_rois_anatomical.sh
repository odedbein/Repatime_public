##!/bin/bash -e -u
# Author: Oded Bein
# This script makes subj space ROIs

if [ $# -ne 2 ]; then
  echo "
usage: `basename $0` subj

This script creates binary masks of anatomically defined ROIs, as well as ROIs in MNI space and registers them to the epi space
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



#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
run_this_part=1
make_functional_rois=0 #if want to make the functional rois
run_qa=0
run_hipp_subfields=1
delete_prev_dir=0
if (( $delete_prev_dir == 1 )); then
	echo "deleting old folders"
fi
#set participants group:
if (( $group == 0 )); then
#all of them:
	declare -a subjects=(2ZD 3RS 5BS 6GC 7MS 8PL 9IL 10BL 11CB 12AN \
 					 13GT 14MR 16DB 17VW 18RA 19AB 20SA 21MY 22JP 24DL \
 					 25AL 26MM 28HM 30RK 31JC 32CC 33ML 34RB 36AN 37IR)
elif (( $group == 1 )); then
	declare -a subjects=(9IL 10BL 11CB 12AN) #2ZD 3RS 5BS 6GC 7MS 8PL 
elif (( $group == 2 )); then
	declare -a subjects=(20SA 21MY 22JP 24DL) #13GT 14MR 16DB 17VW 18RA 19AB 
elif (( $group == 3 )); then
	declare -a subjects=(30RK 31JC 33ML) #32CC 
elif (( $group == 4 )); then
	declare -a subjects=(34RB 36AN 37IR)
fi

#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_noSliceTimingCorrection

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "analyzing subject $subj"

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir


##### make some folders:
mkdir -p $sub_dir/rois/epi
mkdir -p $sub_dir/rois/anatomical

##### make r hem and l hem sphere - I do it for each subject, the AvRef creates very slightly diff resolution around the 2mm (e.g., can be 2.000004 or 2.000002).
#using R/L side of other participants can create problems later for splitting to sides, so I create right and left sides for each participant.
if [ ! -f $sub_dir/rois/epi/rside.nii.gz ]; then
	fslmaths \
	$sub_dir/$anatomy_dir/AvRefimage_fm \
	-roi 0 68 0 136 0 57 0 1 -bin \
	$sub_dir/rois/epi/lside

	fslmaths \
	$sub_dir/$anatomy_dir/AvRefimage_fm \
	-roi 68 68 0 136 0 57 0 1 -bin \
	$sub_dir/rois/epi/rside
fi

################################################
#make a more conservative brain edge mask. Alexa did it with thresholding the mean_func to 5000.
#I want to do it on the AvRefImage, because this is the space where eventually all ROIs will be.
#the average reference image creates weird intensities which makes it difficult to have a good brain mask based on that,
#or to run bet on it. To go around that, I register the mean_func of the frist run on day1 to the AvRefImage, then thresholding that.
if [ ! -f "$sub_dir/$anatomy_dir/epi_mask.nii.gz" ]; then
#apply the transformation matrix:
scan=$sub_dir/$preproc_dir/similarity_post_l1_no_smooth.feat/mean_func
flirt \
-in $scan \
-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
-applyxfm -init $sub_dir/$preproc_dir/similarity_post_l1_no_smooth.feat/reg/example_func2AvRef.mat \
-out $sub_dir/$anatomy_dir/mean_func2RefAv

#now create the brain mask, in the AvRef space - Alexa did 5000, I looked at my image and seemed too strict, may be related to scanner differences. so I took 3000.
fslmaths $sub_dir/$anatomy_dir/mean_func2RefAv -thr 3000 -bin $sub_dir/$anatomy_dir/epi_mask
fi

################################################
#copy a warp from mprage to standard to the anatomy folder, to be used later:
cp $sub_dir/$preproc_dir/similarity_pre_l1_no_smooth.feat/reg/highres2standard.mat $sub_dir/$anatomy_dir/highres2standard2mm.mat
cp $sub_dir/$preproc_dir/similarity_pre_l1_no_smooth.feat/reg/standard2highres.mat $sub_dir/$anatomy_dir/standard2mm2highres.mat
cp $sub_dir/$preproc_dir/similarity_pre_l1_no_smooth.feat/reg/highres2standard_warp.nii.gz $sub_dir/$anatomy_dir/highres2standard2mm_warp.nii.gz

if [ ! -e "$sub_dir/$anatomy_dir/standard2mm2highres_warp.nii.gz" ]; then	
	echo "creating inverse warp from standard (2mm) to mprage"
 	invwarp \
 	--ref=$sub_dir/$anatomy_dir/mprage \
 	--warp=$sub_dir/$anatomy_dir/highres2standard2mm_warp \
 	--out=$sub_dir/$anatomy_dir/standard2mm2highres_warp
fi   

################################################
#create the mask for only grey matter - we'll use that later when registering regions from standard to epi space:
fslmaths $sub_dir/$anatomy_dir/mprage_seg -thr 2 -uthr 2 -bin $sub_dir/$anatomy_dir/mprage_grey

#apply the transformation to AvRef
flirt \
-in $sub_dir/$anatomy_dir/mprage_grey \
-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
-applyxfm -init $sub_dir/$anatomy_dir/mprage2AvRef.mat \
-out $sub_dir/$anatomy_dir/AvRef_grey

#threshold and binarize
fslmaths $sub_dir/$anatomy_dir/AvRef_grey -thr 0.5 -bin $sub_dir/$anatomy_dir/AvRef_grey

#apply the epi mask on the grey matter mask:
fslmaths $sub_dir/$anatomy_dir/AvRef_grey -mul $sub_dir/$anatomy_dir/epi_mask $sub_dir/$anatomy_dir/AvRef_grey


################################################
##FREESURFER SUBCORTICAL SEGMENTATION
cd $sub_dir/rois/anatomical
fs_dir=$sub_dir/data/autorecon #freesurfer dir
mkdir -p $fs_dir/rois

#create a nifti file for the aparc+aseg.mgz file that has all the lables(no hipp subfields):
#this file has both entorhinal and parahipp. However, note that the entorhinal is very inclusive.
mri_convert \
-rl  $fs_dir/mri/rawavg.mgz \
-rt nearest $fs_dir/mri/aparc+aseg.mgz \
$fs_dir/rois/aparc_aseg2mprage.nii.gz

#this file has only parahipp. maybe good to take parahipp from that and segment manually - currently not implemented (7/10/2018):
mri_convert \
-rl  $fs_dir/mri/rawavg.mgz \
-rt nearest $fs_dir/mri/aparc.a2009s+aseg.mgz \
$fs_dir/rois/Destrieux2mprage.nii.gz

#this file has the hipp subfields - left hemi:
mri_convert \
-rl  $fs_dir/mri/rawavg.mgz \
-rt nearest $fs_dir/mri/lh.hippoSfLabels-T1-t1andt2_seg.v10.mgz \
$fs_dir/rois/lhippSF2mprage.nii.gz

#this file has the hipp subfields - right hemi:
mri_convert \
-rl  $fs_dir/mri/rawavg.mgz \
-rt nearest $fs_dir/mri/rh.hippoSfLabels-T1-t1andt2_seg.v10.mgz \
$fs_dir/rois/rhippSF2mprage.nii.gz


################################################################
#hipp subfields from FREESURFER
# extract hipp subfields
echo "extracting fs hippocampal subregions for subject $subj"
declare -a hipp_rois=(parasubiculum perisubiculum subiculum ca1 ca23 ca4 dg HATA fimbria mollayer fissure hptail)
declare -a hipp_labels=(203 204 205 206 208 209 210 211 212 214 215 226)
idx=0
for roi in ${hipp_rois[@]}
do
	fslmaths $fs_dir/rois/rhippSF2mprage.nii.gz -thr ${hipp_labels[idx]} -uthr ${hipp_labels[idx]} -bin fs_r${roi}
	fslmaths $fs_dir/rois/lhippSF2mprage.nii.gz -thr ${hipp_labels[idx]} -uthr ${hipp_labels[idx]} -bin fs_l${roi}
	fslmaths fs_l${roi} -add fs_r${roi} fs_${roi}
	((idx+=1))
done

fs_dir=$sub_dir/data/autorecon #freesurfer dir
cd $sub_dir/rois/anatomical

#####creating a hipp mask based on the subfields - excluding the fissure (215) and fimbria (212, white matter):

#get the entire thing
fslmaths $fs_dir/rois/rhippSF2mprage.nii.gz -thr 203 -uthr 226 -bin fs_rhippFromSF

#subtract fimbria and the fissure from the big hipp:
fslmaths fs_rhippFromSF -sub fs_rfimbria fs_rhippFromSF
fslmaths fs_rhippFromSF -sub fs_rfissure fs_rhippFromSF

#get the entire thing
fslmaths $fs_dir/rois/lhippSF2mprage.nii.gz -thr 203 -uthr 226 -bin fs_lhippFromSF

#subtract fimbria and the fissure from the big hipp:
fslmaths fs_lhippFromSF -sub fs_lfimbria fs_lhippFromSF
fslmaths fs_lhippFromSF -sub fs_lfissure fs_lhippFromSF

#make a bilateral hipp roi:
fslmaths fs_lhippFromSF -add fs_rhippFromSF fs_hippFromSF

#now subtract HATA:
fslmaths fs_lhippFromSF -sub fs_lHATA fs_lhippFromSF_noHATA
fslmaths fs_rhippFromSF -sub fs_rHATA fs_rhippFromSF_noHATA
fslmaths fs_hippFromSF -sub fs_HATA fs_hippFromSF_noHATA

#register the anatomical rois to AvRef space:
echo "registering fs hipp from subregions to RefAv using flirt subject $subj"
#first, create the hippocampal mask by thresholding the full volume to 0.5, so we're sure it's hippocampus:
for roi in lhippFromSF rhippFromSF hippFromSF lhippFromSF_noHATA rhippFromSF_noHATA hippFromSF_noHATA; do

	flirt \
	-in $sub_dir/rois/anatomical/fs_${roi} \
	-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
	-applyxfm -init $sub_dir/$anatomy_dir/mprage2AvRef.mat \
	-out $sub_dir/rois/epi/fs_${roi}
	
	sleep 0.5

	#binarise
	fslmaths $sub_dir/rois/epi/fs_${roi} -thr 0.5 -bin $sub_dir/rois/epi/fs_${roi}
	
	#apply epi mask - these are subcortical regions - don't apply the grey matter.
 	fslmaths $sub_dir/rois/epi/fs_$roi \
 	-mul $sub_dir/$anatomy_dir/epi_mask \
 	$sub_dir/rois/epi/fs_$roi 
done

#make sure hipp and amygdala do not overlap: delete overlapping voxels from amygdala, since hipp is based on fs subregions:
#bilateral:
fslmaths \
	$sub_dir/rois/epi/fs_hippFromSF  \
	-add $sub_dir/rois/epi/first_amygdala \
	-thr 2 $sub_dir/rois/epi/fs_hippFromSF_first_amygdala_overlapp

fslmaths \
	$sub_dir/rois/epi/first_amygdala \
	-sub $sub_dir/rois/epi/fs_hippFromSF_first_amygdala_overlapp \
	-thr 0 -bin $sub_dir/rois/epi/first_amygdala
#right hem:
fslmaths \
	$sub_dir/rois/epi/fs_rhippFromSF  \
	-add $sub_dir/rois/epi/first_ramygdala \
	-thr 2 $sub_dir/rois/epi/fs_rhippFromSF_first_amygdala_overlapp

fslmaths \
	$sub_dir/rois/epi/first_ramygdala \
	-sub $sub_dir/rois/epi/fs_rhippFromSF_first_amygdala_overlapp \
	-thr 0 -bin $sub_dir/rois/epi/first_ramygdala

#left hem:
fslmaths \
	$sub_dir/rois/epi/fs_lhippFromSF  \
	-add $sub_dir/rois/epi/first_lamygdala \
	-thr 2 $sub_dir/rois/epi/fs_lhippFromSF_first_amygdala_overlapp

fslmaths \
	$sub_dir/rois/epi/first_lamygdala \
	-sub $sub_dir/rois/epi/fs_lhippFromSF_first_amygdala_overlapp \
	-thr 0 -bin $sub_dir/rois/epi/first_lamygdala


#call the make_hipp_subfields function, that iterates through the regions and take the max:
cd $proj_dir
#run make hipp subfields
if (( $run_hipp_subfields == 1 )); then
	#echo "creating hipp subfields for subject $subj"
	scripts/PreprocessingAndModel/make_hipp_subfields.sh $subj $engram
fi

fs_dir=$sub_dir/data/autorecon #freesurfer dir
cd $sub_dir/rois/anatomical

if (( $run_qa == 1 )); then
#QA! look at all of the regions in the mprage space:
#create a file with only the regions I care about:
fs_dir=$sub_dir/data/autorecon #freesurfer dir


# #QA view them
echo "
Pulling up FSLEYES for hipp subregions in epi space, and some cortex, $subj. 
examine the regions. When finished checking, close the FSLVIEW window"
 
threshname=025
fsleyes $sub_dir/$anatomy_dir/AvRefimage_fm \
 		$sub_dir/rois/epi/fs_ca1_${threshname} -cm Red \
 		$sub_dir/rois/epi/fs_ca23_${threshname} -cm Green \
 		$sub_dir/rois/epi/fs_ca4_${threshname} -cm Yellow \
 		$sub_dir/rois/epi/fs_dg_${threshname} -cm Blue 
	
else
	echo "you didn't QA!! make sure to QA rois later!"
fi #ends the run_qa part


echo "
all done subject $subj. 
run splitt hipp axis in matlab to create the anterior and posterior hipp masks"

done