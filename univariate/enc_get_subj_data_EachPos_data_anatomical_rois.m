function enc_get_subj_data_EachPos_data_anatomical_rois(engram)
%this script takes roi from group level contrast and retrieve subject
%specific data from the position model
%warningvzzz('off','all')
cwd=pwd;
%[~, hostname]=system('hostname');
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
%rmpath(genpath(fullfile(mydir,'Software/spm12')));
addpath(genpath(fullfile(mydir,'Software/CBI_tools')));
%addpath(genpath(fullfile(mydir,'Software/General_scripts')));
%subjects I excluded:
%'15CD' - movement
%'27AC' - didn't finish the scan - only 4 scans
%'23SJ' - did very badly on day2
%'29DT' - low memory rates
%note that subj 3 and 16 also had low memory, but chance.

%THIS HAS ALL OF THEM:
% subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%           '17VW','18RA','19AB','20SA','21MY','22JP','23SJ','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB'};

%THIS IS JUST THE ONES IN THE STUDY N=30
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL',...
    '10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA','19AB',...
    '20SA','21MY','22JP','24DL','25AL','26MM','28HM',...
    '30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
%subjects={'2ZD'};
%some general dirs
roi_dir='rois/epi';

%%analysis specific stuff:
smoothing='no_smooth'; 
region='hipp'; 
task='encoding';
curr_model='Univar_eachPositionModel';
preproc_type='noSliceTimingCorrection'; %_WithSliceTimingCorrection
csfwm_type='_with_wmcsf_3sphere'; %''
curr_model=[ curr_model csfwm_type '_' preproc_type];
%gfeat_dir=fullfile(proj_dir,'results',task,'univariate',smoothing,[ curr_model '.gfeat' ]);


%subjects dir
subj_model=['Univar_eachPositionModel'  csfwm_type '.gfeat'];

%in this dir, cope1-4 is pos1-4. Then, in each copeX.feat folder, each rep
%is a cope in the stats folder, so cope1-5 will be rep1-5, and copes 6-8
%will be across repetition, for this specific position.

subj_dir=fullfile(proj_dir,'SubData');
data_dir=fullfile('analysis',task,preproc_type,smoothing,subj_model);
results_dir=fullfile(proj_dir,'results',task,'univariate',smoothing,curr_model);

reg_mat_dir=fullfile(results_dir,'regions_matfiles_tstat');
if ~exist(reg_mat_dir)
    mkdir(reg_mat_dir);
end

ItemsPerEvent=4;
numReps=5;

%% get the clusters
%trials will be the columns, voxels are the rows
%third dim: lists
%forth dim: reps

reg_names={...
           'fs_hippFromSF_noHATA',...
           'fs_rhippFromSF_noHATA',...
           'fs_lhippFromSF_noHATA',...
           'fs_hippFromSF_noHATA_ant',...
           'fs_rhippFromSF_noHATA_ant',...
           'fs_lhippFromSF_noHATA_ant',...
           'fs_hippFromSF_noHATA_mid',...
           'fs_rhippFromSF_noHATA_mid',...
           'fs_lhippFromSF_noHATA_mid',...
           'fs_hippFromSF_noHATA_post',...
           'fs_rhippFromSF_noHATA_post',...
           'fs_lhippFromSF_noHATA_post',...
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

for subj=1:numel(subjects)
    
    fprintf('creating data structure for subj %s\n',subjects{subj});
    subj_data_dir=fullfile(subj_dir,subjects{subj},data_dir);
    %prep the reg_data struct:
    reg_data={};
    all_reg={};
    for roi=1:numel(reg_names)
        
        fileName=fullfile(subj_dir,subjects{subj},roi_dir,reg_names{roi});
        
        if ~exist([fileName '.nii'],'file')
        %    disp(['unzipping ' fileName])
            unix(['gunzip ' fileName '.nii.gz']);
        end
        
        %a stupid hack because something in the files were not that good - I
        %read them with spm_vol
        %curr_reg=spm_read_vols(spm_vol(sprintf('%s.nii',fileName)));
        
        %niftiread does work, I used this:
        [curr_reg,header,~]=niftiread([fileName '.nii']);
        % zip up nifti file - we took the data, so can zip again
        unix(['gzip -f ' fileName '.nii']);
        
        %put them all in one structure, easier for later
        all_reg{roi}=find(curr_reg);
        %create the place holder for the data for this region:
        reg_data.(reg_names{roi})=nan(length(find(curr_reg)),ItemsPerEvent,numReps);
    end
    %get the data:
    for r=1:numReps
        for i=1:ItemsPerEvent
            %for position, retrieve the cope:
            fileName=fullfile(subj_data_dir,['cope' num2str(i) '.feat' ],'stats',[ 'tstat' num2str(r) ]);
            if ~exist([fileName '.nii'],'file')
                % disp(['unzipping ' fileName])
                unix(['gunzip ' fileName '.nii.gz']);
            end
            
            %upload the map
            [data,header,~]=niftiread([fileName '.nii']);
            % zip up nifti file - we took the data, so can zip again
            unix(['gzip -f ' fileName '.nii']);
            %get the relevant files for each region
            for reg=1:numel(reg_names)
                reg_data.(reg_names{reg})(:,i,r)=data(all_reg{reg});
            end
        end %all positions
    end %all reps
    %
    save(fullfile(reg_mat_dir,[region '_data_' subjects{subj} '.mat']),'reg_data');
    
end
