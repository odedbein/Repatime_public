function av_nan=calc_av_nan_per_subj(engram)
%this script is a chunk of the compile_model_encodingRT_TempTest.m
%it only expclude outliers and calculate how many were excluded, for the
%paper.

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

%% parameters for analysis:
%run the analysis by logRT or not:
logRT=0;
if logRT
    add_behav_fname='logRT';
else
    add_behav_fname='RTms';
end

%anaylse behavior and model or not:
analyse_enc=0;

%for the RT - criteria for exclusion:
Exclude_SD=3;
too_quick_thresh=100;

%% participants:
%subjects I excluded:
%'15CD' - movement
%'27AC' - didn't finish the scan - only 4 scans
%'23SJ' - did very badly on day2
%'29DT' - low memory rates
%note that subj 3 and 16 also had low memory, but chance.


%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN',...
    '13GT','14MR','16DB','17VW','18RA','19AB','20SA','21MY','22JP','24DL',...
    '25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

nSubj=numel(subjects);


%% analysis dirs:
behav_dir=fullfile(proj_dir,'behavior','data');

%% lists/reps/trials details:
numReps=5;
numLists=6;
numEvents=6;
items_per_event=4;
numTrials=numEvents*items_per_event;

%% encoding RTs:
av_nan=nan(nSubj,1);

for subj=1:nSubj
    fprintf('analysing behavior for subj %s \n',subjects{subj});
    subj_behav_dir=fullfile(behav_dir,subjects{subj},subjects{subj}); %This is not a mistake: I saved the data within the subj folder in another folder in the subj's name
    enc_RT=nan(numTrials,numReps,numLists);
    for r=1:numReps
        for l=1:numLists
            %load the behavioral data, to know which items go to which condition:
            enc_behav_data=load(fullfile(subj_behav_dir,sprintf('encoding_%s_list%d_rep%d.mat',subjects{subj},l,r)));
            
            %do some behavioral analysis to get the items:
            RT=enc_behav_data.response_times*1000;
            %for the first couple of participants - had the bug where if
            %they didn't respond within 2 secs it got the trigger, cancel
            %these:
            RT(enc_behav_data.response==34)=nan;
            %find too quick responses - these are mistakes, remove them
            too_quick=(RT<too_quick_thresh); %this will also mark no responses - since they have 0 RT
            RT(too_quick)=nan;
            RT_std=nanstd(RT);
            RT_av=nanmean(RT);
            RT(RT>(RT_av+(Exclude_SD*RT_std)))=nan;
            RT(RT<(RT_av-(Exclude_SD*RT_std)))=nan;
            enc_RT(:,r,l)=RT;
        end
    end
    enc_RT=reshape(enc_RT,numel(enc_RT),1);
    all_nan=sum(isnan(enc_RT));
    av_nan(subj)=all_nan/numel(enc_RT);
end %loop through each subject

fprintf('mean nan is %.2f per participant \n',mean(av_nan)*100);

end