#!/bin/bash -e -u
# Author: Oded Bein
# This script makes hipp subfields in a "winner takes all" manner. After registration, it attributes each
#voxel per subfield based on the highest value (i.e., if a voxel has .4 CA3, .2DG and .3 CA1 - it'll go to CA3)
# It also have a threshold you can set (see threshold snd threshname variables). That gives a minimum value
#for the subfield. In my analyses, I used .25 threshold. This means that a subfield needs to have at least .25
# in order to win. (can happen that it's lower, values do not have to complete to 1, if some part of the voxel
# did not originate from any roi in the anatomical space).
#I also mask all ROIs with a big hipp mask, to make sure I only take hipp voxels (requires that the hipp mask is created before).
#NOTE: this procedure is novel, hasn't gone through peer review yet (as of Sept 2021).

#INPUTS:
subj=$1 #subj directory, e.g., 2ZD
engram=$2 # 1 if running on engram, 0 if not

#VARIABLES
thresh=0.25 #change this to change the minimal threshold per subfield (see above)
threshname=025 #this will just go into the name of the mask file, so change it accordingly.

if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir
fs_dir=$sub_dir/data/autorecon #freesurfer dir


declare -a rois=(parasubiculum perisubiculum subiculum ca1 ca23 ca4 dg HATA mollayer hptail)
#ca4dg rca4dg lca4dg ca234dg rca234dg lca234dg
#for the subfields, create a more lenient thresholding, don't bin yet:
echo "making fs hippocampal subregions for subject $subj, taking the max value per region"

initthresh=00
initthreshname=00

for roi in ${rois[@]}; do

	flirt \
	-in $sub_dir/rois/anatomical/fs_${roi} \
	-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
	-applyxfm -init $sub_dir/$anatomy_dir/mprage2AvRef.mat \
	-out $sub_dir/rois/epi/fs_${roi}_${initthreshname}
	
	sleep 0.5

	#threshold
	fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} -thr $initthresh $sub_dir/rois/epi/fs_${roi}_${initthreshname}
	
	#apply hipp mask - to make sure we're selecting voxels in the hipp
 	fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} \
 	-mul $sub_dir/rois/epi/fs_hippFromSF \
 	$sub_dir/rois/epi/fs_${roi}_${initthreshname}
done

for roi in fimbria fissure; do

	flirt \
	-in $sub_dir/rois/anatomical/fs_${roi} \
	-ref $sub_dir/$anatomy_dir/AvRefimage_fm \
	-applyxfm -init $sub_dir/$anatomy_dir/mprage2AvRef.mat \
	-out $sub_dir/rois/epi/fs_${roi}_${initthreshname}
	
	sleep 0.5

	#threshold
	fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} -thr $initthresh $sub_dir/rois/epi/fs_${roi}_${initthreshname}
done


#now, for each roi, go through the rest and take the max 
declare -a rois=(parasubiculum perisubiculum subiculum ca1 ca23 ca4 dg HATA mollayer hptail fimbria fissure)

for roi in ${rois[@]}; do
	
	for otherroi in ${rois[@]}; do
		if [ $roi != $otherroi ]; then
			#echo "$roi $otherroi"
		
			#take the max of the two images:
			#this gives me only voxels in which the current roi has larger values:
			fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} \
			-sub $sub_dir/rois/epi/fs_${otherroi}_${initthreshname} \
			-thr 0 \
			$sub_dir/rois/epi/fs_temp_overlap
			
			#mask the current roi by the overlap: it by
			fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} \
			-mas $sub_dir/rois/epi/fs_temp_overlap \
			$sub_dir/rois/epi/fs_${roi}_${initthreshname}
			
		fi
	done
done

#now thresh, binarise, and make the hemispheres rois:
#this procedure create minimun values of about 0.3 anyway, so doesn't matter much, but I wanted to threshold just to not have absurdly small values by chance
declare -a rois=(parasubiculum perisubiculum subiculum ca1 ca23 ca4 dg HATA mollayer hptail)
 
for roi in ${rois[@]}; do
	#echo "bin $roi"
	#threshold and binarise
	fslmaths $sub_dir/rois/epi/fs_${roi}_${initthreshname} -thr $thresh -bin $sub_dir/rois/epi/fs_${roi}_${threshname}
	
	#make the left roi
 	fslmaths $sub_dir/rois/epi/fs_${roi}_${threshname} \
 	-mul $sub_dir/rois/epi/lside \
 	$sub_dir/rois/epi/fs_l${roi}_${threshname}
 	
 	#make the right roi
 	fslmaths $sub_dir/rois/epi/fs_${roi}_${threshname} \
 	-mul $sub_dir/rois/epi/rside \
 	$sub_dir/rois/epi/fs_r${roi}_${threshname}
done


