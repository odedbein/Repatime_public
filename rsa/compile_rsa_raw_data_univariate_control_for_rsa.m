function compile_rsa_raw_data_univariate_control_for_rsa(ResultsEncSimOnlyNum,engram)
%this script creates one file per region, which has:
%1. act_rep1item1 act_rep1item2 act_rep2item1 act_rep2item2 ...

%load('/Volumes/data/Bein/Repatime/repatime_scanner/results/encoding/rsa/no_smooth/filtered100s_mtc_clean_mc_wmcsf_3sphere/voxel_removed/hipp_subreg_encoding_univar_single_trials_filtered100s_mtc_clean_mc_wmcsf_3sphere.mat')
model='filtered100s_mtc_clean_mc_wmcsf_3sphere';
file_init='hipp';

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

%% parameters for analysis:

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN',...
    '13GT','14MR','16DB','17VW','18RA','19AB','20SA','21MY','22JP','24DL',...
    '25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
%%%%%IMPORTANT: make sure that this is the order in which the behavior file
%%%%%was compiled!!!! %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%here it is:
%%subjects_names={'ZD','RS','BS','GC','MS','PL','IL','BL','CB','AN',...
%%%%%%%           'GT','MR','DB','VW','RA','AB','SA','MY','JP','DL',...
%%%%%%%            'AL','MM','HM','RK','JC','CC','ML','RB','AN','IR'};
%%subjects_numbers=[2,3,5:14 16:22 24:26 28 30:34 36 37];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nSubj=numel(subjects);
%% analysis dirs:

smoothing='no_smooth';
task='encoding';

%choose the models and regions:
curr_model=[model '/voxel_removed']
results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,curr_model);

results_file_ext='.txt';
Rfiles_dir=fullfile(results_dir,'FilesForR_outlier_corr_removed/univar_control');
if ~isfolder(Rfiles_dir)
    mkdir(Rfiles_dir)
end

% load the data
reg_names=fieldnames(ResultsEncSimOnlyNum.thirdTR);

regions=1:numel(reg_names);


items='all_items';
%the TRs you want to take - Kim et al did thirdTR:
TRs={'thirdTR'};
header={'act_item1_repX_min_rep1','act_item2_repX_min_rep1','act_item1_repX','act_item2_repX'};
%% lists/reps/trials details:
numReps=5;
numLists=6;
numEvents=6;
items_per_event=4;
numTrials=numEvents*items_per_event;

%prep the nanmat, to cut the activation and make it like the similarity:
nanmat=triu(ones(numTrials,numTrials),1);
nanmat(nanmat==0)=nan;
nanmat=repmat(nanmat,[1,1,numReps,numLists,nSubj]);

%% take the entire simMat - only model for brain data
%I need to replicate the activation here to correspond to trial_num_item1/2
%in compile_model_encodingRT_TempTestRT.
for r=regions
    reg=reg_names{r};
    brain_data=[];
    tr=1:numel(TRs);
    curr_data=ResultsEncSimOnlyNum.(TRs{tr}).(reg).byList.SimMat.(items); %I took curr_data again, participants are first dim.
    %calculate the diff from rep1:
    first_rep=repmat(curr_data(:,:,1,:),[1,1,5,1]);
    data_diff1stRep=(curr_data-first_rep);
    %I decided not to remove outliers based univariate actiation,
    %because it's for the control. I want to look exactly at the
    %same trials I look for the main analysis.
    %Outliers in RSA will be removed from the analysis becasue they are nan.
    %If decide otherwise-check the compile_rsa_data file for a chunk of code to
    %exclude outliers.
    
    %participants are the first dim, make them the last dim, just
    %for ease (as we did for similarity)
    data_diff1stRep_temp=permute(data_diff1stRep,[2:4,1]);
    
    %SET UP ITEM 1:
    %multiply and reshape to have the univariate of item1 parallel to the
    %vectorized similarity (see trial_num_item1 in compile_model_encodingRT_TempTestRT):
    %I checked this by comparing, it works (08/14/2021):
    data_diff1stRep_temp1=reshape(repmat(data_diff1stRep_temp,[numTrials,1,1,1]),[numTrials,numTrials,numReps,numLists,nSubj]);
    %take out the simetric part of the matrix, and vectorize:
    vec_curr_data=data_diff1stRep_temp1(~isnan(nanmat));
    %add item1, all reps, all lists, all subjs, to brain_data:
    brain_data=[brain_data vec_curr_data];
    
    %SET UP ITEM 2:
    %multiply and reshape to have the univariate of item2 parallel to the
    %vectorized similarity (see trial_num_item1 in compile_model_encodingRT_TempTestRT):
    %I checked this by comparing, it works (08/14/2021):
    %data_diff1stRep_temp2=permute(repmat(data_diff1stRep_temp,[numTrials,1,1,1]),[2,1,3,4,5]); %transpose rows and cols
    data_diff1stRep_temp2=reshape(repmat(data_diff1stRep_temp,[numTrials,1,1,1]),[numTrials,numTrials,numReps,numLists,nSubj]);
    data_diff1stRep_temp2=permute(data_diff1stRep_temp2,[2,1,3,4,5]);%transpose rows and cols
    %take out the simetric part of the matrix, and vectorize:
    vec_curr_data=data_diff1stRep_temp2(~isnan(nanmat));
    %add item2, all reps, all lists, all subjs, to brain_data:
    brain_data=[brain_data vec_curr_data];
    
    %% same, but for the data w/o rep one subtraction:
    %participants are the first dim, make them the last dim, just
    %for ease (as we did for similarity)
    curr_data_temp=permute(curr_data,[2:4,1]);
    
    %SET UP ITEM 1:
    %multiply and reshape to have the univariate of item1 parallel to the
    %vectorized similarity (see trial_num_item1 in compile_model_encodingRT_TempTestRT):
    %I checked this by comparing, it works (08/14/2021):
    curr_data_temp1=reshape(repmat(curr_data_temp,[numTrials,1,1,1]),[numTrials,numTrials,numReps,numLists,nSubj]);
    %take out the simetric part of the matrix, and vectorize:
    vec_curr_data=curr_data_temp1(~isnan(nanmat));
    %add item1, all reps, all lists, all subjs, to brain_data:
    brain_data=[brain_data vec_curr_data];
    
    %SET UP ITEM 2:
    %multiply and reshape to have the univariate of item2 parallel to the
    %vectorized similarity (see trial_num_item1 in compile_model_encodingRT_TempTestRT):
    %I checked this by comparing, it works (08/14/2021):
    %data_diff1stRep_temp2=permute(repmat(data_diff1stRep_temp,[numTrials,1,1,1]),[2,1,3,4,5]); %transpose rows and cols
    curr_data_temp2=reshape(repmat(curr_data_temp,[numTrials,1,1,1]),[numTrials,numTrials,numReps,numLists,nSubj]);
    curr_data_temp2=permute(curr_data_temp2,[2,1,3,4,5]);%transpose rows and cols
    %take out the simetric part of the matrix, and vectorize:
    vec_curr_data=curr_data_temp2(~isnan(nanmat));
    %add item2, all reps, all lists, all subjs, to brain_data:
    brain_data=[brain_data vec_curr_data];
    
    %% set up the table and write up
    %all reps and lists in one vector:
    %set the table:
    T=array2table(brain_data);
    T.Properties.VariableNames=header;
  
    %write it up:
    results_fname=[file_init '_' reg '_simMat_control_for_univar' results_file_ext];
    filename=fullfile(Rfiles_dir,results_fname);
    writetable(T,filename,'Delimiter','\t');
end %ends the region loop

end