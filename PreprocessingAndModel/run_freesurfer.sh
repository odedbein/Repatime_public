#!/bin/bash
# Author: Oded Bein
#this script runs freesurfer recon-all and the segmentation of hipp subfields, and view the segmentation

# Important note: for subfields, make sure you use Freesurfer 6.0 and above - before that, subfields segmentation is crappy.
# It is important to have both T1 and T2 scans. Otherwise, freesurfer outputs all the subfields,
# but it ‘guesses’ one of the layer that separates CA from DG so it’s less accurate.

#INPUTS:
subj=$1 #subj directory, e.g., 2ZD
engram=$2 # 1 if running on engram, 0 if not

if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi

sub_dir=$subjects_dir/$subj
sub_data_dir=$subjects_dir/$subj/$data_dir

# ######## run freesurfer ##########
t1=$sub_dir/$anatomy_dir/mprage.nii.gz
t2=$sub_dir/$anatomy_dir/T2image.nii.gz

delete_prev_dir=0
if (( $delete_prev_dir == 1 )); then
	echo "deleting old fs folders"
	if [ -d "$sub_dir/data/autorecon" ]; then 	
		rm -r $sub_dir/data/autorecon
		rm -r $sub_dir/data/fsaverage
	fi
fi

	
#run recon-all with segmenting hipp subfields
recon-all -all -i $t1 -T2 $t2 -subjid autorecon -sd $sub_dir/data -hippocampal-subfields-T1T2 $t2 t1andt2_seg

#this is without hipp subfields:
#recon-all -all -i $t1 -T2 $t2 -subjid autorecon -sd $sub_dir/data

#this is only hipp subfields, after creating the regular one:
#recon-all -subjid autorecon -sd $sub_dir/data -hippocampal-subfields-T1T2 $t2 t1andt2_seg
#recon-all -subjid autorecon -sd $sub_dir/data -hippocampal-subfields-T1

qa=0
if (( $qa == 1 )); then
	#view the cortical and subcortical segmentation, (no hipp subfields)
	output_dir=$sub_dir/data/autorecon
	freeview -v \
	$output_dir/mri/T1.mgz \
	$output_dir/mri/wm.mgz \
	$output_dir/mri/brainmask.mgz \
	$output_dir/mri/aparc+aseg.mgz:colormap=lut:opacity=0.4 \
	-f $output_dir/surf/lh.white:edgecolor=blue \
	$output_dir/surf/lh.pial:edgecolor=red \
	$output_dir/surf/rh.white:edgecolor=blue \
	$output_dir/surf/rh.pial:edgecolor=red

	#view the cortical segmentation (no hipp subfields)
	freeview -f  $output_dir/surf/lh.pial:annot=aparc.annot:name=pial_aparc:visible=0 \
	$output_dir/surf/lh.pial:annot=aparc.a2009s.annot:name=pial_aparc_des:visible=0 \
	$output_dir/surf/lh.inflated:overlay=lh.thickness:overlay_threshold=0.1,3::name=inflated_thickness:visible=0 \
	$output_dir/surf/lh.inflated:visible=0 \
	$output_dir/surf/lh.white:visible=0 \
	$output_dir/surf/lh.pial \
	--viewport 3d

	#view the hipp segmentation:
	freeview -v \
	$output_dir/mri/T1.mgz \
	$output_dir/mri/t1andt2_seg.FSspace.mgz \
	$output_dir/mri/lh.hippoSfLabels-T1-t1andt2_seg.v10.mgz:colormap=lut \
	$output_dir/mri/rh.hippoSfLabels-T1-t1andt2_seg.v10.mgz:colormap=lut 
	
	#view the hipp segmentation:
	freeview -v \
	$output_dir/mri/T1.mgz \
	$output_dir/label/rh.entorhinal_exvivo.label
	$output_dir/label/rh.entorhinal_exvivo.thresh.label
	
	
	
	tksurfer 
fi


#default: Desikan-Killiany atlas: aparc+aseg
#Destrieux atlas: aparc.a2009s+aseg - more regions
#DKT Atlas: aparc.DKTatlas+aseg