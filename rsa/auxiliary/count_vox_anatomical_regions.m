function count_vox_anatomical_regions(engram)

cwd=pwd;
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
%rmpath(genpath(fullfile(mydir,'Software/spm12')));
addpath(genpath(fullfile(mydir,'Software/CBI_tools')));
      
%THIS HAS ALL OF THEM: 
% subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%           '17VW','18RA','19AB','20SA','21MY','22JP','23SJ','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB'};

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
        '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','33ML','36AN','37IR'};

%subjects={'2ZD'};
subj_dir=fullfile(proj_dir,'SubData');
roi_dir='rois/epi';

%%analysis specific dirs:
smoothing='no_smooth'; 
region='hipp';
task='encoding';
preproc_type='noSliceTimingCorrection';
modeling='filtered100s_mtc_clean_mc_wmcsf_3sphere';

results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling);
reg_mat_dir=fullfile(results_dir,'regions_matfiles');
if ~exist(reg_mat_dir)
    mkdir(reg_mat_dir);
end
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


%this script also creates a table with the number of voxel per region per
%participant:
nVoxels=nan(numel(subjects),numel(reg_names));
for subj=1:numel(subjects)
            
    fprintf('grabbing rois for subj %s\n',subjects{subj});
    
    for roi=1:numel(reg_names)
        
        fileName=fullfile(subj_dir,subjects{subj},roi_dir,reg_names{roi});
        
        if ~exist([fileName '.nii'],'file')
            disp(['unzipping ' fileName])
            unix(['gunzip ' fileName '.nii.gz']);
        end
        
        %niftiread does work, I used this:
        [curr_reg,header,~]=niftiread([fileName '.nii']);
        
        % zip up nifti file - we took the data, so can zip again
        unix(['gzip -f ' fileName '.nii']);
        
        %store the number of voxels:
        nVoxels(subj,roi)=length(find(curr_reg));
    end
   
end

%% prepare the structures and headers:
nVoxels_names{1,1}='subjects';
nVoxels_names(2:(numel(subjects)+1),1)=subjects';
nVoxels_names(1,2:(numel(reg_names)+1))=reg_names;
nVoxels_names(2:end,2:end)=num2cell(nVoxels);
save(fullfile(results_dir,[region '_voxel_numbers.mat']),'nVoxels_names','nVoxels');