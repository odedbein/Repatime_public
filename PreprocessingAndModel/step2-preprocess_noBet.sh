##!/bin/bash -e -u
# Author: Alexa Tompary, modified by Oded Bein
# This script renders and runs the design files 
# to preprocess all functional scans from both sessions

if [ $# -ne 1 ]; then
  echo "
usage: `basename $0` engram

This script runs FEAT to preprocess the functional 
scans from both simcon sessions.
"
  exit
fi
#all subjects in the study
declare -a subjects=(10BL 22JP 26MM) #these participants need to run bet before
#declare -a subjects=(22JP) #these participants need to run bet before

engram=$@
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh
fi
#here's an option to run a part of the script - search for the corresponding fi and locate it wherever you want
run_this_part=0
#if you want to run reg to average as well, set it here
run_RegToAv=0
#if you want to create anatomical rois, set it here - make sure that Freesurfer and RegToAv were run
run_anatomical_rois=0
#if you want to preproc the data for ICA, then it's advisable to add another mask, flag here to create it
ICA=0

#delete previous preproc dirs:
delete_prev_dir=0

#run bet: set this to 1 - its for some other subjects
runbet=0
preproc_type=noHPfilter_noSliceTimingCorrection #noSliceTimingCorrectio
#override the global preproc dir:
preproc_dir=$analysis_dir/preproc_${preproc_type}

#set up preproc fsl templates
fsl_templates=$fsl_templates/preproc

#LOOP FOR ALL SUBJECTS
for subj in "${subjects[@]}"
do

echo "analyzing step2-preproc for subject $subj"

if (( $delete_prev_dir == 1 )); then	
	echo "you chose to delete previous preproc dirs for $subj"
fi


sub_dir=$subjects_dir/$subj
sub_motion_dir=$sub_dir/$analysis_dir/motion_assess
sub_data_dir=$subjects_dir/$subj/$data_dir #pre-processed scans are there
sub_analysis_dir=$sub_dir/$analysis_dir
outhtml=$sub_analysis_dir/qa/bold_outliermotion_QA_noSliceTimingCorrection.html
subj_design_dir=$sub_dir/design_dir/preproc_${preproc_type}

#rm $outhtml

echo $sub_data_dir

#make needed directories for the analysis
mkdir -p $sub_dir/$preproc_dir
mkdir -p $sub_dir/$sim_dir
mkdir -p $sub_dir/$enc_dir
mkdir -p $sub_dir/$order_dir
mkdir -p $sub_dir/$color_dir

#make design dir
mkdir -p $subj_design_dir

#make qa dir
if [ ! -d $sub_analysis_dir/qa ]; then
	mkdir $sub_analysis_dir/qa
fi

echo "<h1> motion outliers QA file <h1>" >> $outhtml

#set BET params:
#subj 22JP had a problem lists 5 and 6 - ran bet before for all, just for consistency
#param for  10BL, 26MM - for all, need to run bet before
if [ $subj == "10BL" ]; then
	F=.3
	G=.1
	X=67
	Y=70
	Z=31
elif [ $subj == "22JP" ]; then
	F=.3
	G=.1
	X=67
	Y=72
	Z=29
elif [ $subj == "26MM" ]; then
	F=.3
	G=.1
	X=67
	Y=74
	Z=33
fi 

# render the encoding templates for each list and each repetition
for l in 1 2 3 4 5 6; do
	for r in 1 2 3 4 5; do 
		curr_scan=$sub_data_dir/encoding_l${l}_rep${r}_fm
		cat $fsl_templates/preproc_${preproc_type}.fsf.template \
			| sed "s|inputscan|$curr_scan|g" \
			| sed "s|project_dir|$proj_dir|g" \
			| sed "s|output_dir|$sub_dir/$preproc_dir/encoding_l${l}_rep${r}_no_smooth|g" \
			| sed "s|subj|$subj|g" \
			| sed "s|numvol|77|g" \
			| sed "s|smooth_size|0|g" \
			| sed "s|fsldir|$FSLDIR|g" \
			| sed "s|runbet|$runbet|g" \
			> $subj_design_dir/preproc_encoding_l${l}_rep${r}_no_smooth.fsf
	done
done
	
if (( $run_this_part == 1 )); then	
# render the similarity pre-post templates for each list
for l in 1 2 3 4 5 6; do
	
	curr_scan=$sub_data_dir/similarity_pre_l${l}_fm
	cat $fsl_templates/preproc_engramC_noBet_noSliceTimingCorrection.fsf.template \
		| sed "s|inputscan|$curr_scan|g" \
		| sed "s|project_dir|$proj_dir|g" \
		| sed "s|output_dir|$sub_dir/$preproc_dir/similarity_pre_l${l}_no_smooth|g" \
		| sed "s|subj|$subj|g" \
		| sed "s|numvol|113|g" \
		| sed "s|smooth_size|0|g" \
		| sed "s|fsldir|$FSLDIR|g" \
		> $subj_design_dir/preproc_similarity_pre_l${l}_no_smooth.fsf
	
	curr_scan=$sub_data_dir/similarity_post_l${l}_fm
	cat $fsl_templates/preproc_engramC_noBet_noSliceTimingCorrection.fsf.template \
		| sed "s|inputscan|$curr_scan|g" \
		| sed "s|project_dir|$proj_dir|g" \
		| sed "s|output_dir|$sub_dir/$preproc_dir/similarity_post_l${l}_no_smooth|g" \
		| sed "s|subj|$subj|g" \
		| sed "s|numvol|113|g" \
		| sed "s|smooth_size|0|g" \
		| sed "s|fsldir|$FSLDIR|g" \
		> $subj_design_dir/preproc_similarity_post_l${l}_no_smooth.fsf
		
done


# render the order_test templates for each list
for l in 1 2 3 4 5 6; do
	
	curr_scan=$sub_data_dir/order_test_l${l}_fm
	cat $fsl_templates/preproc_engramC_noBet_noSliceTimingCorrection.fsf.template \
		| sed "s|inputscan|$curr_scan|g" \
		| sed "s|project_dir|$proj_dir|g" \
		| sed "s|output_dir|$sub_dir/$preproc_dir/order_test_l${l}_no_smooth|g" \
		| sed "s|subj|$subj|g" \
		| sed "s|numvol|159|g" \
		| sed "s|smooth_size|0|g" \
		| sed "s|fsldir|$FSLDIR|g" \
		> $subj_design_dir/preproc_order_test_l${l}_no_smooth.fsf
	
done

# render the color_test templates for each run
for r in 1 2 3 4; do
	
	curr_scan=$sub_data_dir/color_test_run${r}_fm
	cat $fsl_templates/preproc_engramC_noBet_noSliceTimingCorrection.fsf.template \
		| sed "s|inputscan|$curr_scan|g" \
		| sed "s|project_dir|$proj_dir|g" \
		| sed "s|output_dir|$sub_dir/$preproc_dir/color_test_run${r}_no_smooth|g" \
		| sed "s|subj|$subj|g" \
		| sed "s|numvol|186|g" \
		| sed "s|smooth_size|0|g" \
		| sed "s|fsldir|$FSLDIR|g" \
		> $subj_design_dir/preproc_color_test_run${r}_no_smooth.fsf
	
done

fi #if run part
##### ENCODING: run motion assessment and FEAT #######

for l in {1..6}; do #{1..6}

	for r in {1..5}; do #{1..5}

		scan_name=encoding_l${l}_rep${r}
		subj_output_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth
		curr_motion_dir=$sub_motion_dir/${scan_name}
		curr_scan=$sub_data_dir/${scan_name}_fm
		
		mkdir -p $curr_motion_dir
	
		if [ ! -f $curr_motion_dir/fd_plot.png ]; then
			echo "running motion assessment on scan ${scan_name}" 
			fsl_motion_outliers -i $curr_scan -o $curr_motion_dir/confound.txt --fd --thresh=0.9 -p $curr_motion_dir/fd_plot -v \
			> $curr_motion_dir/outlier_output.txt
		fi

		# Put confound info into html file for review later on
		echo "<p>=============<p>" >> $outhtml   
		cat $curr_motion_dir/outlier_output.txt >> $outhtml
		echo "<p>FD plot ${scan_name} <br><IMG BORDER=0 SRC=$curr_motion_dir/fd_plot.png WIDTH=100%%></BODY></HTML> " \
		>> $outhtml   

		# Last, if we're planning on modeling out scrubbed volumes later
		#   it is helpful to create an empty file if confound.txt isn't
		#   generated (i.e. no scrubbing needed).  It is basically a
		#   place holder to make future scripting easier
		if [ ! -f $curr_motion_dir/confound.txt ]; then
		echo >> $curr_motion_dir/confound.txt
		fi
	
	  
		#run feat:        
		if [ ! -f "$subj_output_dir.feat/absbrainthresh.txt" ]; then 	
			rm -rf $subj_output_dir.feat
			echo "running FEAT preprocessing on subj $subj ${scan_name}"
			feat $subj_design_dir/preproc_${scan_name}_no_smooth.fsf &
			sleep 10
			scripts/PreprocessingAndModel/wait-for-feat.sh $subj_output_dir.feat
			
			#copy the registration folder from the preprocessing I did with filtering, shouldn't matter
			#so I didn't run it again
			#cp -rf $sub_dir/$analysis_dir/preproc/${scan_name}_no_smooth.feat/reg $subj_output_dir.feat/
		
			#ICA option - create a mask:
			if (( $ICA == 1 )); then	
				if [ ! -d "$subj_output_dir.feat/example_func_brain_mask.nii.gz" ]; then 
					bet $subj_output_dir.feat/example_func $subj_output_dir.feat/example_func_brain -f 0.3 -n -m -R 
				fi
			fi
			
			#run bet to create a proper mask:
			rm $subj_output_dir.feat/mask.nii.gz
			echo "bet parameters for subj $subj F $F G $G X $X Y $Y Z $Z"
			bet $subj_output_dir.feat/mean_func $subj_output_dir.feat/mask -f $F -g $G -c $X $Y $Z -n -m
			cp $subj_output_dir.feat/mask_mask.nii.gz $subj_output_dir.feat/mask.nii.gz
			rm $subj_output_dir.feat/mask_mask.nii.gz
			for image in filtered_func_data mean_func example_func ; do
				fslmaths $subj_output_dir.feat/$image -mas $subj_output_dir.feat/mask $subj_output_dir.feat/$image
			done

		fi
		

	done #repetition
	
done #lists


if (( $run_this_part == 1 )); then	
##### SIMILARITY: run motion assessment and FEAT #######

for l in {1..6}; do #

	#similarity pre
	scan_name=similarity_pre_l${l}
	subj_output_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth
	curr_motion_dir=$sub_motion_dir/${scan_name}
	curr_scan=$sub_data_dir/${scan_name}_fm
	
	mkdir -p $curr_motion_dir
	
	if [ ! -f $curr_motion_dir/fd_plot.png ]; then
	echo "running motion assessment on scan ${scan_name}" 
		fsl_motion_outliers -i $curr_scan -o $curr_motion_dir/confound.txt --fd --thresh=0.9 -p $curr_motion_dir/fd_plot -v \
		> $curr_motion_dir/outlier_output.txt
	fi

	# Put confound info into html file for review later on
	echo "<p>=============<p>" >> $outhtml 
	cat $curr_motion_dir/outlier_output.txt >> $outhtml
	echo "<p>FD plot ${scan_name} <br><IMG BORDER=0 SRC=$curr_motion_dir/fd_plot.png WIDTH=100%%></BODY></HTML> " \
	>> $outhtml   

	# Last, if we're planning on modeling out scrubbed volumes later
	#   it is helpful to create an empty file if confound.txt isn't
	#   generated (i.e. no scrubbing needed).  It is basically a
	#   place holder to make future scripting easier
	if [ ! -f $curr_motion_dir/confound.txt ]; then
	echo >> $curr_motion_dir/confound.txt
	fi
	
      
    #run feat:        
	if [ ! -f "$subj_output_dir.feat/absbrainthresh.txt" ]; then 	
		rm -rf $subj_output_dir.feat
		echo "running FEAT preprocessing on subj $subj ${scan_name}"
		feat $subj_design_dir/preproc_${scan_name}_no_smooth.fsf &
		sleep 10
		scripts/PreprocessingAndModel/wait-for-feat.sh $subj_output_dir.feat
		
		#copy the registration folder from the preprocessing I did with filtering, shouldn't matter
		#so I didn't run it again
		#cp -rf $sub_dir/$analysis_dir/preproc/${scan_name}_no_smooth.feat/reg $subj_output_dir.feat/
	
		#ICA option - create a mask:
		if (( $ICA == 1 )); then	
			if [ ! -d "$subj_output_dir.feat/example_func_brain_mask.nii.gz" ]; then 
				bet $subj_output_dir.feat/example_func $subj_output_dir.feat/example_func_brain -f 0.3 -n -m -R 
			fi
		fi
		
		#run bet to create a proper mask:
		rm $subj_output_dir.feat/mask.nii.gz
		echo "bet parameters for subj $subj F $F G $G X $X Y $Y Z $Z"
		bet $subj_output_dir.feat/mean_func $subj_output_dir.feat/mask -f $F -g $G -c $X $Y $Z -n -m
		cp $subj_output_dir.feat/mask_mask.nii.gz $subj_output_dir.feat/mask.nii.gz
		rm $subj_output_dir.feat/mask_mask.nii.gz
		for image in filtered_func_data mean_func example_func ; do
			fslmaths $subj_output_dir.feat/$image -mas $subj_output_dir.feat/mask $subj_output_dir.feat/$image
		done
	fi
	
	
			
	#similarity post
	scan_name=similarity_post_l${l}
	subj_output_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth
	curr_motion_dir=$sub_motion_dir/${scan_name}
	curr_scan=$sub_data_dir/${scan_name}_fm
	mkdir -p $curr_motion_dir
	
	if [ ! -f $curr_motion_dir/fd_plot.png ]; then
	echo "running motion assessment on subj $subj scan ${scan_name}" 
		fsl_motion_outliers -i $curr_scan -o $curr_motion_dir/confound.txt --fd --thresh=0.9 -p $curr_motion_dir/fd_plot -v \
		> $curr_motion_dir/outlier_output.txt
	fi

	# Put confound info into html file for review later on
	echo "<p>=============<p>" >> $outhtml   
	cat $curr_motion_dir/outlier_output.txt >> $outhtml
	echo "<p>FD plot ${scan_name} <br><IMG BORDER=0 SRC=$curr_motion_dir/fd_plot.png WIDTH=100%%></BODY></HTML> " \
	>> $outhtml   

	# Last, if we're planning on modeling out scrubbed volumes later
	#   it is helpful to create an empty file if confound.txt isn't
	#   generated (i.e. no scrubbing needed).  It is basically a
	#   place holder to make future scripting easier
	if [ ! -f $curr_motion_dir/confound.txt ]; then
	echo >> $curr_motion_dir/confound.txt
	fi
	
      
    #run feat:        
	if [ ! -f "$subj_output_dir.feat/absbrainthresh.txt" ]; then 	
		rm -rf $subj_output_dir.feat
		echo "running FEAT preprocessing on subj $subj ${scan_name}"
 		feat $subj_design_dir/preproc_${scan_name}_no_smooth.fsf &
 		sleep 10
 		scripts/PreprocessingAndModel/wait-for-feat.sh $subj_output_dir.feat
 		
 		#copy the registration folder from the preprocessing I did with filtering, shouldn't matter
		#so I didn't run it again
		#cp -rf $sub_dir/$analysis_dir/preproc/${scan_name}_no_smooth.feat/reg $subj_output_dir.feat/
	
		#ICA option - create a mask:
		if (( $ICA == 1 )); then	
			if [ ! -d "$subj_output_dir.feat/example_func_brain_mask.nii.gz" ]; then 
				bet $subj_output_dir.feat/example_func $subj_output_dir.feat/example_func_brain -f 0.3 -n -m -R 
			fi
		fi
		
		#run bet to create a proper mask:
		rm $subj_output_dir.feat/mask.nii.gz
		echo "bet parameters for subj $subj F $F G $G X $X Y $Y Z $Z"
		bet $subj_output_dir.feat/mean_func $subj_output_dir.feat/mask -f $F -g $G -c $X $Y $Z -n -m
		cp $subj_output_dir.feat/mask_mask.nii.gz $subj_output_dir.feat/mask.nii.gz
		rm $subj_output_dir.feat/mask_mask.nii.gz
		for image in filtered_func_data mean_func example_func ; do
			fslmaths $subj_output_dir.feat/$image -mas $subj_output_dir.feat/mask $subj_output_dir.feat/$image
		done
	fi
		
done
fi #ends the run this part if - move if don't want to run all script


##### ORDER TEST: run motion assessment and FEAT #######
if (( $run_this_part == 1 )); then	

for l in 1 2 3 4 5 6; do

	scan_name=order_test_l${l}
	subj_output_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth
	curr_motion_dir=$sub_motion_dir/${scan_name}
	curr_scan=$sub_data_dir/${scan_name}_fm
	mkdir -p $curr_motion_dir

	if [ ! -f $curr_motion_dir/fd_plot.png ]; then
	echo "running motion assessment on scan ${scan_name}" 
		fsl_motion_outliers -i $curr_scan -o $curr_motion_dir/confound.txt --fd --thresh=0.9 -p $curr_motion_dir/fd_plot -v \
		> $curr_motion_dir/outlier_output.txt
	fi

	# Put confound info into html file for review later on
	echo "<p>=============<p>" >> $outhtml   
	cat $curr_motion_dir/outlier_output.txt >> $outhtml
	echo "<p>FD plot ${scan_name} <br><IMG BORDER=0 SRC=$curr_motion_dir/fd_plot.png WIDTH=100%%></BODY></HTML> " \
	>> $outhtml   

	# Last, if we're planning on modeling out scrubbed volumes later
	#   it is helpful to create an empty file if confound.txt isn't
	#   generated (i.e. no scrubbing needed).  It is basically a
	#   place holder to make future scripting easier
	if [ ! -f $curr_motion_dir/confound.txt ]; then
	echo >> $curr_motion_dir/confound.txt
	fi

  
	#run feat:        
	if [ ! -f "$subj_output_dir.feat/absbrainthresh.txt" ]; then 	
		rm -rf $subj_output_dir.feat
		echo "running FEAT preprocessing on subj $subj ${scan_name}"
		feat $subj_design_dir/preproc_${scan_name}_no_smooth.fsf &
		sleep 10
		scripts/PreprocessingAndModel/wait-for-feat.sh $subj_output_dir.feat
		
		#copy the registration folder from the preprocessing I did with filtering, shouldn't matter
		#so I didn't run it again
		#cp -rf $sub_dir/$analysis_dir/preproc/${scan_name}_no_smooth.feat/reg $subj_output_dir.feat/
	
		#ICA option - create a mask:
		if (( $ICA == 1 )); then	
			if [ ! -d "$subj_output_dir.feat/example_func_brain_mask.nii.gz" ]; then 
				bet $subj_output_dir.feat/example_func $subj_output_dir.feat/example_func_brain -f 0.3 -n -m -R 
			fi
		fi
		
		#run bet to create a proper mask:
		rm $subj_output_dir.feat/mask.nii.gz
		echo "bet parameters for subj $subj F $F G $G X $X Y $Y Z $Z"
		bet $subj_output_dir.feat/mean_func $subj_output_dir.feat/mask -f $F -g $G -c $X $Y $Z -n -m
		cp $subj_output_dir.feat/mask_mask.nii.gz $subj_output_dir.feat/mask.nii.gz
		rm $subj_output_dir.feat/mask_mask.nii.gz
		for image in filtered_func_data mean_func example_func ; do
			fslmaths $subj_output_dir.feat/$image -mas $subj_output_dir.feat/mask $subj_output_dir.feat/$image
		done
	fi
done #lists


##### COLOR TEST: run motion assessment and FEAT #######

for r in 1 2 3 4; do

	scan_name=color_test_run${r}
	subj_output_dir=$sub_dir/$preproc_dir/${scan_name}_no_smooth
	curr_motion_dir=$sub_motion_dir/${scan_name}
	curr_scan=$sub_data_dir/${scan_name}_fm
	mkdir -p $curr_motion_dir

	if [ ! -f $curr_motion_dir/fd_plot.png ]; then
	echo "running motion assessment on scan ${scan_name}" 
		fsl_motion_outliers -i $curr_scan -o $curr_motion_dir/confound.txt --fd --thresh=0.9 -p $curr_motion_dir/fd_plot -v \
		> $curr_motion_dir/outlier_output.txt
	fi

	# Put confound info into html file for review later on
	echo "<p>=============<p>" >> $outhtml   
	cat $curr_motion_dir/outlier_output.txt >> $outhtml
	echo "<p>FD plot ${scan_name} <br><IMG BORDER=0 SRC=$curr_motion_dir/fd_plot.png WIDTH=100%%></BODY></HTML> " \
	>> $outhtml   

	# Last, if we're planning on modeling out scrubbed volumes later
	#   it is helpful to create an empty file if confound.txt isn't
	#   generated (i.e. no scrubbing needed).  It is basically a
	#   place holder to make future scripting easier
	if [ ! -f $curr_motion_dir/confound.txt ]; then
	echo >> $curr_motion_dir/confound.txt
	fi

  
	#run feat:        
	if [ ! -f "$subj_output_dir.feat/absbrainthresh.txt" ]; then 	
		rm -rf $subj_output_dir.feat
		echo "running FEAT preprocessing on subj $subj ${scan_name}"
		feat $subj_design_dir/preproc_${scan_name}_no_smooth.fsf &
		sleep 10
		scripts/PreprocessingAndModel/wait-for-feat.sh $subj_output_dir.feat
		
		#copy the registration folder from the preprocessing I did with filtering, shouldn't matter
		#so I didn't run it again
		#cp -rf $sub_dir/$analysis_dir/preproc/${scan_name}_no_smooth.feat/reg $subj_output_dir.feat/
	
		#ICA option - create a mask:
		if (( $ICA == 1 )); then	
			if [ ! -d "$subj_output_dir.feat/example_func_brain_mask.nii.gz" ]; then 
				bet $subj_output_dir.feat/example_func $subj_output_dir.feat/example_func_brain -f 0.3 -n -m -R 
			fi
		fi
		
		#run bet to create a proper mask:
		rm $subj_output_dir.feat/mask.nii.gz
		echo "bet parameters for subj $subj F $F G $G X $X Y $Y Z $Z"
		bet $subj_output_dir.feat/mean_func $subj_output_dir.feat/mask -f $F -g $G -c $X $Y $Z -n -m
		cp $subj_output_dir.feat/mask_mask.nii.gz $subj_output_dir.feat/mask.nii.gz
		rm $subj_output_dir.feat/mask_mask.nii.gz
		for image in filtered_func_data mean_func example_func ; do
			fslmaths $subj_output_dir.feat/$image -mas $subj_output_dir.feat/mask $subj_output_dir.feat/$image
		done
	fi
	
done #lists

fi #
#run reg to Av
if (( $run_RegToAv == 1 )); then
	echo "running RegToAv on subject $subj"
	scripts/PreprocessingAndModel/register_to_AvRef.sh $subj $engram
fi

#run create anatomical rois
if (( $run_anatomical_rois == 1 )); then
	echo "creating anatomical rois for subject $subj"
	scripts/PreprocessingAndModel/make_subj_rois.sh $subj
fi

# if (( $delete_prev_dir = 1 )); then
# 	echo "removing previous preproc dirs for subject $subj"
# 	rm -rf $sub_dir/$analysis_dir/preproc
# fi
# 

done #participants

