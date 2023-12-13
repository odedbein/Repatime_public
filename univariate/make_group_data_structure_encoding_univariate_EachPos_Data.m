function [ResultsEncUnivarOnlyNum]=make_group_data_structure_encoding_univariate_EachPos_Data(engram)

warning('off','all')
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
%subjects I excluded:

%rows: voxels
%colums: position
%3rd dim: repetition

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL',...
    '10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA','19AB',...
    '20SA','21MY','22JP','24DL','25AL','26MM','28HM',...
    '30RK','31JC','32CC','33ML','34RB','36AN','37IR'};


%Analysis definitions:
smoothing='no_smooth';%
task='encoding';
curr_model='Univar_eachPositionModel'; 
preproc_type='noSliceTimingCorrection'; %
csfwm_type='_with_wmcsf_3sphere'; %''
add_to_model=''; %
curr_model=[ curr_model csfwm_type '_' preproc_type add_to_model];

analysis='all_reg_eachPosModelWithoutRT_data'; %
check_nan=1; %regions shouldn't have nans, but just to double check
results_dir=fullfile(proj_dir,'results',task,'univariate',smoothing,curr_model);

region='hipp';%
reg_mat_dir=fullfile(results_dir,'regions_matfiles_tstat');
mat_file_name=[ region '_data' ];
results_filename=fullfile(results_dir,[mat_file_name]); % 'FIR_model'

load(fullfile(reg_mat_dir,[ mat_file_name '_2ZD.mat' ]),'reg_data');
reg_names=fieldnames(reg_data);

ItemsPerEvent=4; %items per events
numReps=5;

%% prepare the structures and headers:
ResultsEncUnivarOnlyNum={};

for reg=1:numel(reg_names)
    ResultsEncUnivarOnlyNum.(reg_names{reg})=nan(numel(subjects),ItemsPerEvent,numReps);
    
end %ends the regions loop

%% actually analyze the data:
for subj=1:numel(subjects)
    fprintf('analyzing subj %s\n',subjects{subj});
    %%load the data:    
    load(fullfile(reg_mat_dir,[ mat_file_name '_' subjects{subj} '.mat']),'reg_data');
    
    for r=1:numReps
        
        for reg=1:numel(reg_names)
            data=squeeze(reg_data.(reg_names{reg})(:,:,r)); %get the data of the current region, in the current repetition
            
            %check the data for no nans:
            if check_nan
                if ~isempty(find(isnan(data)))
                    fprintf('subj %s reg %s rep %d has nans\n',subjects{subj},reg_names{reg},r)
                end
            end
            ResultsEncUnivarOnlyNum.(reg_names{reg})(subj,:,r)=nanmean(data);
        end %ends the regions loop
    end %ends the reps loop
end %ends the subject loop


%%an explanation about the .all structure:
%rows: participants.
%columns: event position
%3th dim:repetition

save(results_filename,'ResultsEncUnivarOnlyNum');
end

