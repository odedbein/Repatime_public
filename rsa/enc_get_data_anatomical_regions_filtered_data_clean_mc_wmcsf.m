function enc_get_data_anatomical_regions_filtered_data_clean_mc_wmcsf(engram,sub_group)

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
if nargin == 1 %didn't select a group - run all subjects
    subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
        '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','33ML','36AN','37IR'};
else
    switch sub_group
    case 1
        subjects = {'2ZD','3RS','5BS','6GC','7MS','8PL'};
    case 2
        subjects = {'9IL','10BL','11CB','12AN','13GT','14MR'};
    case 3
        subjects = {'16DB','17VW','18RA','19AB','20SA','21MY'};
    case 4
        subjects = {'22JP','24DL','25AL','26MM','28HM','30RK'}; 
    case 5
        subjects = {'31JC','32CC','33ML','34RB','36AN','37IR'};
    end


end

%subjects={'2ZD'};
subj_dir=fullfile(proj_dir,'SubData');
roi_dir='rois/epi';

%%analysis specific dirs:
smoothing='no_smooth';
region='hipp';
task='encoding';
preproc_type='_noSliceTimingCorrection';%
modeling='filtered100s_mtc_only_wmcsf_3sphere';
data_dir=fullfile('analysis',task,preproc_type,smoothing,modeling);

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

%this loop grabs for each subject the t-map, and create a matrix file for
%each region, for all lists, all repetitions:
num_trials=24;
num_lists=6;
num_reps=5;
num_TRs=77;
%trials will be the columns, voxels are the rows
%third dim: lists
%forth dim: reps

%this script also creates a table with the number of voxel per region per
%participant:
nVoxels=zeros(numel(subjects),numel(reg_names));
for subj=1:numel(subjects)
            
    fprintf('creating data structure for subj %s\n',subjects{subj});
    subj_data_dir=fullfile(subj_dir,subjects{subj},data_dir)
     %get the rois
    reg_data={};
    all_reg={};
    for roi=1:numel(reg_names)
        
        fileName=fullfile(subj_dir,subjects{subj},roi_dir,reg_names{roi});
        
        if ~exist([fileName '.nii'],'file')
            disp(['unzipping ' fileName])
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
        reg_data.thirdTR.(reg_names{roi})=nan(length(find(curr_reg)),num_trials,num_lists,num_reps);
        reg_data.entireTseries.(reg_names{roi})=nan(length(find(curr_reg)),num_TRs,num_lists,num_reps);
        %store the number of voxels:
        nVoxels(subj,roi)=length(find(curr_reg));
    end
    
    for l=1:num_lists
        fprintf('extracting data structure for list %d subj %s\n',l,subjects{subj});
        for r=1:num_reps
            %get the scan:
            fileName=fullfile(subj_data_dir,sprintf('%s_list%d_rep%d.feat',task,l,r),'stats','res4d_AvRef');
            if ~exist([fileName '.nii'],'file')
                % disp(['unzipping ' fileName])
                unix(['gunzip ' fileName '.nii.gz']);
            end
            
            %upload the map
            %data=spm_read_vols(spm_vol(sprintf('%s.nii',fileName)));
            [data,header,~]=niftiread([fileName '.nii']);
            % zip up nifti file - we took the data, so can zip again
            unix(['gzip -f ' fileName '.nii']);
            
            %reshape to have voxels in rows,time points as columns, that
            %matches the find(curr_reg) function, I checked it :)
            data=reshape(data,size(data,1)*size(data,2)*size(data,3),size(data,4));
            
            for roi=1:numel(reg_names)
                %extract the time series of all voxels:
                tSeries=data(all_reg{roi},:);
                %zscore each voxel:
                tSeries=zscore(tSeries,1,2);%'1' is to flag population sample (denominator==n, rather than n-1), '2' is to go on the rows.
                
                %The 3TR from each item presentation - which is 4s
                %after, the peak acording to fsl hrf function (Kim et al.
                %2017 did it 4.5s). Just for fun, I also took the 4th, and
                %the 3-4 average.
                
                %the 3rd TR:
                reg_data.thirdTR.(reg_names{roi})(:,:,l,r)=tSeries(:,4:3:73); %at the end there was a bit more time to let the hrf drop, so don't go till the end, just get 24 items
                
                %entire tseries:
                reg_data.entireTseries.(reg_names{roi})(:,:,l,r)=tSeries; 
                
            end %all regs
        end %all reps
    end %all lists
    save(fullfile(reg_mat_dir,[region '_data_' subjects{subj} '.mat']),'reg_data');
   
end
