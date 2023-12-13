function compile_model_encodingRT_TempTestRT(engram)
%this script creates three files:
%1. all similairity metrix, vectorized
%2. the n+1 gap, all trials
%3. only the n+1 gap in memory trials (pos1-2,2-3,4-1)

if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');

%% parameters for analysis:
add_behav_fname='RTms';

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

%THIS HAS ALL OF THEM:
% subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%           '17VW','18RA','19AB','20SA','21MY','22JP','23SJ','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB'};

%THIS IS JUST THE ONES IN THE STUDY
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN',...
    '13GT','14MR','16DB','17VW','18RA','19AB','20SA','21MY','22JP','24DL',...
    '25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};
%%%%%IMPORTANT: make sure that this is the order in which the neural file
%%%%%was compiled!!!! %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%it is - I coppied it from there...
%%also make sure that the test is the same:
%subjects_names={'ZD','RS','BS','GC','MS','PL','IL','BL','CB','AN',...
%                'GT','MR','DB','VW','RA','AB','SA','MY','JP','DL',...
%                'AL','MM','HM','RK','JC','CC','ML','RB','AN','IR'};
%%subjects_numbers=[2,3,5:14 16:22 24:26 28 30:34 36 37];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subjects={'2ZD','3RS','5BS'};
nSubj=numel(subjects);


%% analysis dirs:
behav_dir=fullfile(proj_dir,'behavior','data');
smoothing='no_smooth';
task='encoding';

%choose the models:
curr_model='filtered100s_mtc_clean_mc_wmcsf_3sphere/voxel_removed'; 

results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,curr_model);


Rfiles_behavior_dir=fullfile(results_dir,'FilesForR_outlier_corr_removed/behavior_models'); %'FilesForR_outlier_corr_removed','FilesForR_outlier_corr_removed_subtract_csf_cormat'
if ~isfolder(Rfiles_behavior_dir)
    mkdir(Rfiles_behavior_dir)
end
% load the data

%% lists/reps/trials details:
numReps=5;
numLists=6;
numEvents=6;
items_per_event=4;
numTrials=numEvents*items_per_event;

%% set up data structures - for n+1 analysis, all items:

%% set up the relevant model:
%start constructing the data structure, that's identical for all:
%participants variable:
g=1;
curr_num_trials=numTrials-g;
participants=repmat((1:nSubj)',[curr_num_trials*numLists*numReps,1]);
%trial_num variabe:
trials=repmat(reshape(repmat((1:curr_num_trials),[nSubj,1]),[curr_num_trials*nSubj,1]),[numLists*numReps,1]);

%repetition variable:
reps=repmat(1:numReps,[curr_num_trials*nSubj,1]);
reps=repmat(reshape(reps,[numel(reps),1]),[numLists,1]);

%lists variable:
lists=repmat(1:numLists,[curr_num_trials*nSubj*numReps,1]);
lists=reshape(lists,[numel(lists),1]);

%position variable:
positions=[repmat((1:items_per_event),[nSubj,(numEvents-1)]) repmat(1:(items_per_event-g),[nSubj,1])];
positions=repmat(reshape(positions,[numel(positions),1]),[numLists*numReps,1]);

%within/across events:
across_event=zeros(size(positions));
across_event(positions==4)=1;

%put it all together:
model=[participants trials reps lists positions across_event];

%% encoding RTs:
if analyse_enc
%behavioral variables
behave_data.first.rawRT=nan(nSubj,curr_num_trials,numReps,numLists);
behave_data.first.diff_rep1=behave_data.first.rawRT;
behave_data.first.diff_rep1pos1=behave_data.first.rawRT;
behave_data.second=behave_data.first;
%to save the change/no change in response matrix
resp_change_mat=nan(numTrials,numTrials,numReps,numLists,nSubj);
resp1st_mat=resp_change_mat;
resp2nd_mat=resp_change_mat;
%every sample in the neural data is a correlation between two items (e.g., 1-2), so we'll have
%both - once for the 1st item, once for the 2nd
behav_varname={'first_rawRT','first_RT_difFromRep1_posXrep1_minus_posXrepX','first_RT_difFromPos1Rep1_posXRep1MinRepX_min_pos1Rep1MinRepX','first_response_pleasantness','first_response_change',...
    'second_rawRT','second_RT_difFromRep1_posXrep1_minus_posXrepX','second_RT_difFromPos1Rep1_posXRep1MinRepX_min_pos1Rep1MinRepX','second_response_pleasantness','second_response_change',...
    'second_RT_diffpos1prev4','second_RT_diffpos1prev4_repXrep1'};
nbehavior=numel(behav_varname);
%set up the header:
header={'subject','trials','repetition','list','pos_first_in_corr_pair','across_event'};
header=[header behav_varname];

%% actually analyse the data:
for subj=1:nSubj
    fprintf('analysing behavior for subj %s \n',subjects{subj});
    subj_behav_dir=fullfile(behav_dir,subjects{subj},subjects{subj}); %This is not a mistake: I saved the data within the subj folder in another folder in the subj's name
    enc_RT=nan(numTrials,numReps,numLists);
    pleasant_resp_temp=nan(numTrials,numReps,numLists);
    resp_change_temp=pleasant_resp_temp;
    resp_change_mat_temp=nan(numTrials,numTrials,numReps,numLists);
    resp1st_mat_temp=nan(numTrials,numTrials,numReps,numLists);
    resp2nd_mat_temp=nan(numTrials,numTrials,numReps,numLists);
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
            pleasant_resp_temp(:,r,l)=enc_behav_data.response_pleasentness;
            %same or diff from previous? for predicting RTs, I want to
            %have it for both first and second
            first_c=enc_behav_data.response_pleasentness(1:(numTrials-1));
            second_c=enc_behav_data.response_pleasentness(2:numTrials);
            change_seq=[nan(1,1);(first_c ~= second_c)];
            resp_change_temp(:,r,l)=change_seq;
            
            %prepare that for the matrix:
            %if there is a change in the response:
            A=enc_behav_data.response_pleasentness;
            A(isnan(RT))=nan;
            A=repmat(A,1,numTrials);
            match_mis=A+A';
            match_mis_again=(mod(match_mis,2)==1)+0; %this makes all the nans 0, which is not good, so nan them back. +0 is just to make it a number again
            match_mis_again(isnan(match_mis))=nan;
            resp_change_mat_temp(:,:,r,l)=match_mis_again;
            resp1st_mat_temp(:,:,r,l)=A;
            resp2nd_mat_temp(:,:,r,l)=A';
        end
    end
    
    if logRT
        enc_RT=log(enc_RT);
    end

    %nan wherever enc_RT is nan - innaccurate and too quick responses, we don't want to analyze these. 
    pleasant_resp_temp(isnan(enc_RT))=nan;
    resp_change_temp(isnan(enc_RT))=nan;
    pleasant_resp=nan(1,size(pleasant_resp_temp,1),size(pleasant_resp_temp,2),size(pleasant_resp_temp,3));
    pleasant_resp(1,:,:,:)=pleasant_resp_temp;
    resp_change=nan(size(pleasant_resp));
    resp_change(1,:,:,:)=resp_change_temp;
    
    %exclude the first item in each list in each repetition - this item
    %has high RTs always just because it's the first on the list:
    enc_RT(1,:,:)=nan;
    
    resp_change_mat(:,:,:,:,subj)=resp_change_mat_temp;
    resp1st_mat(:,:,:,:,subj)=resp1st_mat_temp;
    resp2nd_mat(:,:,:,:,subj)=resp2nd_mat_temp;
    %build the behavior data table for all regions:
    rawRT=nan(1,size(enc_RT,1),size(enc_RT,2),size(enc_RT,3));
    rawRT(1,:,:,:)=enc_RT;
    rep1=repmat(enc_RT(:,1,:),[1,numReps,1]);
    %diff from rep1:
    diff_rep1_temp=rep1-enc_RT; %so bigger difference means better learning
    %nan the first rep:
    diff_rep1_temp(:,1,:)=nan;
    diff_rep1=nan(1,size(enc_RT,1),size(enc_RT,2),size(enc_RT,3));
    diff_rep1(1,:,:,:)=diff_rep1_temp;
    diff_rep1pos1_temp=nan(size(diff_rep1_temp));
    for r=2:numReps
        for l=1:numLists
            %pull the pos1 RT diff from rep1
            curr_pos1=diff_rep1_temp(1:items_per_event:numTrials,r,l); %this is the improvement in pos1
            for pos=2:items_per_event
                %pull the current position diff from rep 1:
                curr_pos=diff_rep1_temp(pos:items_per_event:numTrials,r,l);
                %compute the diff:(posX(rep1-repX)-pos1(rep1-repX)) %how much they improved in posX, minus how much they improved in pos1 of that same event
                diff_rep1pos1_temp(pos:items_per_event:numTrials,r,l)=curr_pos-curr_pos1;
            end
        end
    end
    diff_rep1pos1=nan(1,size(enc_RT,1),size(enc_RT,2),size(enc_RT,3));
    diff_rep1pos1(1,:,:,:)=diff_rep1pos1_temp;
    
    %diff pos4-pos1 after:
    pos4=nan(size(enc_RT));
    pos=4;
    %prepare a matrix with pos4 RTs in their locations
    pos4(pos:items_per_event:numTrials,:,:)=enc_RT(pos:items_per_event:numTrials,:,:);
    %nan the last item - there's no pos1 to follow...
    pos4(numTrials,:,:)=nan;
    %prepare a matrix with the following pos1 items, and place them in
    %the pos4 locations, so that later we can subtract
    pos1=nan(size(enc_RT));
    pos1(pos:items_per_event:(numTrials-1),:,:)=enc_RT(5:items_per_event:numTrials,:,:);
    %subtract the 2 matrices, and place in a 4-dim matrix (to be later located in the structure with all subs:
    diff_pos1pos4=nan(size(diff_rep1pos1));
    diff_temp=pos1-pos4;
    diff_pos1pos4(1,:,:,:)=pos1-pos4;
    
    %diff pos4-pos1 after, diff from rep1:
    rep1=repmat(diff_temp(:,1,:),[1,5,1]);
    diff_pos1pos4_repXrep1=nan(size(diff_rep1pos1));
    diff_pos1pos4_repXrep1(1,:,:,:)=diff_temp-rep1; %so this is how much the difference changed relative to rep1 - bigger difference in 200ms will be 200
    %diff_rep1pos1=reshape(diff_rep1pos1,[num_trials*num_lists*num_reps,1]);
    %put it all in the all participants structure:
    %first item:
    curr_items=1:curr_num_trials;
    behave_data.first.rawRT(subj,:,:,:)=rawRT(1,curr_items,:,:);
    behave_data.first.diff_rep1(subj,:,:,:)=diff_rep1(1,curr_items,:,:);
    behave_data.first.diff_rep1pos1(subj,:,:,:)=diff_rep1pos1(1,curr_items,:,:);
    behave_data.first.response_pleasantness(subj,:,:,:)=pleasant_resp(1,curr_items,:,:);
    behave_data.first.response_change(subj,:,:,:)=resp_change(1,curr_items,:,:); %this will be whether there is a change in response from the previous trial - not in the current pair - good to predictthe RTs
    %I put the relevant RTs in the location of item 4, so that means
    %it's RTs correspoinding to the second item in the pair, hence
    %"second", but no need to change curr_items
    behave_data.second.diff_pos1pos4(subj,:,:,:)=diff_pos1pos4(1,curr_items,:,:);
    behave_data.second.diff_pos1pos4_repXrep1(subj,:,:,:)=diff_pos1pos4_repXrep1(1,curr_items,:,:);
    
    
    curr_items=2:numTrials;
    behave_data.second.rawRT(subj,:,:,:)=rawRT(1,curr_items,:,:);
    behave_data.second.diff_rep1(subj,:,:,:)=diff_rep1(1,curr_items,:,:);
    behave_data.second.diff_rep1pos1(subj,:,:,:)=diff_rep1pos1(1,curr_items,:,:);
    behave_data.second.response_pleasantness(subj,:,:,:)=pleasant_resp(1,curr_items,:,:);
    behave_data.second.response_change(subj,:,:,:)=resp_change(1,curr_items,:,:);%this will be whether there is a change in response btw the items in the pair in the similarity
end %loop through each subject

%% reshape all variables, create the table, and save into a file together with the models:
parts={'first','second'};
pp={'rawRT','diff_rep1','diff_rep1pos1','response_pleasantness','response_change'};
behave_data_table=[];
for p=1:numel(parts)
    for t=1:numel(pp)
        curr_bdata=behave_data.(parts{p}).(pp{t});
        behave_data_table=[behave_data_table reshape(curr_bdata,[numel(curr_bdata),1])];
    end
end
%pos1pos4 is only for second, since it's RTs in pos1 minus the pos4
%before that item
parts={'second'};
pp={'diff_pos1pos4','diff_pos1pos4_repXrep1'};
for p=1:numel(parts)
    for t=1:numel(pp)
        curr_bdata=behave_data.(parts{p}).(pp{t});
        behave_data_table=[behave_data_table reshape(curr_bdata,[numel(curr_bdata),1])];
    end
end


% set the bable:
T=[array2table(model) array2table(behave_data_table)];
T.Properties.VariableNames=header;
%write it up:
results_fname=['model_and_encoding_' add_behav_fname '.txt'];
filename=fullfile(Rfiles_behavior_dir,results_fname);
writetable(T,filename,'Delimiter','\t')
end %ends the analyse encoding if

%% temporal test RT
%restructure the behavioral data:
%The script that produces the sorted RT memory test is: 
%repatimeS_analyse_temporal_mem_test_sort_test
load('/Volumes/data/Bein/Repatime/repatime_scanner/results/encoding/sorted_RTmemoryTest_outliers_removed_quick100ms_N30.mat')
behav_varname={'rem','hc','forg','temporalTestRT','temporalTestOrderAllTrials','temporalTestOrderPerCondition'};
behave_data_table=[];
for t=1:numel(behav_varname)
    curr_bdata=sorted_RTmemoryTestOnlyNum.(behav_varname{t});
    %cut the 24th item:
    curr_bdata=curr_bdata(:,1:curr_num_trials,:);
    if (t==numel(behav_varname)) && logRT
        curr_bdata=log(curr_bdata);
    end
    behave_data_table=[behave_data_table reshape(curr_bdata,[numel(curr_bdata),1])];
end

%set up the header:
header={'subject','trials','list','pos_first_in_corr_pair','across_event'};
header=[header behav_varname];

%% set up the relevant model:
%start constructing the data structure, that's identical for all:
%participants variable:
participants=repmat((1:nSubj)',[curr_num_trials*numLists,1]);
%trial_num variabe:
trials=repmat(reshape(repmat((1:curr_num_trials),[nSubj,1]),[curr_num_trials*nSubj,1]),[numLists,1]);

%lists variable:
lists=repmat(1:numLists,[curr_num_trials*nSubj,1]);
lists=reshape(lists,[numel(lists),1]);

%position variable:
positions=[repmat((1:items_per_event),[nSubj,(numEvents-1)]) repmat(1:(items_per_event-g),[nSubj,1])];
positions=repmat(reshape(positions,[numel(positions),1]),[numLists,1]);

%within/across events:
across_event=zeros(size(positions));
across_event(positions==4)=1;

%put it all together:
model=[participants trials lists positions across_event];

%% set the table and write it up
T=[array2table(model) array2table(behave_data_table)];
T.Properties.VariableNames=header;
%write it up:
results_fname=['model_and_TemporalTest_quick100ms_' add_behav_fname '.txt'];
filename=fullfile(Rfiles_behavior_dir,results_fname);
writetable(T,filename,'Delimiter','\t')

if analyse_enc
%% take the entire simMat - only model for brain data

%prepare a nan mat to mark all the diagonal+low triangle of the mat:

%actually prep the mat:
nanmat=triu(ones(numTrials,numTrials),1);
nanmat(nanmat==0)=nan;
nanmat=repmat(nanmat,[1,1,numReps,numLists,nSubj]);

%% set up the model to correspond to the simMat:
%nanmat=triu(ones(numTrials),1);
%event model:
event_model=zeros(numTrials);
for en=1:numEvents
    event_model(((en-1)*items_per_event+(1:items_per_event)),((en-1)*items_per_event+(1:items_per_event)))=ones(items_per_event);
end

%all within-across, controlling for time on average:
%mark within as 2, across as 1, later on, use that regressor to select
%items, but as factor for the analysis
wa_control_time=zeros(numTrials);
for i=1:numTrials
    wa_control_time(i,i:(i+items_per_event-1))=1;
end
%cut the extra:
wa_control_time=wa_control_time(1:numTrials,1:numTrials);
wa_control_time=wa_control_time+event_model;

%linear drift (i.e., gap):
gap=zeros(numTrials);
for i=1:numTrials
    gap(i,(i+1):end)=(1:(numTrials)-i);
end

%color model
color_model=[ones(items_per_event) zeros(items_per_event);zeros(items_per_event) ones(items_per_event)];
color_model=repmat(color_model,[numEvents/2,numEvents/2]);

%event_position item1 (1-4)
event_pos_item1=repmat((1:items_per_event)',numEvents,numTrials);
%event_position item2 (1-4)
event_pos_item2=event_pos_item1';
%nan:
event_pos_item1(nanmat==0)=nan;
event_pos_item2(nanmat==0)=nan;

%positional code: i.e., same position vs. other positions:
same_other_pos=(event_pos_item1==event_pos_item2)+0; %add 0 just to make it a number

%trial_num item1
trial_num_item1=repmat((1:numTrials)',1,numTrials);
%trial_num item2
trial_num_item2=trial_num_item1';

%event number (event1-event6) - only within event
event_number_model=zeros(numTrials);
for en=1:numEvents
    event_number_model(((en-1)*items_per_event+(1:items_per_event)),((en-1)*items_per_event+(1:items_per_event)))=ones(items_per_event)*en;
end

%repetition
repetition=nan(numTrials,numTrials,numReps);
for r=1:numReps
    repetition(:,:,r)=r;
end

repetition=repmat(repetition,[1,1,1,numLists,nSubj]);

%lists
lists=nan(numTrials,numTrials,numReps,numLists,nSubj);
for l=1:numLists
    lists(:,:,:,l,:)=l;
end

%subjects
participants=nan(numTrials,numTrials,numReps,numLists,nSubj);
for s=1:nSubj
    participants(:,:,:,:,s)=s;
end



%% vectorize it all and write to a table
resp_change_mat=resp_change_mat(~isnan(nanmat)); %0: no change, 1: change
resp1st_mat=resp1st_mat(~isnan(nanmat)); %0: not pleasant, 1: pleasant
resp2nd_mat=resp2nd_mat(~isnan(nanmat)); %0: not pleasant, 1: pleasant

event_model=repmat(event_model,[1,1,numReps,numLists,nSubj]);
event_model=event_model(~isnan(nanmat));

wa_control_time=repmat(wa_control_time,[1,1,numReps,numLists,nSubj]);
wa_control_time=wa_control_time(~isnan(nanmat));

gap=repmat(gap,[1,1,numReps,numLists,nSubj]);
gap=gap(~isnan(nanmat));

color_model=repmat(color_model,[1,1,numReps,numLists,nSubj]);
color_model=color_model(~isnan(nanmat));

event_pos_item1=repmat(event_pos_item1,[1,1,numReps,numLists,nSubj]);
event_pos_item1=event_pos_item1(~isnan(nanmat));

event_pos_item2=repmat(event_pos_item2,[1,1,numReps,numLists,nSubj]);
event_pos_item2=event_pos_item2(~isnan(nanmat));

trial_num_item1=repmat(trial_num_item1,[1,1,numReps,numLists,nSubj]);
trial_num_item1=trial_num_item1(~isnan(nanmat));

trial_num_item2=repmat(trial_num_item2,[1,1,numReps,numLists,nSubj]);
trial_num_item2=trial_num_item2(~isnan(nanmat));

event_number_model=repmat(event_number_model,[1,1,numReps,numLists,nSubj]);
event_number_model=event_number_model(~isnan(nanmat));

repetition=repetition(~isnan(nanmat));
lists=lists(~isnan(nanmat));
participants=participants(~isnan(nanmat));

%put it all together:
model=[participants lists repetition event_model wa_control_time gap color_model ...
    event_pos_item1 event_pos_item2 trial_num_item1 trial_num_item2 event_number_model resp1st_mat resp2nd_mat resp_change_mat];
%% set up the table and write up
header={'subject','list','repetition','event_model','wa_control_time','gap','color_model', ...
    'event_pos_item1','event_pos_item2','trial_num_item1','trial_num_item2','event_number_model',...
    'resp1st','resp2nd','response_changed'};
%set the table:
T=array2table(model);
T.Properties.VariableNames=header;
%write it up:
results_fname='encoding_model_for_simMat.txt';
filename=fullfile(Rfiles_behavior_dir,results_fname);
writetable(T,filename,'Delimiter','\t');
end

end