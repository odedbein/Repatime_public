function enc_get_subj_data_background_connectivity(engram,group)

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
    '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

%subjects={'2ZD'};%,'3RS','5BS'};
switch group
    case 0
        subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
                  '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
    case 1
        subjects={'3RS','5BS','6GC','7MS'}; %'2ZD',
    case 2
        subjects={'8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA'};
    case 3
        subjects={'13GT','14MR','16DB','17VW','18RA'};
    case 4
        subjects={'32CC'};%'19AB','21MY','22JP','24DL','30RK','28HM','31JC','26MM','33ML','34RB','36AN','37IR',
    case 5
        subjects={'25AL','28HM','30RK','31JC','26MM'};%'20SA',
    case 6
        subjects={'33ML','34RB','36AN','37IR','32CC'};
end
%subjects={'2ZD'};
%group dirs:
smoothing='no_smooth'; 
task='encoding';
curr_model='Univar_EachPositionModel';
preproc_type='noSliceTimingCorrection'; 
csfwm_type='_with_wmcsf_3sphere'; %
curr_model=[ curr_model csfwm_type '_' preproc_type];
subj_dir=fullfile(proj_dir,'SubData');
roi_dir='rois/epi';

results_dir=fullfile(proj_dir,'results',task,'background_connectivity',smoothing,curr_model);
reg_mat_dir=fullfile(results_dir,'regions_matfiles');
if ~exist(reg_mat_dir)
    mkdir(reg_mat_dir);
end


num_tp=77;
num_lists=6;
num_reps=5;


reg_names={...
    'fs_ca23_025',...%25
    'fs_rca23_025',...%26
    'fs_lca23_025',...%27
    'fs_dg_025',...%28
    'fs_rdg_025',...%29
    'fs_ldg_025',...%30
    };

%get the linear decrease regions:
reg_names=reg_names';
reg_names_for_data_struct=reg_names;

%% get the data per list per repetition per participant
%time points will be the columns, voxels are the rows
%third dim: lists
%forth dim: reps
subj_model=[curr_model csfwm_type];
data_dir=fullfile('analysis',task,preproc_type,smoothing,subj_model);

for subj=1:numel(subjects)
    
   % mkdir(fullfile(subj_dir,subjects{subj},'temp'));
    %get the rois
    reg_data={};
    all_reg={};
    for roi=1:numel(reg_names)
        
        fileName=fullfile(subj_dir,subjects{subj},roi_dir,reg_names{roi});
        
        %read the file:
        curr_reg=niftiread(fileName);
        
        %put them all in one structure, easier for later
        all_reg{roi}=find(curr_reg);
        %create the place holder for the data for this region:
        reg_data.(reg_names_for_data_struct{roi})=nan(length(find(curr_reg)),num_tp,num_lists,num_reps);
        %store the number of voxels:
        nVoxels(subj,roi)=length(find(curr_reg));
    end
    
    %get the data:
    for r=1:num_reps
        for l=1:num_lists
            fprintf('creating data structure for subj %s list %d rep %d \n',subjects{subj},l,r);
            subj_data_dir=fullfile(subj_dir,subjects{subj},data_dir,['encoding_list' num2str(l) '_rep' num2str(r) '.feat']);
            
            %for position, retrieve the residuals:
            fileName=fullfile(subj_data_dir,'stats','reg_AvRef','bp_filtered01hz035hz_res4d');
            
            %upload the map
            data=niftiread(fileName);
            
            %unix(['rm ' fileName '.nii']);
            %vectorize data so that we can get the timeseries in each voxel
            %in each roi
            data_vec=reshape(data,[size(data,1)*size(data,2)*size(data,3),size(data,4)]); %each TR is now a vector, the voxels are aligned like
            %the find function is aligning them - so it matches the all_reg{roi}=find(curr_reg); checked it, Oded, 4/23/19
            %get the relevant files for each region
            for reg=1:numel(reg_names)
                reg_data.(reg_names_for_data_struct{reg})(:,:,l,r)=data_vec(all_reg{reg},:);
            end
        end %all positions
    end %all reps
    
    save(fullfile(reg_mat_dir,['hipp_rois_' subjects{subj} '.mat']),'reg_data');
    %fileName2=fullfile(subj_dir,subjects{subj},'temp');
    %unix(['rm -rf ' fileName2]);
 
end

end

