function compile_vector_analysis_raw_data_noRep1Subtraction(ResultsEncSimOnlyNum,engram,file_init,model)
%this script works on the output of the script:
%rsa_encoding_anatomical_raw_data.m
% file_init: hipp_all/hipp_reg - I ran it twice.

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

%% parameters for analysis:


%criteria for exclusion:
Exclude_SD=3;
remove_outliers=1;

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
%subjects={'21MY','3RS','5BS'};
nSubj=numel(subjects);


%% analysis dirs:
smoothing='no_smooth'; 
task='encoding';

%choose the models and regions:
curr_model=[model '/voxel_removed']; 
results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,curr_model);

results_file_ext='.txt';
Rfiles_dir=fullfile(results_dir,'FilesForR_outlier_corr_removed/regions_data_noRep1Subtraction');
Rfiles_behavior_dir=fullfile(results_dir,'FilesForR_outlier_corr_removed/behavior_models');
if ~isfolder(Rfiles_dir)
    mkdir(Rfiles_dir)
end
if ~isfolder(Rfiles_behavior_dir)
    mkdir(Rfiles_behavior_dir)
end

%get the number and name of regions:
reg_names=fieldnames(ResultsEncSimOnlyNum.thirdTR);

regions=1:numel(reg_names);
%take only items for which participants responsed during encoding, or not:
measure={'norm_diff';'abs_norm_diff';'ndp'};

%the TRs you want to take - Kim et al did thirdTR:
TRs={'thirdTR'};

%% lists/reps/trials details:
numReps=5;
numLists=6;
numEvents=6;
items_per_event=4;
numTrials=numEvents*items_per_event;


%% take the entire simMat - only model for brain data
%prepare a nan mat to mark all the diagonal+low triangle of the mat:
tr=1;reg=reg_names{1};
%take one region just to have the size:
curr_data=ResultsEncSimOnlyNum.(TRs{tr}).(reg).byList.SimMat.ndp;
%participants are the first dim, make them the last dim, just for ease
curr_data=permute(curr_data,[2:5,1]);
%actually prep the mat:
nanmat=triu(ones(size(curr_data,1)),1);
nanmat(nanmat==0)=nan;
nanmat=repmat(nanmat,[1,1,size(curr_data,3),size(curr_data,4),size(curr_data,5)]);
for r=regions
    reg=reg_names{r};
    brain_data=[];
    for tr=1:numel(TRs)
        for oor=1:numel(measure)
            curr_m=measure{oor};
            %% all items, regardless of memory, the n+g diag:
            curr_data=ResultsEncSimOnlyNum.(TRs{tr}).(reg).byList.SimMat.(curr_m); %I took curr_data again, participants are first dim.
            
            %calculate the diff from rep1:
            %NOTE: I kept the variable name because I'm lazy, but here we
             %don't subtract the first rep
            data_diff1stRep=curr_data;
            if remove_outliers
                for subj=1:nSubj
                    %% exclude outlier per participant:
                    curr_data_temp=squeeze(data_diff1stRep(subj,:,:,2:5,:));
                    curr_data_temp=reshape(curr_data_temp,[numel(curr_data_temp),1]);
                    %it says t_std/av bc I copied, but it's r values
                    t_std=nanstd(curr_data_temp(isfinite(curr_data_temp)));
                    t_av=nanmean(curr_data_temp(isfinite(curr_data_temp)));
                    curr_data_temp=data_diff1stRep(subj,:,:,2:5,:);
                    curr_data_temp(curr_data_temp > t_av+(Exclude_SD*t_std))=nan;
                    curr_data_temp(curr_data_temp < t_av-(Exclude_SD*t_std))=nan;
                    data_diff1stRep(subj,:,:,2:5,:)=curr_data_temp;
                end
            end
                
            %participants are the first dim, make them the last dim, just
            %for ease (as we did above)
            data_diff1stRep_temp=permute(data_diff1stRep,[2:5,1]);
            %take out the simetric part of the matrix, and vectorize:
            vec_curr_data=data_diff1stRep_temp(~isnan(nanmat));
            
            brain_data=[brain_data vec_curr_data];
        end %ends the choose measures
        
    end %ends the TR loop
    %% set up the table and write up
    %all reps and lists in one vector:
    %set the table:
    T=array2table(brain_data);
    T.Properties.VariableNames=measure;
    %write it up:
    if strcmp(file_init,'hipp_all')
        switch r
            case 1
                reg='fs_hippFromSF_noHATA_all';
            case 2
                reg='fs_rhippFromSF_noHATA_all';
            case 3
                reg='fs_lhippFromSF_noHATA_all';
        end
    end
    results_fname=[file_init '_' reg '_vector_analysis_simMat' results_file_ext];
    filename=fullfile(Rfiles_dir,results_fname);
    writetable(T,filename,'Delimiter','\t');
end %ends the region loop

end