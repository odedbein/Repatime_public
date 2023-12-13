function [ResultsEncSim, ResultsEncSimOnlyNum]=rsa_encoding_anatomical_raw_data(engram)

warning('off','all')

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

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


%THIS HAS ALL IN THE STUDY:
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL',...
    '10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA','19AB',...
    '20SA','21MY','22JP','24DL','25AL','26MM','28HM',...
    '30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

%subjects={'21MY'};

%analysis specific stuff:
task='encoding';
smoothing='no_smooth';
modeling='filtered100s_mtc_clean_mc_wmcsf_3sphere';
remove_vox=1;

TRs={'thirdTR',};%Kim 2017 did thirdTR, fsl peak is the thirdTR.
results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling);
results_dir=fullfile(results_dir,'voxel_removed');

if ~exist(results_dir)
    mkdir(results_dir);
end

reg_mat_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling,'regions_matfiles');

%choose regions:
region='hipp_subreg'; %'hipp_all'
region_subj='hipp'; %for each sub, it's still all hipp regions together

%set the results filename
results_filename=fullfile(results_dir,[ region '_encoding_rsa_' modeling '.mat']);

if strcmp(region,'hipp_all')
    reg_names={...
        'fs_hippFromSF_noHATA',...%1
        'fs_rhippFromSF_noHATA',...%2
        'fs_lhippFromSF_noHATA',...%3
        'fs_hippFromSF_noHATA_ant',...%4
        'fs_rhippFromSF_noHATA_ant',...%5
        'fs_lhippFromSF_noHATA_ant',...%6
        'fs_hippFromSF_noHATA_mid',...%7
        'fs_rhippFromSF_noHATA_mid',...%8
        'fs_lhippFromSF_noHATA_mid',...%9
        'fs_hippFromSF_noHATA_post',...%10
        'fs_rhippFromSF_noHATA_post',...%11
        'fs_lhippFromSF_noHATA_post',...%12
        };
elseif strcmp(region,'hipp_subreg')
    reg_names={...
        
        'fs_ca1_025',...
        'fs_rca1_025',...
        'fs_lca1_025',...
        'fs_ca23_025',...
        'fs_rca23_025',...
        'fs_lca23_025',...
        'fs_dg_025',...
        'fs_rdg_025',...
        'fs_ldg_025',...
        };

end %ends the regions condition

num_TRs=77;
num_trials=24;
num_lists=6;
num_reps=5;
num_pos=4; %items per events

Exclude_SD=3;
%% prepare the structures and headers:
ResultsEncSim={};
ResultsEncSimOnlyNum={};
%% all t-series
for reg=1:numel(reg_names)
    ResultsEncSimOnlyNum.entireTseries.(reg_names{reg}).byList.SimMat.all_items=nan(numel(subjects),num_TRs,num_TRs,num_reps,num_lists);
end

%% by TRs
for tr=1:numel(TRs)
    for reg=1:numel(reg_names)
        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.all_items=nan(numel(subjects),num_trials,num_trials,num_reps,num_lists);
        
    end %ends the regions loop
end %ends the TR loop


%% actually analyze the data:
for subj=1:numel(subjects)
    fprintf('analyzing subj %s\n',subjects{subj});
    %load the data:
    load(fullfile(reg_mat_dir,[ region_subj '_data_' subjects{subj} '.mat']),'reg_data');
    
    for l=1:num_lists
        %% just make the similarity matrix of all TRs by all TRs
        for reg=1:numel(reg_names)
            
            %pull the data and remove outliers:
            curr_data_temp=reg_data.entireTseries.(reg_names{reg});
            curr_data_temp=reshape(curr_data_temp,[size(curr_data_temp,1)*size(curr_data_temp,2)*size(curr_data_temp,3)*size(curr_data_temp,4),1]);
           
            t_std=nanstd(curr_data_temp);
            t_av=nanmean(curr_data_temp);
            curr_data=reg_data.entireTseries.(reg_names{reg});
            curr_data(curr_data > t_av+(Exclude_SD*t_std))=nan;
            curr_data(curr_data < t_av-(Exclude_SD*t_std))=nan;
            
            for r=1:num_reps
                %take the data of the current rep
                data=squeeze(curr_data(:,:,l,r)); %get the data of the current region, in the current list and repetition
                if (size(data,1) <= 10) % ended up not using it, no need to...:&& (~strcmp(reg_names{reg},'csf_3sphere'))
                    fprintf('subj %s reg %s list %d part %d has 10 voxels or less, excluded \n',subjects{subj},reg_names{reg},l,r)
                else
                    corr=corrcoef(data,'rows','pairwise'); %If removing voxels, this will remove rows (voxels) that have nans, for each pair
                    %so a voxel that has nan in one trial is not omitted
                    %from the analysis completely, but just for the trial
                    %that had NaNs
                    ResultsEncSimOnlyNum.entireTseries.(reg_names{reg}).byList.SimMat.all_items(subj,:,:,r,l)=corr;
                end
            end
        end
        
        %% third TR
        for tr=1:numel(TRs)
            for reg=1:numel(reg_names)
                
                %pull the data and remove outliers:
                curr_data_temp=reg_data.(TRs{tr}).(reg_names{reg});
                curr_data_temp=reshape(curr_data_temp,[size(curr_data_temp,1)*size(curr_data_temp,2)*size(curr_data_temp,3)*size(curr_data_temp,4),1]);
                
                t_std=nanstd(curr_data_temp);
                t_av=nanmean(curr_data_temp);
                curr_data=reg_data.(TRs{tr}).(reg_names{reg});
                curr_data(curr_data > t_av+(Exclude_SD*t_std))=nan;
                curr_data(curr_data < t_av-(Exclude_SD*t_std))=nan;
                
                for r=1:num_reps
                    
                    %take the data of the current rep
                    data=squeeze(curr_data(:,:,l,r)); %get the data of the current region, in the current list and repetition
                    if (size(data,1) <= 10) 
                        fprintf('subj %s reg %s list %d part %d has 10 voxels or less, excluded \n',subjects{subj},reg_names{reg},l,r)
                    else
                        corr=corrcoef(data,'rows','pairwise'); %this will remove rows (voxels) that have nans, for each pair
                        %so a voxel that has nan in one trial is not omitted
                        %from the analysis completely, but just for the trial
                        %that had NaNs
                        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.all_items(subj,:,:,r,l)=corr;
                        
                    end %ends the size of region conditional
                end %ends the reps loop
            end %ends the regions loop
        end %ends the choose Trs loop
        
    end %ends the list loop
end %ends the subjects loop

save(results_filename,'ResultsEncSimOnlyNum','ResultsEncSim');
end

