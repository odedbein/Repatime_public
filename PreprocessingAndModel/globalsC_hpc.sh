#!/bin/bash -e -u
# Author: Oded Bein, after Alexa Tompary
# List of relative file paths starting in each subject directory
echo 'running globals'
proj_dir=/rigel/psych/projects/davachilab/Bein/Repatime/repatime_scanner

subjects_dir=$proj_dir/SubData
fsl_templates=$proj_dir/fsl_templates

#folders of each subject
analysis_dir=analysis
data_dir=data/processed
design_dir=design
preproc_dir=$analysis_dir/preproc
enc_dir=$analysis_dir/encoding
sim_dir=$analysis_dir/similarity
order_dir=$analysis_dir/order_test
color_dir=$analysis_dir/color_test
tmaps_dir=single_trial_Tmaps
#SM_DIR=analysis/sm_sm6
output_dir=analysis_files
tmaps_dir=single_trial_Tmaps
roi_dir=rois
anatomy_dir=data/anatomy
fm_dir=data/fieldmap

KERNEL_SIZE=8 # size of ROI kernel
SMOOTH_SIZE=6 # size of smoothing kernel

#master_run=localizer_run1 # align all ROIs and statistical maps to this run's native space
#standard=$PROJECT_DIR/design/standard

#ALL_SUBJECTS=`ls -1d subjects/* | cut -c 10-12`


#I re-write the subject folder when I run recon-all, so no need to redifne it, but if want to - do it here:
#SUBJECTS_DIR=$subjects_dir
