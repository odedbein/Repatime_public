function repatimeS_ListGenerator(subj_num,subj_id)
% repatime_encodingListGenerator creates the encodingLists matrix that
% details the IDs of randomized items from an image database that are used
% for memory encoding and testing in repatime. the matrix also indicates
% which items appear in different memory test conditions. the final matrix
% follows the organization:
% column 1: subject number
% column 2: day number
% column 3: List number
% column 4: trial number
% column 5: event number
% column 6: within-event position
% column 7: item ID (/720)
% column 8: event colour
% column 9: repeat in similarity


%% initial definitions
rand('state',sum(100.*clock));%solve the randperm problem in matlab from being consistent
[~, hostname]=system('hostname');

project_dir='.';

scripts_dir='scripts';
scritps_dir=fullfile(project_dir,scripts_dir);
subj_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id));
if ~exist(subj_dir), mkdir(subj_dir); end
stim_dir='images';
stim_dir=fullfile(project_dir,stim_dir);

%% define variables for counterbalancing
nLists = 6;
nEvents = 6;
nTrialsPerEvent = 4;
nTrialsPerList=nEvents*nTrialsPerEvent;
nTrials = nTrialsPerList*nLists;
MaxGapRepeatSim=14; %there are 24*2 trials per list, and 5 repeats - so on average would be 48/5. But do a bit more to give flexibility

%create the subj list
encodingLists = ones(nTrials,1)*subj_num;

%create the day list
encodingLists(:,2)= [ones(nTrials/2,1);ones(nTrials/2,1)*2];

%create the List lists:
encodingLists(:,3)=reshape(repmat(1:nLists,nTrialsPerList,1),nTrials,1);
%create the item number list:
encodingLists(:,4)=repmat([1:nTrialsPerList]',nLists,1);
%% generate event numbers for each List
events = [];
for iEvent = 1:nEvents
    events = [events; ones(nTrialsPerEvent,1)*iEvent];
end
encodingLists(:,5) = repmat(events,nLists,1);

%% generate n-item lists for events
encodingLists(:,6)=repmat((1:nTrialsPerEvent)',nLists*nEvents,1);

%generate a randomly chosen stim list for all subjects (same set) from the
%entire stim bank

% randomly select all stim for encoding and lures from the item list
%allStim = randperm(nTrials)';
encodingStim = randperm(nTrials)';
%lureStim = allStim(nTrials+1:end);%take the rest for lures during retrieval - they are randomized already

% place the item number list into the encoding list matrix
encodingLists(:,7)=encodingStim;


%% generate the colors
%1-6 - 6 different colors  %1-red 2-green 3-blue 4-yellow 5-magenta 6-orange
%colors will repeat 
rand_colors=[1 3 5];
%randomize the color pairs:
rand_colors=rand_colors(randperm(3));
check=1;
while check
    check=0;
    rand_lists_day2=randperm(3)+3;
    if rand_lists_day2(1)==4; %aviod having the same so that participants will not think it's the same then have a violation, also prevent it fom being exactly the same order
        check=1;
    end
end
%randomize which one of the color-pairs will come first:
rand_pairs=[];
for i=1:length(rand_colors)
    rand_pairs=[rand_pairs round(rand())];
end

%set the colors by the first randomization, then randomize the order for
%day 2:
colors=zeros(nTrials,1);
for l=1:nLists/2
    if ~rand_pairs(l)
        colors_temp=repmat([ones(nTrialsPerEvent,1)*rand_colors(l);ones(nTrialsPerEvent,1)*(rand_colors(l)+1)],nEvents,1);
    else
        colors_temp=repmat([ones(nTrialsPerEvent,1)*(rand_colors(l)+1);ones(nTrialsPerEvent,1)*rand_colors(l)],nEvents,1);
    end
    colors(((l-1)*nTrialsPerList)+(1:nTrialsPerList))=colors_temp(1:nTrialsPerList);%that's the first day
    colors(((rand_lists_day2(l)-1)*nTrialsPerList)+(1:nTrialsPerList))=colors_temp(nTrialsPerList+1:end);%that's the dsecond day, by the randomization
end

encodingLists(:,8) = colors;

%% prepare the match/mismatch lists:
%We did a version in which the distractor was from a different event of the same color (see OLD_EventMismatch script),
%participants were at ceiling. Here, we take as the mismatch the next item
%that appeared in the sequence:
%target pos1 - lure pos2
%target pos2 - lure pos3
%target pos3 - lure pos4

cues=[];
for e=1:nEvents 
    cues=[cues;(e-1)*nTrialsPerEvent+[1;2;4]];
end
cues(end)=[];
dist=[cues cues+1 cues+2];
MatchMisLists=[];
nTrialsMatchMis=nTrialsPerList-nEvents-1;
MatchMisCueDist=zeros(nTrialsMatchMis,3,nLists);
MatchMisDistLoc=zeros(nTrialsMatchMis,2,nLists);
for l=1:nLists
    attempts=1;
    fprintf(sprintf('attempt match/mismatch list %d\n',l));
    %set up the randomization
    temp_dist=dist;
    
    %now set the order of the trials:
    check=1;
    while check
        check=0;
        %check that two items do not appear in two consequitve trials (or
        %with one trial gap).
        attempts=attempts+1;
        temp_dist=temp_dist(randperm(length(temp_dist)),:);
        for r=2:size(temp_dist,1)
            if any(ismember(temp_dist(r,:),temp_dist(r-1,:)))
                check=1;
                break;
            end
            if r>2 && check==0 %need to check the 2-back
                if any(ismember(temp_dist(r,:),temp_dist(r-2,:)))
                    check=1;
                    break;
                end
            end
        end
        
        %check that there are no 2 subsequent trials of the same event:
        if ~check
            curr_enc=encodingLists(encodingLists(:,3)==l,:);
            rand_trials=curr_enc(temp_dist(:,1),:);
            events_check=rand_trials(:,5);
            for ec=1:length(events_check)
                if ec<length(events_check) && events_check(ec)==events_check(ec+1) %this is not the lasy item check the following one, current event is identical to the next event
                    check=1;
                    break
                end
                
                if ec<length(events_check) && rand_trials(ec,6)==nTrialsPerEvent && (events_check(ec)+1)==events_check(ec+1) %this is not the lasy item check the following one:
                    %this is an item in the last pos, so the match/mismatch will be of the next event, so check that the next trial is not of the next event
                    check=1;
                    break
                end
                
                if ec>1 && rand_trials(ec,6)==nTrialsPerEvent && (events_check(ec)+1)==events_check(ec-1) %this is not the first item,
                    %an item in the last pos, so the match/mismatch will be of the next event, so check that the previous trial is not of the next event (or it'll be something from the next event, then the 6 and the 1 of the next event).
                    check=1;
                    break
                end
                
            end
        end
    end
    
    if mod(attempts,500000)==0
        fprintf(sprintf('attempt match/mismatch %d\n',attempts));
    end
    if attempts > 4000000
        check=0;
        fprintf('didn''t find a good sequence for match/mismatch, run script again\n');
    end
    
    if ~check %found a good sequence - yay!
        MatchMisCueDist(:,:,l)=temp_dist;
        
        %set the location:
        check=1;
        while check
            check=0;
            %randomize the location, within each condition:
            %within, boundary:
            temp_loc=zeros(nTrialsMatchMis,1);
            items_loc=ismember(temp_dist(:,1),(1:nTrialsPerEvent:nTrialsPerList));
            leftRight=[1,1,1,2,2,2];
            leftRight=leftRight(randperm(length(leftRight)));
            temp_loc(items_loc,1)=leftRight;
            %within,nb:
            items_loc=ismember(temp_dist(:,1),(2:nTrialsPerEvent:nTrialsPerList));
            leftRight=[1,1,1,2,2,2];
            leftRight=leftRight(randperm(length(leftRight)));
            temp_loc(items_loc)=leftRight;
            %across - only 5 trials:
            items_loc=ismember(temp_dist(:,1),(4:nTrialsPerEvent:nTrialsPerList-1));
            leftRight=[1,1,2,2,(round(rand())+1)];%fifth will be a random number
            leftRight=leftRight(randperm(length(leftRight)));
            temp_loc(items_loc)=leftRight;
            
            %have no more than 3 right/left responses
            for i=4:nTrialsMatchMis
                curr_items=temp_loc(i-3:i);
                if all(curr_items==2) || all(curr_items==1)
                    check=1;
                    break
                end
            end
            
            %put the response:
            if ~check
                MatchMisDistLoc(:,1,l)=temp_loc;
                MatchMisDistLoc(temp_loc==1,2,l)=2;
                MatchMisDistLoc(temp_loc==2,2,l)=1;
            end
        end %ends the location loop
        
        if ~check
            %place the items:
            curr_enc=encodingLists(encodingLists(:,3)==l,:);
            curr_MatchMis=curr_enc(temp_dist(:,1),:);
            curr_MatchMis=[curr_MatchMis curr_enc(temp_dist(:,2),7) curr_enc(temp_dist(:,3),7)];
            MatchMisLists=[MatchMisLists;curr_MatchMis];
        end
    end
    
end
               
%% set up the onsets:

attempts=0;
%deifnitions for the match/mismatch scan
run_delay = 2;
run_decay = 13; %needs to be 13 to have a full TR.
tr=2;
stim_dur=3;
cue_probe_gap=5;
% stick function convolved with FSL's double gamma HRF
%from Alexa - fit a 2s TR
hrf =[0.0036 0.0960 0.1469 0.1163 0.0679 0.0329 0.0137 0.0047 0.0008 -0.0007 -0.0013 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017];
num_bt=1000;
j=[6 2 4 4 6 2 4 4 6 4 4 6 2 4 4 6]+3; 
min_corr=0.3;
matchmis_onsets=[];    

for l=1:nLists
    curr_list=MatchMisLists(MatchMisLists(:,3)==l,:);
    jitter_check=1;
    while jitter_check
        attempts=attempts+1;
        jitter_check=0;
        %display('checking match/mismatch jitter');
        %jitter_temp=[j(randperm((length(j)-1)/2)) j(randperm((length(j)-1)/2+1)+((length(j)-1)/2))];
        jitter_temp=[j(randperm(length(j))) 5]; %the last one is a place holder - discarded later anyway. it's just to make the script easier
        jitter(1:2:nTrialsMatchMis*2)=cue_probe_gap;
        jitter(2:2:nTrialsMatchMis*2)=jitter_temp;
        trial_lengths=stim_dur + jitter;
        matchmis_onsets_temp=run_delay + cumsum(trial_lengths) - (trial_lengths);
        run_length=matchmis_onsets_temp(end)+stim_dur+run_decay;
        run_length_tp=run_length/tr;
        trial_onsets_tp=matchmis_onsets_temp./tr;
        %create a regressor for each cue type:boundary,nb,across, and one
        %for all probes
        design=zeros(run_length_tp,4);
        %within boundary trials
        exp_trials=find(curr_list(:,6)==1)*2-1;
        design(trial_onsets_tp(exp_trials),1)=1;
        %within non-boundary trials
        exp_trials=find(curr_list(:,6)==2)*2-1;
        design(trial_onsets_tp(exp_trials),2)=1;
        %across trials
        exp_trials=find(curr_list(:,6)==4)*2-1;
        design(trial_onsets_tp(exp_trials),3)=1;
        %all response trials
        design(trial_onsets_tp(2:2:end),4)=1;
        design_conv=[];
        for col=1:nTrialsPerEvent
            design_conv(:,col)=conv(design(:,col),hrf);
        end
        design_conv=design_conv(1:run_length_tp,:);
        design_corr=abs(corr(design_conv));
        design_corr(design_corr==1)=0;
        if any(any(design_corr>min_corr))
            jitter_check=1;
        end
        
        if attempts> 10000000
            display('didn''t find a good mm jitter sequence - re-run the script');
            break
        end
    end
    
    if ~jitter_check
      matchmis_onsets=[matchmis_onsets;matchmis_onsets_temp];
    end    
    
end

save([subj_dir '/matchmis.mat'],'MatchMisLists','matchmis_onsets','MatchMisDistLoc');

%% generate the prepost similarity list:
%set up the repeating trials in each list: these will be the last item that
%I don't test for at the match/mismatch, and 4 more items that I'm choosing
%randomly, one from each event


%of the 5 possible events (total of 6), in each list, one will not have a
%repeating item, make sure it's a different one in every list. we have 6
%lists, so one event will that doesn't have a repeating item repeat twice - make sure it's across both days.
%than, in each event from which a repeated item is taken (4 events) -
%randomly take an item of each 4 locations.
%in total, there would be 5 repeating items
sim_rep=zeros(nTrials,1);
attempts=0;
check=1;
while check
    check=0;
    attempts=attempts+1;
    add1=randperm(nEvents-1);
    rand_lists=[randperm(nEvents-1)';add1(1)];
    rand_lists=reshape(rand_lists,[nLists/2,2]);
    if ~any(ismember(rand_lists(:,1),rand_lists(:,2))) %the repeating event is not spread between days
        check=1;
    end
    %now, in each list, choose randomly 4 locations in the 4 events that
    %are left:
    if ~check
        for l=1:nLists
            rand_list_temp=zeros(nTrialsPerList,1);
            loc_rep=randperm(4);
            rep_events=1:5;
            rep_events(rand_lists(l))=[];
            for ee=1:length(rep_events)
                ev=rep_events(ee);
                rand_list_temp((ev-1)*nTrialsPerEvent+loc_rep(ee))=1;
            end
            sim_rep(((l-1)*nTrialsPerList+1):(l*nTrialsPerList))=rand_list_temp;
        end
    end
end

sim_rep(nTrialsPerList:nTrialsPerList:nTrials)=1;

encodingLists(:,9) = sim_rep;


%% similarity scans - sequence and jitter
%things that I control
%1) minimun of 3 items btw same event trials
%2) minimum of 3 items btw following event trials - my main comparison
% for all other comparisons - I have tons of items, so can exclude for each
% item the few that are close in time, if that's an issue.
attempts=0;
similarityList=[];
last_enc_col=size(encodingLists,2);
%deifnitions for the similarity scan - here for jitter
run_delay = 2;
run_decay = 13;
tr=2;
stim_dur=1;
% stick function convolved with FSL's double gamma HRF
%from Alexa - fit a 2s TR
hrf =[0.0036 0.0960 0.1469 0.1163 0.0679 0.0329 0.0137 0.0047 0.0008 -0.0007 -0.0013 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017];
j=[1 1 1 3 3 3 3 5 5 5]';
min_corr=0.38;%set on 0.38, pretty high, bc I am going to do the Mumford model anyway - just to make sure it's not crazy
sim_onsets=[];
jitter_check=1;
for l=1:nLists
    display(sprintf('finding sim sequence for list %d',l))
    check=1;
    while check
        %% get a good order of the stimuli
        check=0;
        attempts=attempts+1;
        CurrSimList=encodingLists(encodingLists(:,3)==l,:);
        repeat=find(CurrSimList(:,9)>0);
        CurrSimList=[CurrSimList;CurrSimList];
        choose_repDrop=randperm(5);%randomly choose the repeated items that will be dropped in either the first and second reps
        if round(rand())
            CurrSimList(repeat(choose_repDrop(1:2)),9)=0;
            CurrSimList((repeat(choose_repDrop(3:5))+nTrialsPerList),9)=0;
        else
            CurrSimList(repeat(choose_repDrop(1:3)),9)=0;
            CurrSimList((repeat(choose_repDrop(4:5))+nTrialsPerList),9)=0;
        end
        
        %randomize within each repetition
        CurrSimList=CurrSimList([randperm(nTrialsPerList)';(randperm(nTrialsPerList)+nTrialsPerList)'],:);
        
        %check that there's no repetition of the same item between the two
        %cycles:
        if CurrSimList(nTrialsPerList,7)==CurrSimList(nTrialsPerList+1,7)
            check=1;
            display('identical item between cycles similarity')
        else
            
            %add the repeat trials:
            repeat=find(CurrSimList(:,9)>0);
            diff=repeat(2:end)-repeat(1:end-1);%compute gaps between two repeat trials
            
            if any(diff>MaxGapRepeatSim)
                check=1;
            elseif repeat(1)>MaxGapRepeatSim %the first one is too late
                check=1;
            elseif repeat(end)<(nTrialsPerList-MaxGapRepeatSim) %the last one is too early - that's a bug - nTrialsPerList is 24 - should have been nTrialsPerList*2, because items are presented twice, so I didn't control that in essence.
                check=1;
            else
                %% this is a good repeat sequence - check for more things
                %check for distance between trials of the same events or n and n+1
                %events - I took it out since it's impossible when having similarity per list, so look at other scripts.
                
                % make sure that there will be gap between n and n+1 items:
                %check that the following items in the similarity list do not
                %appear before or after in the encoding list (i.e. - checks
                %both directions of n+1 and n-1.
                for t=1:nTrialsPerList*2-1
                    %display(sprintf('now checking list %d event %d\n',l,e));
                    
                    %find the location during encoding:
                    curr_item=CurrSimList(t,7);
                    if t < (nTrialsPerList*2-1)
                        next_items=CurrSimList([t+1],7); %add t+1 here if want to check the 2 following items in the similarity scan
                    else %this is the one before last item in the similarity sequence, so only check that
                        next_items=CurrSimList(t+1,7);
                    end
                    
                    %check the following item in the encoding list
                    loc_t=find(encodingLists(:,7)==curr_item);
                    if loc_t<size(encodingLists,1) %this is not the last item:
                        if any(ismember(next_items,encodingLists((loc_t+1),7)))
                            check=1;
                        end
                    end
                    
                    %this checks two following items in the encoding list:
                    %                 if loc_t==size(encodingLists,1)-1 %this is one before the last item - check only one next item
                    %                     if any(ismember(next_items,encodingLists((loc_t+1),7)))
                    %                         check=1;
                    %                     end
                    %                 elseif loc_t<(size(encodingLists,1)-1) %there are two following items - check them
                    %                     if any(ismember(next_items,encodingLists((loc_t+1):(loc_t+2),7)))
                    %                         check=1;
                    %                     end
                    %                 end
                end
                
                %now check that the next item does not appear in the preceding items as well:
                for t=1:nTrialsPerList*2-1
                    %find the location during encoding:
                    curr_item=CurrSimList(t,7);
                    if t < (nTrialsPerList*2-1)
                        next_items=CurrSimList([t+1],7); %add t+1 here if want to check the 2 following items in the similarity scan
                    else %this is the one before last item in the similarity sequence, so only check that
                        next_items=CurrSimList(t+1,7);
                    end
                    
                    loc_t=find(encodingLists(:,7)==curr_item);
                    
                    %check the preceding item in the encoding list
                    if loc_t>1 %this is not the first item:
                        if any(ismember(next_items,encodingLists((loc_t-1),7)))
                            check=1;
                        end
                    end
                    
                    %                 %this checks two preceding items in the encoding list:
                    %                 if loc_t==2 %this is the second one in the encoding list - only one check before
                    %                     if any(ismember(next_items,encodingLists((loc_t-1),7)))
                    %                         check=1;
                    %                     end
                    %                 elseif loc_t>2 %there are two preceding items - check them
                    %                     if any(ismember(next_items,encodingLists((loc_t-2):(loc_t-1),7)))
                    %                         check=1;
                    %                     end
                    %                 end
                end
                
                
                %check that across the two reps there are no repeating
                %pairs, e.g., that items 17,20 do not appear one after the
                %other twice (nor does 20,17 appear):
                if ~check
                    for tt=1:nTrialsPerList
                        sec_loc=find(CurrSimList(:,7)==CurrSimList(tt,7),1,'last');
                        if tt>1 && tt<nTrialsPerList %check both sides
                            around=[CurrSimList(tt-1,7) CurrSimList(tt+1,7)];
                        elseif tt==1
                            around=CurrSimList(tt+1,7);
                        else %t=nTrialsPerLisr
                            around=CurrSimList(tt-1,7);
                        end
                        
                        if  sec_loc<nTrialsPerList*2 %check both sides (sec_loc cannot be the first item, no need to check that
                            around_sec=[CurrSimList(sec_loc-1,7) CurrSimList(sec_loc+1,7)];
                        else % sec_loc=nTrialsPerLisr
                            around_sec=CurrSimList(sec_loc-1,7);
                        end
                        
                        if any(ismember(around,around_sec))
                            check=1;
                            break
                        end
                    end
                end %ends the if on checking for two identical repetitions
                
                
            end %ends the conditional on the gaps (and other things I put in if the gaps are fine)
            
            %% list s good, check jitter
            if ~check %whoo hoo! list is good
                display(sprintf('found a sim sequence for list %d - checking jitter',l))
                %%%add the repeat
                repeat=find(CurrSimList(:,9)>0);
                for i=1:length(repeat)
                    CurrSimList=[CurrSimList(1:repeat(i),:);CurrSimList(repeat(i),:);CurrSimList(repeat(i)+1:end,:)];
                    repeat(i:end)=repeat(i:end)+1;
                end
                %mark the items
                CurrSimList=[CurrSimList zeros(nTrialsPerList*2+length(repeat),1)];
                CurrSimList(repeat,last_enc_col+1)=1;
                CurrSimList=[CurrSimList zeros(nTrialsPerList*2+length(repeat),1)];
                CurrSimList((repeat-1),last_enc_col+2)=1;
                CurrSimList(repeat,last_enc_col+2)=2;
                
                
                %% check jitter:
                jitter_check=1;
                attempts_jit=0;
                while jitter_check
                    attempts_jit=attempts_jit+1;
                    jitter_check=0;
                    %display('checking similarity jitter');
                    jitter=[];
                    for col=1:5
                        jitter=[jitter;j(randperm(length(j)))];%shuffle within each fifth of the trials, to have an equal spread, this gives us 50, we need 54
                    end
                    add_jit=[3 5]';
                    jitter=[jitter;add_jit(randperm(2));1]; %the last jitter one is dropped, so just to make sure that all lists are of equal length - I set it to drop 1 sec
                    
                    trial_lengths=stim_dur + jitter;
                    sim_onsets_temp=run_delay + cumsum(trial_lengths) - (trial_lengths);
                    run_length=sim_onsets_temp(end)+stim_dur+run_decay;
                    run_length_tp=run_length/tr;
                    trial_onsets_tp=sim_onsets_temp./tr;
                    repeat=find(CurrSimList(:,10)>0);
                    design=zeros(run_length_tp,nTrialsPerList); %check the correlations between all regressors -
                    %not how I'll do the analysis, I'll do the Mumford model, but just
                    %to make sure that there's nothing too funky going on
                    design_conv=[];
                    %I had a bug: this loop doesn't exclude the repeat items - the index runs on them as well. I only noticed
                    %it when I wanted to simulate the data - that means that for each list, it went until nTrialsPerList
                    %including the repeating trials - so it didn't check the last 2/3 items. That was,sadly, for almost all
                    %participants - until participant 29 (including). I changed it after, but I keep the code here for
                    %refernece: **when I re-produced the participants, I
                    %saw that it was way easier to find jitter this way, so
                    %my assumption is that mostly, the correlated trials
                    %were those with the repeat - hence the trials I didn't
                    %check should be fine.
                    
%                     for col=1:nTrialsPerList
%                         curr_loc=find(CurrSimList(:,7)==CurrSimList(col,7));
%                         curr_loc(ismember(curr_loc,repeat))=[];
%                         design(trial_onsets_tp(curr_loc),col)=1;
%                         design_conv(:,col)=conv(design(:,col),hrf);
%                     end
                    col=1;
                    SimList_idx=1;
                    while col <= nTrialsPerList
                        if (~ismember(SimList_idx,repeat)) %this is not a repeat trial, ignore these:
                            curr_loc=find(CurrSimList(:,7)==CurrSimList(SimList_idx,7));
                            curr_loc(ismember(curr_loc,repeat))=[];
                            design(trial_onsets_tp(curr_loc),col)=1;
                            design_conv(:,col)=conv(design(:,col),hrf);
                            col=col+1;
                        end
                        SimList_idx=SimList_idx+1;
                    end

                    design_conv=design_conv(1:run_length_tp,:);
                    design_corr=abs(corr(design_conv));
                    design_corr(design_corr==1)=0;
                    if any(any(design_corr>min_corr))
                        jitter_check=1;
                    end
                    
                    if mod(attempts_jit,30000)==0
                        attempts_jit
                    end
                    
                    if attempts_jit>100000
                        display(sprintf('didn''t found a good jitter sequence for list %d - reshuffling',l));
                        jitter_check=0;
                        check=1;
                    end
                end %ends the jitter check
                
            end %ends the if we're good, check jitter
        end
        
        if mod(attempts,100000)==0
            attempts
        end
        
    end %ends the check on the list
    similarityList=[similarityList;CurrSimList];
    sim_onsets=[sim_onsets;sim_onsets_temp'];
end%ends the loop on all lists

save([subj_dir '/similarity.mat'],'similarityList','sim_onsets');

%% set up the onsets for the encoding phase - no jittering
%I ran some versions of Repatime with jittering during encoding - we droped
%that because it influenced the behavior - so there was a whole section
%here that checks the correlations btw different regressors, and time gaps
%etc. all of that is unecessary in the fixed duration. check the script of
%Repatime5 for that section.

%since it's fixed, here it's redundent - but kept it becuase the encoding
%script uses it...

run_delay = 2;
%run_decay = 12;
%tr=2;
stim_dur=2;
ISI_enc=4;

enc_onsets=run_delay:(stim_dur+ISI_enc):(stim_dur+ISI_enc)*nTrialsPerList; %the same for all lists, all reps

save([subj_dir '/encoding.mat'],'encodingLists','enc_onsets');

%% prepare the color memory list

%shuffle the location of the color keys:
color_keys=randperm(6);

%definitions for randomizing the items across the 4 blocks:
%in this version, i control it so it'll be 4 runs, each run has an one item
%from an event, so that I could compare similarity within and across
%events, always across block
nBlocks=4;
allPerm=perms(1:nBlocks); %each number (1:4) is the block during color test, each row is an event, each column is the event position

%there are 24 perms, I need 18 per day (18 events) - take out 6, 4 from each group of 6 perms, then 2 more:
rPerms=reshape(1:nTrialsPerList,6,nTrialsPerEvent);
%this randomizes each group of six, so that later we'll take out the first
%row of rPerms, and it'll be 1 of each group of 6 params
for col=1:nTrialsPerEvent
    rPerms(:,col)=rPerms(randperm(6),col);
end
%2:end, beacause the first row will be removed completely
%randperm(nTrialsPerEvent): the colums are the groups of 6. we ramdomize
%the selection of group of 6, and the order within the group was randomized
%before.
two_more=rPerms(2:end,randperm(nTrialsPerEvent));

allPerm([rPerms(1,:) two_more(1) two_more(1,2)],:)=[];

%this make sure we have the same permutation for both days, but randomize
%the events differently:
allPermdays=reshape(allPerm(randperm(size(allPerm,1)),:)',numel(allPerm),1); %randomize the order and convert to a column
allPermdays=[allPermdays;reshape(allPerm(randperm(size(allPerm,1)),:)',numel(allPerm),1)]; %do the same for day 2
%take these trials per block for the color list - have the indecis, then - ColorTestList=encodingLists(randperm(size(encodingLists,1)),:);
items_color=[];
for i=1:nBlocks
    items_color=[items_color find(allPermdays==i)];%randomize the order later - make sure there is a good spread of day1 and day2
end

%definitions for the jittering:
run_delay = 2;
run_decay = 12;
tr=2;
stim_dur=6;
% stick function convolved with FSL's double gamma HRF
%from Alexa - fit a 2s TR
hrf =[0.0036 0.0960 0.1469 0.1163 0.0679 0.0329 0.0137 0.0047 0.0008 -0.0007 -0.0013 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017 -0.0017];
last_enc_col=size(encodingLists,2);
num_bt=1000;
j=([1 1 1 3 3 3 3 5 5 5 1 1 1 3 3 3 3 5 5 5 1 1 1 3 3 3 3 5 5 5 1 3 3 5 5]+1)';
min_corr=0.3;
nTrialsPerBlock=nTrials/nBlocks;
color_onsets=zeros(nBlocks,nTrialsPerBlock);
%start randomizing:
ColorTestList=[];
for b=1:nBlocks
    display(sprintf('checking color list %d',b));
    check=1;
    while check
        check=0;
        items_temp=items_color(randperm(size(items_color,1)),b);
        ColorTestList_temp=encodingLists(items_temp,:);
        %first, make sure there is no sequence of more than 4 trials of same
        %day vs. previous day
        rand_trials=ColorTestList_temp(:,2);
        check_m=convPeriodic(rand_trials,[1,1,1,1,1]);%caclulate the sum - 1 1 1 1 1 would yield 5 and 2 2 2 2 2 would yield 10, anytihng between is good
        check_m=check_m(1:(length(check_m)-4));%trim the edge - it ciculate with the begining, doesn't make sense
        if any(check_m==5) || any(check_m==10)
            check=1;
        end
        
        %since each event contributes one item per block, cannot be two
        %consequtive items of the same event, so we're done. Do the jitter:
        if ~check %put the sequence in, check the jitter:
            %display(sprintf('found a color sequence for block %d - checking jitter',b))
           
            %% set up the onsets for the test:
            jitter_check=1;
            attempts=0;
            while jitter_check
                attempts=attempts+1;
                jitter_check=0;
                %display('checking color jitter');
                jitter=[j(randperm(length(j)));2];%the last jitter one is dropped, so just to make sure that all lists are of equal length - I set it to drop 2 sec
                trial_lengths=stim_dur + jitter;
                color_onsets_temp=run_delay + cumsum(trial_lengths) - (trial_lengths);
                %color_onsets(b,:)=color_onsets_temp;
                %checking the correlations:
                run_length=color_onsets_temp(end)+stim_dur+run_decay;
                run_length_tp=run_length/tr;
                trial_onsets_tp=color_onsets_temp./tr;
%                 %checking for correlations between days - was too high
%                 %(above 0.4), so don't look at that - do the full 2 by 2
%                 %(see below), then in the contrasts have the comparison -
%                 %ayway the better way to do it.
%                 design=zeros(run_length_tp,2); %check the correlations between the day1 and day2 - may want it for univariate
%                 design_conv=[];
%                 min_corr=0.4; %will probably do the full design, but just to be sure.
%                 for col=1:2
%                     curr_loc=find(ColorTestList_temp(:,2)==col);
%                     design(trial_onsets_tp(curr_loc),col)=1;
%                     design_conv(:,col)=conv(design(:,col),hrf);
%                 end
%                 design_conv=design_conv(1:run_length_tp,:);
%                 design_corr=abs(corr(design_conv));
%                 design_corr(design_corr==1)=0;
%                 if any(any(design_corr>min_corr))
%                     jitter_check=1;
%                 end
%                 
                if ~jitter_check %that's fine, now check boundary/non-boundary y day
                    min_corr=0.3;
                    design=zeros(run_length_tp,2); %check the correlations between the day1 and day2 - may want it for univariate
                    design_conv=[];
                    for d=1:2
                        col=1;
                        curr_loc=find(((ColorTestList_temp(:,6)==col) + (ColorTestList_temp(:,2)==d))==2); %boundary items, day 1 or 2
                        design(trial_onsets_tp(curr_loc),(d-1)*2+1)=1;
                        design_conv(:,col)=conv(design(:,col),hrf);
                        
                        curr_loc=find(((ColorTestList_temp(:,6)>col) + (ColorTestList_temp(:,2)==d))==2); %boundary items, day 1 or 2
                        design(trial_onsets_tp(curr_loc),(d-1)*2+2)=1;
                        design_conv(:,col)=conv(design(:,col),hrf);
                    end
                    design_conv=design_conv(1:run_length_tp,:);
                    design_corr=abs(corr(design_conv));
                    design_corr(design_corr==1)=0;
                    if any(any(design_corr>min_corr))
                        jitter_check=1;
                    end
                end
                %             if mod(attempts,10000)==0
                %                 attempts
                %                 %jitter_check=0;
                %             end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if attempts > 10000
                    display('didn''t find a good color sequence - re shuffle the order');
                    check=1;
                    jitter_check=0;
                    break
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end
    end %ends the conditional on the color list
   
    if ~check && ~jitter_check  %out of the loop, should be fine, but check nevertheless
         ColorTestList_temp=[ColorTestList_temp ones(size(ColorTestList_temp,1),1)*b];%mark the block - i put it at the end just to not interfere with previous scripts
         ColorTestList=[ColorTestList;ColorTestList_temp];
         color_onsets(b,:)=color_onsets_temp;
    else
         display('shoot! script is bed, out of the randomization loop but checks are not good');
    end
            
end %ends the cwhile on the block


save([subj_dir '/color_test.mat'],'ColorTestList','color_onsets','color_keys');    



end
