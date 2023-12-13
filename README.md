# Repatime_public

This includes the code for runing the experiment and the analyses reported in "Event integration and temporal differentiation: how hierarchical knowledge emerges in hippocampal subfields through learning" Bein & Davachi, accepted for publication at JNeuro

## Behavior folder

### Experiment_scripts:

repatimeS_ListGenerator.m was used to create the lists for each participant, with multiple checks.

repatime_wrapper.m runs the entire task in the scanner, wraps around all the experiment parts


### analysis

Includes files used for analysis of the encoding RT and the temporal memory test

repatimeS_analyse_temporal_mem_test_sort_test.m, compile_model_encodingRT_TempTestRT.m: prepared the data for analysis in R

Repatime_analyse_behavior.Rmd: main statistical analysis

## PreprocessingAndModel

Generally, analysis scripts were run in order by their number.
Files without a number are files that are being used by other scripts.
* matlab files are without numbers bc filenames cannot start with a number.

## univariate

01: enc_get_subj_data_EachPos_data_anatomical_rois.m - collects the data per participant in ROI from the t-stat nii files, saves in a matlab structure

02: make_group_data_structure_encoding_univariate_EachPos_Data.m - loads the data per participant from the matlab structure, and prepare a matlab structure for all participants.

03: compile_EachPos_across_reg_interaction.m - loads the group matlab structure and make an xlsx file for analyses in R

04: encoding_univar_stats.Rmd - group level stats and plotting.


## RSA

01: enc_get_data_anatomical_regions_filtered_data_clean_mc_wmcsf.m - collects the data per participant in ROI from the preprocessed nii files, saves in a matlab structure

02: rsa_encoding_anatomical_raw_data.m - calculates RSA - entire similarity matrix.

03: vector_like_analysis_encoding_anatomical_raw_data.m - calculate RSA - ndp and norm-diff measures, entire similarity matrix.

04: compile_model_encodingRT_TempTestRT.m - prepare the behavioral data and model for analysis in R. Correlation with memory test was done to answer a reviewer (correlation with DG similarity was tested)

05: compile... - prepare the neural data and model for analysis in R.

in Rscripts: files for statistical analyses in R, DG simulations, and simulations for additional rsa measures. 
 
#### auxiliary files
rsa_encoding_anatomical_calcNan.m: in the analysis, we removed time points (in voxels) that were 3SD of the mean in voxels.

This code counts voxels to know how many in each ROI, and counts the number of timepoints removed and the percentage.

count_vox_anatomical_regions.m: counts the number of voxels per ROI - could use this one as well. Gives the same result as the other code that also counts nans.

## Background connectivity:
01: enc_get_subj_data_background_connectivity.m: grabs the data from the nifti files

02: make_group_data_structure_encoding_background_connectivity.m: calculate the correlation and store for the group

03: encoding_background_connectivity_plot.m: statistics and plotting
