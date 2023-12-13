function step4_create_regressors_files_encodingUnivariate()%could input subjects if wanted
%creates the regressor files for each model, for each subject
%input:     subjects: a structure array with subjects' names
%proj_dir='/Volumes/davachilab/Bein/Repatime/repatime_scanner';
proj_dir='/Volumes/data/Bein/Repatime/repatime_scanner';

%THIS HAS ALL OF THEM:
% subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%           '17VW','18RA','19AB','20SA','21MY','22JP','23SJ','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB'};

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
    '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

%subjects={'2ZD',} %'22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
behavior_dir='behavior'; %where the behavioral files are
subs_dir='SubData'; %subject's fmri data



%% creating a regular GLM event model, and regressors by position
onsets_dir='onsets/univariate'; %a folder to put the onsets

nLists=6;
nReps=5;
nEventsPerList=6;
trials_per_event=4;
trials_per_sess=trials_per_event*nEventsPerList;

run_this_part=0;
for subj=1:numel(subjects)
    fprintf('creating onsets for subject %s\n',subjects{subj});
    subj_dir=fullfile(proj_dir,subs_dir,subjects{subj}); %subject fmri data and analysis dir
    subj_behavior_dir=fullfile(proj_dir,behavior_dir,'data',subjects{subj},subjects{subj}); %subject fmri data and analysis dir
    
    
    %if run_this_part
    %% ENCODING SCANS %%
    im_duration=2;
    task_onsets_dir=fullfile(subj_dir,onsets_dir,'encoding');
    if ~exist(task_onsets_dir)
        mkdir (task_onsets_dir);
    end
    
    %the onsets for all of the lists for all repetitions should be the
    %same, so check that they are, but then have general onsets for all
    %runs.
    %load the relevant encoding file
    enc_filename=fullfile(subj_behavior_dir,'encoding.mat');
    load(enc_filename);
    
    check_enc_onstes=1;
    for list=1:nLists
        for rep=1:nReps
            curr_enc_file=fullfile(subj_behavior_dir,sprintf('encoding_%s_list%d_rep%d.mat',subjects{subj},list,rep));
            load(curr_enc_file);
            %display(sprintf('check list %d rep %d \n',list,rep));
            if any(abs(stim_onset - enc_onsets')>0.1)
                display(sprintf('wrong onsets in list %d rep %d \n',list,rep));
                check_enc_onsets=0;
            end
            
            %% during my meeting with Lila 10/19/18, we decided to not
            %exclude no repsonses. There aren't many of them, and as long as pariticpants
            % looked at the screen, should be fine. 
            
            %create the regressors for each position:
            %regressors for each event position will be included in the model:
            for pos=1:trials_per_event
                items=pos:trials_per_event:trials_per_sess;
                reg_file=sprintf('encoding_list%d_rep%d_pos%d.txt',list,rep,pos);
                fid = fopen(fullfile(task_onsets_dir,reg_file), 'w');
                for c=items
                    fprintf(fid,'%.1f\t%.1f\t%d\n',enc_onsets(c),im_duration,1);
                end
                fclose(fid);
            end %ends the 4 positions regressor
            
        end %ends all reps
    end %ends all lists
    
    %end %ends the run_this_part if
    
end%ends all subjs

end%ends the function
