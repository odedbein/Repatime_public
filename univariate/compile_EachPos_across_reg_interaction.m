function compile_EachPos_across_reg_interaction(engram)

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




%THIS HAS ALL OF THEM:
% subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%           '17VW','18RA','19AB','20SA','21MY','22JP','23SJ','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB'};

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN',...
    '13GT','14MR','16DB','17VW','18RA','19AB','20SA','21MY','22JP','24DL',...
    '25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
subjects_numbers=[2,3,5:14 16:22 24:26 28 30:34 36 37]';
%%%%%IMPORTANT: make sure that this is the order in which the group
%%%%%structure was created. It's not so important, but it'll keep
%%%%%consistency with the number of participants.

nSubj=numel(subjects);


%group dirs:
behav_dir=fullfile(proj_dir,'behavior','data');
smoothing='no_smooth'; 
task='encoding';
curr_model='Univar_eachPositionModel';
preproc_type='noSliceTimingCorrection'; 
csfwm_type='_with_wmcsf_3sphere';
curr_model=[ curr_model csfwm_type '_' preproc_type];
results_dir=fullfile(proj_dir,'results',task,'univariate',smoothing,curr_model);
Rfiles_dir=fullfile(results_dir,'FilesForR');
if ~exist(Rfiles_dir)
    mkdir(Rfiles_dir);
end
%upload the group structure data:
load(fullfile(results_dir,'hipp_data.mat'));

%get the number of regions:
reg_names=fieldnames(ResultsEncUnivarOnlyNum);
choose_regs=[5,6,11,12]; %for JNeuro response to reviewers: rant,lant,rpost,lpost
nroi=numel(choose_regs);

contrasts_names={'activation_t'};
%number of brain variables:
nbrain=numel(contrasts_names);

%set up the header:
header={'subject','position','repetition','roi','hemi'};
header=[header contrasts_names];
T.Properties.VariableNames=header;

%% data in each trial, for multi-level models:
results_fname='ant_post_EachPos_interaction.xlsx';

num_reps=5;
num_pos=4; %items per events

%start constructing the data structure, per roi, we'll create it first, then multiply by number of regions:
%subjects_variable:
sub_nums=repmat(subjects_numbers,[num_pos*num_reps],1);

%position variable:
positions=repmat((1:num_pos),nSubj,1,num_reps);
positions=reshape(positions,numel(positions),1);
%repetition variable:
reps=repmat(1:num_reps,nSubj*num_pos,1);
reps=reshape(reps,numel(reps),1);

model=repmat([sub_nums positions reps],nroi,1);
data=[];
all_hemi=[];
all_rois=[];
%loop through rois:
for curr_roi=choose_regs
    d=ResultsEncUnivarOnlyNum.(reg_names{curr_roi});
    d=reshape(d,numel(d),1);
    data=[data;d];
    if (curr_roi == 5 || curr_roi == 11)%ant/post for JNeuro revision
        hemi=repmat({'right'},size(d,1),1);
    else
        hemi=repmat({'left'},size(d,1),1);
    end
    all_hemi=[all_hemi;hemi];
    roi_nm=repmat(reg_names(curr_roi),size(d,1),1);
    all_rois=[all_rois;roi_nm];
        
end

%write it up:
filename=fullfile(Rfiles_dir,results_fname);
%M=struct2table(header);
T=[array2table(model) cell2table(all_rois) cell2table(all_hemi) array2table(data)];
T.Properties.VariableNames=header;

writetable(T,filename)


end