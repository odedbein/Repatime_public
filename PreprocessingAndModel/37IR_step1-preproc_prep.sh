#! /bin/bash -u
# Author: Alexa Tompary, modified by Oded Bein
# This script preps all functional and anatomical scans for analysis,
# including:
#1. reorientation to std
#2. skull stripping the MPRAGE and T2 images
#3. running topup to correct fm distortions

# if [ $# -ne 1 ]; then
#   echo "
# usage: `basename $0` subj
# 
# This script preps all functional and anatomical scans for preprocessing:
# 	- reorient and skull-strip MPRAGE
# 	- reorient all functional scans
# "
#   exit
# fi

#subj=$@
subj=37IR

engram=$@ #[ 0 / 1 ] 1 means you ssh on engram
if (( $engram == 1 )); then
	source ./scripts/PreprocessingAndModel/globalsCengram.sh
else
	source ./scripts/PreprocessingAndModel/globalsC.sh #globalsC means globals for Columbia (vs. nyu)
fi
sub_dir=$subjects_dir/$subj
sub_cbi_dir=$subjects_dir/$subj/CBIdata #should exist - that's where I exctracted CBI data to
sub_data_dir=$subjects_dir/$subj/$data_dir

echo $sub_data_dir

use_t2=0
run_this_part=0
run_freesurfer=0
delete_prev_dir=1
run_on_seahorse=1

if (( $delete_prev_dir == 1 )); then
	echo "deleting old folders"
	#anatomy stuff:
	cp -r $sub_dir/${anatomy_dir} $sub_dir/${anatomy_dir}_old
	mkdir -p $sub_dir/${anatomy_dir}_temp
	cp $sub_dir/${anatomy_dir}/mprage* $sub_dir/${anatomy_dir}_temp/
	cp $sub_dir/${anatomy_dir}/T2* $sub_dir/${anatomy_dir}_temp/
	cp $sub_dir/${anatomy_dir}/Refimage_d1.nii.gz $sub_dir/${anatomy_dir}_temp/
	cp $sub_dir/${anatomy_dir}/Refimage_d2.nii.gz $sub_dir/${anatomy_dir}_temp/
	rm -r $sub_dir/$anatomy_dir
	mv $sub_dir/${anatomy_dir}_temp $sub_dir/${anatomy_dir}
	
	
	#fieldmap stuff:
	cp -r $sub_dir/${fm_dir} $sub_dir/${fm_dir}_old
	mkdir -p $sub_dir/${fm_dir}_temp
	cp $sub_dir/${fm_dir}/*1.nii* $sub_dir/${fm_dir}_temp/
	cp $sub_dir/${fm_dir}/*2.nii* $sub_dir/${fm_dir}_temp/
	rm $sub_dir/${fm_dir}_temp/*unwarped*
	rm -r $sub_dir/$fm_dir
	mv $sub_dir/${fm_dir}_temp $sub_dir/${fm_dir}
	
	#fieldmap corrected files:
	rm -r $sub_data_dir/*_fm*
	
	#analysis and rois dirs
	rm -rf $sub_dir/analysis
	rm -rf $sub_dir/$roi_dir
	rm -rf $sub_dir/design_dir
fi

#make needed directories for the analysis

#mkdir -p $sub_data_dir
#mkdir -p $sub_dir/$anatomy_dir
#mkdir -p $sub_dir/$fm_dir
#mkdir -p $sub_dir/$preproc_dir
mkdir -p $sub_dir/$sim_dir
mkdir -p $sub_dir/$enc_dir
mkdir -p $sub_dir/$order_dir
mkdir -p $sub_dir/$color_dir

if (( $run_this_part == 1 )); then

#### ANATOMY ####################################################

# MPRAGE: loop is hack to only run fsl commands if the file exists
#make sure that files were downloaded zipped from CBI

#takes all MPRAGES of day1
t1_scan=`ls $sub_cbi_dir/day1/*/*t1_mprage*.nii.gz*`

#choose the second file, that's the normalized mprage: change if needed - if want to use another mprage
#stupid hack:
t1_scan="${t1_scan#*.nii.gz}" #delete the shortest match from the front - that's the first file
t1_scan="${t1_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the second one, but it takes out the .nii extention as well - add it back
t1_scan_d1=${t1_scan}.nii.gz

#takes all MPRAGES of day2
t1_scan=`ls $sub_cbi_dir/day2/*/*t1_mprage*.nii.gz*`

#choose the second file, that's the normalized mprage: change if needed - if want to use another mprage
#stupid hack:
if [ -z "$t1_scan" ]; then
	echo "mprage d2 doesn't exist"
else
	t1_scan="${t1_scan#*.nii.gz}" #delete the shortest match from the front - that's the first file
	t1_scan="${t1_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the second one, but it takes out the .nii extention as well - add it back
	t1_scan_d2=${t1_scan}.nii.gz
fi

#07/23: Oded: I first did the analysis with averaging both mprages of day1 and 2. Then, I decided that since I have it for some
#participants, and not for others (that didn't want to do it, I gave them the option ad the end of the study), and also it blurs the images a bit,
#that I'll do use only day1. I still prepare day2 (reorient etc), but I just don't use it. 
#to look at the code that averages the images - see old_scripts folder

#take day1 - we'll use this one as our main mprage:
file_name=$sub_dir/$anatomy_dir/mprage
cp $t1_scan_d1 $file_name.nii.gz

#re-orient to std view and crop the neck
fslreorient2std $file_name $file_name
robustfov -i $file_name -r $file_name


#just to have - take day2 if exists:		
if [ ! -z "$t1_scan" ]; then	
	#echo "mprage d2 exists, averaging both days' mprages"
	echo "mprage d2 exists, reorienting"

	file_name=$sub_dir/$anatomy_dir/mprage_d2
	cp $t1_scan_d2 $file_name.nii.gz
	#re-orient to std view and crop the neck
	fslreorient2std $file_name $file_name
	robustfov -i $file_name -r $file_name		
fi

#run bet and fast on the mprage image, whether it's the day1 image or the average one.
echo "skull stripping MPRAGE"

#run bet
scripts/PreprocessingAndModel/run_bet.sh $sub_dir/$anatomy_dir mprage


#this script will also run free surfer on the mprage image, but it'll do so after the other steps,
#becasue it takes time, so while that runs I could start the preprocessing

## use that if you want to run bet directly, not via the script			
#bet $file_name ${file_name}_brain -f 0.3 -g -0.1 -B #that you can play with - the B function is good,
#but the f and g may be better with some tweaking for different participants


file_name=$sub_dir/$anatomy_dir/mprage

echo "running FAST on MPRAGE"
fast -t 1 -o $file_name ${file_name}_brain
rm -rf ${file_name}_pve* ${file_name}_mixeltype.nii.gz



# T2 image: loop is hack to only run fsl commands if the file exists

#takes all T2
t2_scan=`ls $sub_cbi_dir/*/*/*T2w_p*.nii.gz*`

#choose the second file, that's the normalized mprage: change if needed - if want to use another mprage
#stupid hack:
t2_scan="${t2_scan#*.nii.gz}" #delete the shortest match from the front - that's the first file
t2_scan="${t2_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the second one, but it takes out the .nii extention as well - add it back
t2_scan=${t2_scan}.nii.gz

#copy, run bet and fast
for t in $t2_scan; do
    echo "reorienting and skull stripping T2 image"
    #copy to folder
    file_name=$sub_dir/$anatomy_dir/T2image
    cp $t $file_name.nii.gz
    
    #re-orient to std view
    fslreorient2std $file_name $file_name
    robustfov -i $file_name -r $file_name
    if (( $use_t2 == 1 )); then
		#run bet
		scripts/PreprocessingAndModel/run_bet.sh $sub_dir/$anatomy_dir T2image

		echo "running FAST on T2 image"
		fast -t 2 -o $file_name ${file_name}_brain
		rm -rf ${file_name}_pve* ${file_name}_mixeltype.nii.gz
		
		#never actually run this because no need to register the t2
		echo "registering T2 to mprage"
		flirt \
		-in ${file_name}_brain \
		-ref $sub_dir/$anatomy_dir/mprage_brain \
		-out T2image2mprage \
		-omat T2image2mprage.mat \
		-cost corratio \
		-dof 6 \
		-searchrx -90 90 -searchry -90 90 -searchrz -90 90 \
		-interp trilinearno
		

    fi
done


################# FIELDMAP AND RUN TOPUP ######################
#On each day, the first fm will be used for the first block (until the order memory test, included).
#a second fm was collected before the 3rd block - that means that the 2nd and 3rd blocks are closer to this one.
#thus, they will be corrected using the second fm.
#the color test on day2 is corrected using the 2nd fm on day2 as well.

echo "creating fm distortion map pairs"
#day1 - AP - first
#takes all fm for day1
fm_scan=`ls $sub_cbi_dir/day1/*/*SE_FieldMap_AP*.nii.gz*`
fm_scan="${fm_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the first one, but it takes out the .nii extention as well - add it back
fm_scan=${fm_scan}.nii.gz
fslreorient2std $fm_scan $sub_dir/$fm_dir/day1_FieldMap_AP1

#day1 - PA - first
#takes all fm for day1
fm_scan=`ls $sub_cbi_dir/day1/*/*SE_FieldMap_PA*.nii.gz*`
fm_scan="${fm_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the first one, but it takes out the .nii extention as well - add it back
fm_scan=${fm_scan}.nii.gz
fslreorient2std $fm_scan $sub_dir/$fm_dir/day1_FieldMap_PA1

# Concatenate the pair of spin-echo scans
fm_pair=$sub_dir/$fm_dir/day1_fm_pair1.nii.gz
fslmerge -t $fm_pair $sub_dir/$fm_dir/day1_FieldMap_AP1 $sub_dir/$fm_dir/day1_FieldMap_PA1

#day1 - AP - second
#takes all fm for day1
fm_scan=`ls $sub_cbi_dir/day1/*/*SE_FieldMap_AP*.nii.gz*`
fm_scan="${fm_scan#*.nii.gz}" #delete the lonlgest match from the end - that's all the files but the first one
fslreorient2std $fm_scan $sub_dir/$fm_dir/day1_FieldMap_AP2

#day1 - PA - second
#takes all fm for day1
fm_scan=`ls $sub_cbi_dir/day1/*/*SE_FieldMap_PA*.nii.gz*`
fm_scan="${fm_scan#*.nii.gz}" #delete the lonlgest match from the end - that's all the files but the first one
fslreorient2std $fm_scan $sub_dir/$fm_dir/day1_FieldMap_PA2

# Concatenate the pair of spin-echo scans
fm_pair=$sub_dir/$fm_dir/day1_fm_pair2.nii.gz
fslmerge -t $fm_pair $sub_dir/$fm_dir/day1_FieldMap_AP2 $sub_dir/$fm_dir/day1_FieldMap_PA2

#day2 - AP - first
#takes all fm for day2
fm_scan=`ls $sub_cbi_dir/day2/*/*SE_FieldMap_AP*.nii.gz*`
fm_scan="${fm_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the first one, but it takes out the .nii extention as well - add it back
fm_scan=${fm_scan}.nii.gz
fslreorient2std $fm_scan $sub_dir/$fm_dir/day2_FieldMap_AP1

#day2 - PA - first
#takes all fm for day2
fm_scan=`ls $sub_cbi_dir/day2/*/*SE_FieldMap_PA*.nii.gz*`
fm_scan="${fm_scan%%.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the first one, but it takes out the .nii extention as well - add it back
fm_scan=${fm_scan}.nii.gz
fslreorient2std $fm_scan $sub_dir/$fm_dir/day2_FieldMap_PA1

# Concatenate the pair of spin-echo scans
fm_pair=$sub_dir/$fm_dir/day2_fm_pair1.nii.gz
fslmerge -t $fm_pair $sub_dir/$fm_dir/day2_FieldMap_AP1 $sub_dir/$fm_dir/day2_FieldMap_PA1

#day2 - AP - second
#takes all fm for day2
fm_scan=`ls $sub_cbi_dir/day2/*/*SE_FieldMap_AP*.nii.gz*`
fm_scan="${fm_scan#*.nii.gz}" #delete the match from the beginning - that's the first file
#but, sometimes I ran more AP in the begining, so see if need to remove more scans:
if (( ${#fm_scan} > 160 )); then
fm_scan="${fm_scan#*.nii.gz}"
fi
fslreorient2std $fm_scan $sub_dir/$fm_dir/day2_FieldMap_AP2


#day2 - PA - second
#takes all fm for day2
fm_scan=`ls $sub_cbi_dir/day2/*/*SE_FieldMap_PA*.nii.gz*`
fm_scan="${fm_scan#*.nii.gz*}" #delete the lonlgest match from the end - that's all the files but the first one
fslreorient2std $fm_scan $sub_dir/$fm_dir/day2_FieldMap_PA2



# Concatenate the pair of spin-echo scans
fm_pair=$sub_dir/$fm_dir/day2_fm_pair2.nii.gz
fslmerge -t $fm_pair $sub_dir/$fm_dir/day2_FieldMap_AP2 $sub_dir/$fm_dir/day2_FieldMap_PA2

fi #ends the run this part if - move if don't want to run all script

fm_params=$sub_dir/$fm_dir/fm_params.txt

if [ -e $fm_params ]; then
    rm $fm_params
fi

fm_frames=`fslval $sub_dir/$fm_dir/day1_FieldMap_AP1 dim4`

#prepare the parameters file and save it
for i in $(seq 1 $fm_frames); do
    echo "0 1 0 1" >> $fm_params
done
for i in $(seq 1 $fm_frames); do
    echo "0 -1 0 1" >> $fm_params
done

sleep 0.5
#run topup - day1 - first
echo "estimating b0 bias with topup - day1_pair1"
fm_pair=$sub_dir/$fm_dir/day1_fm_pair1.nii.gz

topup --imain=$fm_pair \
      --datain=$fm_params \
      --config=b02b0.cnf \
      --out=$sub_dir/$fm_dir/day1_topup1 \
      --iout=$sub_dir/$fm_dir/day1_fm_pair_unwarped1 
#      --verbose

sleep 0.5
#run topup - day1 - second
echo "estimating b0 bias with topup - day1_pair2"
fm_pair=$sub_dir/$fm_dir/day1_fm_pair2.nii.gz

topup --imain=$fm_pair \
      --datain=$fm_params \
      --config=b02b0.cnf \
      --out=$sub_dir/$fm_dir/day1_topup2 \
      --iout=$sub_dir/$fm_dir/day1_fm_pair_unwarped2 
#      --verbose

sleep 0.5	
#run topup - day2 - first
echo "estimating b0 bias with topup - day2_pair1"
fm_pair=$sub_dir/$fm_dir/day2_fm_pair1.nii.gz

topup --imain=$fm_pair \
      --datain=$fm_params \
      --config=b02b0.cnf \
      --out=$sub_dir/$fm_dir/day2_topup1 \
      --iout=$sub_dir/$fm_dir/day2_fm_pair_unwarped1
#      --verbose

#run topup - day2 - second
echo "estimating b0 bias with topup - day2_pair2"
fm_pair=$sub_dir/$fm_dir/day2_fm_pair2.nii.gz

topup --imain=$fm_pair \
      --datain=$fm_params \
      --config=b02b0.cnf \
      --out=$sub_dir/$fm_dir/day2_topup2 \
      --iout=$sub_dir/$fm_dir/day2_fm_pair_unwarped2
#      --verbose
      
#optional arg I removed from Michael's version:
# --rbmout --dfout
#they may not exist for my fsl version


#### Ref-scans, to create a template for each participant, to which I align the results ####################################################
#I chose to create an average template based on the ref image for the first run on each day
fm_params=$sub_dir/$fm_dir/fm_params.txt

#image day1:
echo "reorienting and fm correcting Ref scan day1"
# scan=`ls $sub_cbi_dir/*/*/*task-l1_similarity_pre_SBRef.nii*`
# fslreorient2std $scan $sub_dir/$anatomy_dir/Refimage_d1

#apply topup to correct for fm distorsions:
day=day1
sleep 0.5	
applytopup \
--imain=$sub_dir/$anatomy_dir/Refimage_d1 \
--inindex=1 \
--datain=$fm_params \
--topup=$sub_dir/$fm_dir/${day}_topup1 \
--out=$sub_dir/$anatomy_dir/Refimage_d1_fm \
--method=jac

#image day2:
echo "reorienting and fm correcting Ref scan day2"
# scan=`ls $sub_cbi_dir/*/*/*task-l4_similarity_pre_SBRef.nii*`
# fslreorient2std $scan $sub_dir/$anatomy_dir/Refimage_d2

#apply topup to correct for fm distorsions:
day=day2
sleep 0.5	
applytopup \
--imain=$sub_dir/$anatomy_dir/Refimage_d2 \
--inindex=1 \
--datain=$fm_params \
--topup=$sub_dir/$fm_dir/${day}_topup1 \
--out=$sub_dir/$anatomy_dir/Refimage_d2_fm \
--method=jac


#now average them:
file_name=$sub_dir/$anatomy_dir/AvRefimage_fm
AnatomicalAverage -o $file_name -w ${file_name}_tmp --noclean $sub_dir/$anatomy_dir/Refimage_d1_fm $sub_dir/$anatomy_dir/Refimage_d2_fm

#check if worked well:
answer_av="no"
if (( $run_on_seahorse == 0 )); then
	echo "Pulling up FSLVIEW; examine the average brains. When finished checking, close the FSLVIEW window"
	
	fslview $file_name -l Greyscale ${file_name}_tmp/ImToHalf0001 -l Red-Yellow ${file_name}_tmp/ImToHalf0002 -l Blue-Lightblue
	
	echo "did averaging the ref images worked? type yes or no"
	
	read answer_av

	#remove the temp directory
	if [ "$answer_av" == "no" ]; then
		echo "you didin't like the Refs averaging, consider what to do"
	else
		rm -r ${file_name}_tmp
	fi
else
	echo "running on seahorse, make sure to check the averaging of ref images"
fi

		
#### FUNCTIONAL RUNS ####################################################
fm_params=$sub_dir/$fm_dir/fm_params.txt #re-define here just in case you don't run all the script
# encoding
for list in {1..6}; do
	for rep in {1..5}; do
		echo "reorienting and fm correcting encoding list $list rep $rep"
		# scan=`ls $sub_cbi_dir/*/*/*task-l${list}_rep${rep}.nii*`
# 		fslreorient2std $scan $sub_data_dir/encoding_l${list}_rep${rep}
# 		
		#choose topup scan for applying topup:
		if (( $list == 1 )); then
			fm_scan=day1_topup1
		elif (( $list == 2 )) || (( $list == 3 )); then
			fm_scan=day1_topup2
		elif (( $list == 4 )); then
			fm_scan=day2_topup1
		elif (( $list == 5 )) || (( $list == 6 )); then
			fm_scan=day2_topup2
		fi
		
		sleep 0.5
		if (( $list == 5 )) && (( $rep == 1 )); then
		echo "fm list 5 rep 1 with the first fm"
			fm_scan=day2_topup1
		fi
		
		if (( $list == 5 )) && (( $rep == 2 )); then
		echo "fm list 5 rep 2 with the first fm"
			fm_scan=day2_topup1
		fi
		
		
		#apply topup to correct for fm distorsions:	
		applytopup \
		--imain=$sub_data_dir/encoding_l${list}_rep${rep} \
		--inindex=1 \
		--datain=$fm_params \
		--topup=$sub_dir/$fm_dir/$fm_scan \
		--out=$sub_data_dir/encoding_l${list}_rep${rep}_fm \
		--method=jac
	done
done

fm_params=$sub_dir/$fm_dir/fm_params.txt #re-define here just in case you don't run all the script
# similarity - pre and post
for list in {1..6}; do
echo "reorienting and fm correcting similarity pre and post list $list"
	
	#choose topup scan for applying topup:
	if (( $list == 1 )); then
		fm_scan=day1_topup1
	elif  (( $list == 2 )) || (( $list == 3 )); then
		fm_scan=day1_topup2
	elif (( $list == 4 )) || (( $list == 5 )); then
		fm_scan=day2_topup1
	elif (( $list == 6 )); then
		fm_scan=day2_topup2
	fi
	
	#similarity pre
#     scan=`ls $sub_cbi_dir/*/*/*task-l${list}_similarity_pre.nii*`
#     fslreorient2std $scan $sub_data_dir/similarity_pre_l${list}
     sleep 0.5
    #apply topup to correct for fm distorsions:
	applytopup \
	--imain=$sub_data_dir/similarity_pre_l${list} \
	--inindex=1 \
	--datain=$fm_params \
	--topup=$sub_dir/$fm_dir/$fm_scan \
	--out=$sub_data_dir/similarity_pre_l${list}_fm \
	--method=jac
	
	if  (( $list == 5 )); then
		fm_scan=day2_topup2
	fi
		
	#similarity post
    # scan=`ls $sub_cbi_dir/*/*/*task-l${list}_similarity_post.nii*`
#     fslreorient2std $scan $sub_data_dir/similarity_post_l${list}
    sleep 0.5
    #apply topup to correct for fm distorsions:
	applytopup \
	--imain=$sub_data_dir/similarity_post_l${list} \
	--inindex=1 \
	--datain=$fm_params \
	--topup=$sub_dir/$fm_dir/$fm_scan \
	--out=$sub_data_dir/similarity_post_l${list}_fm \
	--method=jac
	
done


fm_params=$sub_dir/$fm_dir/fm_params.txt #re-define here just in case you don't run all the script
# order memory test (match/mismatch)
for list in {1..6}; do
	echo "reorienting and fm correcting order test list $list"
	
	#choose topup scan for applying topup:
	if (( $list == 1 )); then
		fm_scan=day1_topup1
	elif (( $list == 2 )) || (( $list == 3 )); then
		fm_scan=day1_topup2
	elif (( $list == 4 )); then
		fm_scan=day2_topup1
	elif (( $list == 5 )) || (( $list == 6 )); then
		fm_scan=day2_topup2
	fi


	
	#order test
    # scan=`ls $sub_cbi_dir/*/*/*task-l${list}_match_mismatch.nii*`
#     fslreorient2std $scan $sub_data_dir/order_test_l${list}
    sleep 0.5
    #apply topup to correct for fm distorsions:
	applytopup \
	--imain=$sub_data_dir/order_test_l${list} \
	--inindex=1 \
	--datain=$fm_params \
	--topup=$sub_dir/$fm_dir/$fm_scan \
	--out=$sub_data_dir/order_test_l${list}_fm \
	--method=jac
	
done


fm_params=$sub_dir/$fm_dir/fm_params.txt #re-define here just in case you don't run all the script
# color memory test
for run in {1..4}; do
	echo "reorienting and fm correcting color test run $run"
	
	#color test was done on day2, so apply day2 topup:
    fm_scan=day2_topup2
	
	#color test
    # scan=`ls $sub_cbi_dir/*/*/*task-color_test_run${run}.nii*`
#     fslreorient2std $scan $sub_data_dir/color_test_run${run}
    sleep 0.5
    #apply topup to correct for fm distorsions:
	applytopup \
	--imain=$sub_data_dir/color_test_run${run} \
	--inindex=1 \
	--datain=$fm_params \
	--topup=$sub_dir/$fm_dir/$fm_scan \
	--out=$sub_data_dir/color_test_run${run}_fm \
	--method=jac
done

echo "done preparing subj $subj for preproc, continue to freesurfer, but you can run preprocessing"
rm -rf $sub_dir/${anatomy_dir}_old
rm -rf $sub_dir/${fm_dir}_old


#run freesurfer to segment cortical, 
if (( $run_freesurfer == 1 )); then
	echo "run freesurfer to segment cortical,subcortical and hipp subfields"
	scripts/PreprocessingAndModel/run_freesurfer.sh $subj
else
	echo "you chose not to run freesurfer"
fi