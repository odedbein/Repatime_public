function ResultsEncSimOnlyNum=rsa_encoding_anatomical_calcNan(engram)


if engram==1
    mydir='/data/Bein';
    proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
elseif engram==2 %for JNeuro revision
    mydir='/Users/oded/princeton_gdrive/DAVACHI_LAB/';
    proj_dir=fullfile(mydir,'/Repatime/Rfiles_data_for_JNeuro');
else
    mydir='/Volumes/data/Bein';
    proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
end
%rmpath(genpath(fullfil[ResultsEncSim, ResultsEncItemsCount, ResultsEncSimOnlyNum,ResultsEncItemsCountOnlyNum]=rsa_encoding_anatomical_raw_data
%subjects I excluded:
%'15CD' - movement
%Charest Kriegeskorte
%'27AC' - didn't finish the scan - only 4 scans
%'23SJ' - did very badly on day2
%'29DT' - low memory rates


%%an explanation about the .all structure:
%rows: participants.
%columns: the different correlations per comparison - this will have a
%number for each correlation (e.g., position 1-2 in event #1). it'll have
%nan if there is no such comparison, e.g., the last event doesn't have the
%across comparison, or, in the "Responded" strucutre, it'll have nans
%where participants did not respond.
%3rd dim: the different comparisons, e.g., 1-2/2-3 etc.
%4th dim:repetition
%5th dim: lists


%THIS HAS ALL OF THEM:
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL',...
    '10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA','19AB',...
    '20SA','21MY','22JP','24DL','25AL','26MM','28HM',...
    '30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

%note that subj 3 and 16 also had low memory, but not chance.
%subjects={'21MY'};
%subj_dir=fullfile(proj_dir,'SubData');
%analysis specific stuff:
task='encoding';
%data_dir=fullfile('analysis',task);
smoothing='no_smooth';
modeling='filtered100s_mtc_clean_mc_wmcsf_3sphere';%'nofilter_mtc_wmcsf_3sphere_MC1_no_confound';%'AFNIfiltered100s_mtc';%'nofilter_mtc_only_wmcsf_3sphere_no_confound';
%'nofilter_mtc_clean_only_pass_through_preproc';%'nofilter__mtc_clean_mc_wmcsf_3sphere_no_prewhitening';%'filtered100s_mtc';%'nofilter__mtc_clean_mc_wmcsf_3sphere';%'filtered100s_mtc_clean_mc_wmcsf_3sphere_no_MC_filtering';%'filtered100s_mtc_clean_mc_wmcsf_3sphere_no_MC_filtering';%'AFNI_filtered100s_mtc_clean_mc_wmcsf_3sphere';%'filtered100s_mtc'; %'filtered100s_mtc'; %'filtered100s_mtc_clean_mc_wmcsf'; %'raw_data_mtc_matlab_unfiltered_drift_cor'; %'raw_data_unfiltered_mtc'; %'raw_data_clean_mc_wmcsf'; % 'raw_data';

TRs={'thirdTR'};%the different types of TRs I took for analysis. Kim 2017 did thirdTR, fsl peak is the thirdTR. I only looked at thirdTR
%results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling);
results_dir=fullfile(proj_dir,'results',task,'rsa');

if ~exist(results_dir)
    mkdir(results_dir);
end
%reg_mat_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling,'regions_matfiles');
reg_mat_dir=fullfile(proj_dir,'results',task,'rsa','regions_matfiles');

%choose regions:
region='hipp_subreg';
%taking all of the reigons was too big a file, so I divided; 'other_papers_cortex'; %'other_papers_cortex'
region_subj='hipp'; %for each sub, it's still all hipp regions together, or MTL and striatum together %'MTLstriatum' %'hipp' %
%set the results filename
results_filename=fullfile(results_dir,[ region '_encoding_nVox_nNans_' modeling '.mat']);

reg_names={...
           'fs_rca23_025',...%26
           'fs_lca23_025',...%27
           'fs_rdg_025',...%29
           'fs_ldg_025'...%30
            };

num_trials=24;
num_lists=6;
num_reps=5;
Exclude_SD=3;
%% prepare the structures and headers:
ResultsEncSimOnlyNum={};

for reg=1:numel(reg_names)
    ResultsEncSimOnlyNum.thirdTR.(reg_names{reg})=nan(numel(subjects),4);%rows: participants; cols:num voxels,num total voxels,num nans,percentage nans
end %ends the regions loop
%prep Items count matrix:

%% actually analyze the data:
for subj=1:numel(subjects)
    fprintf('analyzing subj %s\n',subjects{subj});
    %load the data:
    load(fullfile(reg_mat_dir,[ region_subj '_data_' subjects{subj} '.mat']),'reg_data');
    
    %% break by the different TRs
    for tr=1:numel(TRs)
        for reg=1:numel(reg_names)
            %% remove outlier voxels - we did it for the similarity matrix of all TRs by all TRs, so do it for the univar control as well
            % this removes outliers based on all data, all voxels in
            % roi, all reps, all lists - very conservative.
           
            %pull the data and remove outliers:
            curr_data_temp=reg_data.(TRs{tr}).(reg_names{reg});
            dims=size(curr_data_temp);
            ResultsEncSimOnlyNum.thirdTR.(reg_names{reg})(subj,1)=dims(1); %first dim is number of voxels in roi
            
            curr_data_temp=reshape(curr_data_temp,[size(curr_data_temp,1)*size(curr_data_temp,2)*size(curr_data_temp,3)*size(curr_data_temp,4),1]);
            ResultsEncSimOnlyNum.thirdTR.(reg_names{reg})(subj,2)=length(curr_data_temp);
            
            t_std=nanstd(curr_data_temp);
            t_av=nanmean(curr_data_temp); 

            curr_data_temp(curr_data_temp > t_av+(Exclude_SD*t_std))=nan;
            curr_data_temp(curr_data_temp < t_av-(Exclude_SD*t_std))=nan;
            sprintf('subj %s roi %s Nans: %d ',subjects{subj},reg_names{reg},sum(isnan(curr_data_temp)))
            ResultsEncSimOnlyNum.thirdTR.(reg_names{reg})(subj,3)=sum(isnan(curr_data_temp));
            ResultsEncSimOnlyNum.thirdTR.(reg_names{reg})(subj,4)=sum(isnan(curr_data_temp))/length(curr_data_temp);
        end %ends the regions loop
    end %ends the choose Trs loop
end %ends the subjects loop

save(results_filename,'ResultsEncSimOnlyNum');

%% then, just load the results and calculate mean and sd for the roi you want
% format short g
% mean(ResultsEncSimOnlyNum.thirdTR.fs_lca23_025)
end

