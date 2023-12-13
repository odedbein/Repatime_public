function repatimeS_matchmis(subj_num, subj_id,iList,varargin)
% function encoding(subj_num, subj_initials, fMRI, practice, debug, [startBlock])
% Inputs:
%   subj_num: start first subject as 1, used to counterbalance button
%                       box response mappings (integer)
%   subj_initials:      subject initials, used to write output file names (string)
%   part:               'day1_init'/'day2_init'/'rem'/'er_block'
%   fMRI:               [0 / 1] looks for scanner pulse/trigger if fMRI,
%                       restricts KbCheck to button box
%   practice:           [0 / 1] run through 10 practice trials
%   debug:              [0 / 1] if debug, not whole screen

%% boiler plate

fMRI=varargin{1};
practice=varargin{2};
debug=varargin{3};
if length(varargin) == 4
mainWindow=varargin{4};
end
startBlock=1;

if ~debug;
    ListenChar(2);
    HideCursor;
end

Priority(0);
Screen('Preference', 'SkipSyncTests', 1 );
description = Screen('Computer'); %#ok<NASGU>

%% paths
project_dir='.';
%addpath(fullfile(project_dir,'scripts'))
stim_dir=fullfile(project_dir,'images');
data_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id));

if ~exist(data_dir,'dir')
    mkdir(data_dir);
end
%% file lists:
file_names={};
%get all the images:
dir_list=dir(stim_dir);
% skip stuff that isn't an image
dir_list = dir_list(3:end);               % skip . & ..
if (strcmp(dir_list(1).name,'.DS_Store')==1) % also skip .DS_Store
    dir_list= dir_list(2:end);
end

for image=1:numel(dir_list)
    file_names{image}=[stim_dir '/' dir_list(image).name];
end

%% trial timing: all units in sec
if debug
    stim_dur = 0.1;
    response_window = 0.1;
    CP_Int=0.1;%cue-probe interval
    arrow_dur=0.1;
else
    stim_dur = 3;
    response_window = 4;
    CP_Int=5;%cue-probe interval
    arrow_dur=1;
end

run_delay = 2;
run_decay = 13;
btw_runs_time=2;
%% keyboard and key presses
device=-1; %allows use all keyboard platforms
KbName('UnifyKeyNames');

if fMRI == 1
    %for the match.mis memory - response with left hand
    sure_left = KbName('9(');
    maybe_left = KbName('8*');
    maybe_right = KbName('7&');
    sure_right = KbName('6^');
    
    left_arrow = KbName('7&');
    right_arrow = KbName('6^');
elseif fMRI == 0
    %for the match.mis memory
    sure_left = KbName('h');
    maybe_left = KbName('j');
    maybe_right = KbName('k');
    sure_right = KbName('l');
    
    left_arrow = KbName('k');
    right_arrow = KbName('l');
end
backtick=KbName('5%');

%not counterbalancing responses presses by subject
instructString{1} = 'Order memory task:'; 
instructString{2} = 'Upon seeing the first object in each trial,'; 
instructString{3} = 'recall the following object from the object/color sequence.';
instructString{4} = 'Then indicate which of the two items that appear on the screen';
instructString{5} = 'matches the following item in the object/color sequence';
instructString{6} = 'Remember to use all 4 buttons';
instructString{7} = 'Try your best to recall the following object';
instructString{8} = 'Please respond as quickly as possible while still being accurate,'; 
instructString{9} = 'remember that accuracy is more important';


%if for some reason running not in the scanner - let the participant know he/she should press "q": 
if ~fMRI && ~practice
    instructString{end+1} = 'Press ''q'' to begin!';
end

if practice==1
    instructString{end+1} = '(practice round)';
end

%response buttons:
KeyTest{1} = 'LEFT SURE       LEFT UNSURE'; 
KeyTest{2} = 'RIGHT UNSURE     RIGHT SURE';

% instructions to get the experimenter at the end
if fMRI==0
    progressString{1} = 'Great job!';
    progressString{2} = 'Please find the experimenter in the other room.';
elseif fMRI==1
    progressString{1} = 'Great job!';
end

%% set screen information
backColor = 127;
textColor = 0;
textColorFixRecall=1111;
textFont = 'Arial';
textSize = 34; %change here for larger fixations, arrows and begining text.
mm_text_size=28; %text size of the match/mismatch task keys
textSpacing = 38;
imageSize=350; % assumed square
screens = Screen('Screens');

if fMRI
    % present stimuli in second screen
    windowIdx=max(screens);
    [Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
elseif debug
    % present stimuli on second screen, but smaller
    windowIdx=max(screens);
    Screen_X = 1280; %these are the dimentions of the testing room screen
    Screen_Y = 1024;
else
    % behavioral: run in testing room
    windowIdx=min(screens);
    [Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
%     Screen_X = 1280; %these are the dimentions of the testing room screen
%     Screen_Y = 1024;

end
centerX = Screen_X/2;
centerY = Screen_Y/2;

% placeholder for images
imageRect = [0,0,imageSize,imageSize];

% position of images
centerRect = [centerX-imageSize/2,centerY-imageSize/2,centerX+imageSize/2,centerY+imageSize/2];

%position for the match/mismatch trial
mvFromCenter=70; %each image will move 30 pixels from the center
leftImCenterX=centerX-imageSize/2-mvFromCenter;%easy to locate the text later
rightImCenterX=centerX+imageSize/2+mvFromCenter;%easy to locate the text later
leftRect = [leftImCenterX-imageSize/2,centerY-imageSize/2,leftImCenterX+imageSize/2,centerY+imageSize/2];
rightRect = [rightImCenterX-imageSize/2,centerY-imageSize/2,rightImCenterX+imageSize/2,centerY+imageSize/2];

%position for the match/mismatch text
Ytext= centerY+imageSize/2+50;


%% load trial sequences
load([data_dir '/matchmis'],'MatchMisLists','matchmis_onsets','MatchMisDistLoc');
nPracTrials=8;

%select the current list:
MatchMisList=MatchMisLists(MatchMisLists(:,3)==iList,:);
MatchMisDistLoc=MatchMisDistLoc(:,:,iList);

condition=MatchMisList(:,6);
condition(condition==4)=3; %1 - boundary, 2 - nb-within 3 - across
trial_seq=MatchMisList(:,7);
matchmis_idx=trial_seq;
target_idx=MatchMisList(:,9);
lure_idx=MatchMisList(:,10);
trial_onsets=matchmis_onsets(iList,1:2:end);
n_runs=1;

if practice
    
    % override number of encoding trials and stim folder
    n_runs=1;
    matchmis_idx=[1 4 6]; 
    target_idx=matchmis_idx+1;
    lure_idx=matchmis_idx+2;
    % skip stuff that isn't an image
    dir_list=dir([project_dir '/practiceEnc']);
    dir_list = dir_list(3:end);               % skip . & ..
    if (strcmp(dir_list(1).name,'.DS_Store')==1) % also skip .DS_Store
        dir_list = dir_list(2:end);
    end
    
    prac_file_names={};
    % grab some objects
    for f=1:nPracTrials 
        prac_file_names{f}=[project_dir '/practiceEnc/' dir_list(f).name];
    end
end

%% load images
% create main window
if length(varargin)==3 %ran independently without the wrapper.
    %set up the main window and present a grey screen
    if fMRI && ~debug
        mainWindow = Screen(windowIdx,'OpenWindow',backColor,[]);
    else
        mainWindow = Screen(windowIdx,'OpenWindow',backColor,[0 0 Screen_X Screen_Y]);
    end
    
end
Screen(mainWindow,'TextFont',textFont);
Screen(mainWindow,'TextSize',textSize);

% set up the tuxture to draw stimuli from:
if practice==1
    matchmis_texture=zeros(size(matchmis_idx));
    for i=1:length(matchmis_idx) %the number of the stimuli
        
        %enc_idx is the order of the stimuli
        % match encoding index to the list of all indices for this subject
        %all_idx is an array of numbers - possibly, this is the array that sets
        %which image is "image number x" it is different in each subject
        %takes "image number 1" finds it in loc - say, number 40.
        %temp_idx=all_idx==i;
        
        % read in images in the order of encoding presentation
        temp_image = imread(prac_file_names{matchmis_idx(i)}); %now in temp image, the first 1, there is the 40th image in the folder
        
        % return index of images that can be called by 'DrawTexture'
        matchmis_texture(i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
    
    %same for targets - I cut the explanation, same as above
    target_texture=zeros(size(target_idx));
    for i=1:length(target_idx) %the number of the stimuli
        temp_image = imread(prac_file_names{target_idx(i)});
        target_texture(i) = Screen('MakeTexture',mainWindow,temp_image);
    end
    
    %same for lures - I cut the explanation, same as above
    lure_texture=zeros(size(lure_idx));
    for i=1:length(lure_idx) %the number of the stimuli
        temp_image = imread(prac_file_names{lure_idx(i)});
        lure_texture(i) = Screen('MakeTexture',mainWindow,temp_image);
    end
    
elseif practice==0
    idx_to_find=unique(matchmis_idx)';
    matchmis_texture=zeros(size(matchmis_idx));
    for i=idx_to_find %the number of the stimuli
        
        %enc_idx is the order of the stimuli
        % match encoding index to the list of all indices for this subject
        %all_idx is an array of numbers - possibly, this is the array that sets
        %which image is "image number x" it is different in each subject
        %takes "image number 1" finds it in loc - say, number 40.
        %temp_idx=all_idx==i;
        
        % read in images in the order of encoding presentation
        temp_image = imread(file_names{i}); %now in temp image, the first 1, there is the 40th image in the folder
        
        % return index of images that can be called by 'DrawTexture'
        matchmis_texture(matchmis_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
    
    %same for targets - I cut the explanation, same as above
    idx_to_find=unique(target_idx)';
    target_texture=zeros(size(target_idx));
    for i=idx_to_find %the number of the stimuli
        temp_image = imread(file_names{i});
        target_texture(target_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
    end
    
    %same for lures - I cut the explanation, same as above
    idx_to_find=unique(lure_idx)';
    lure_texture=zeros(size(lure_idx));
    for i=idx_to_find %the number of the stimuli
        temp_image = imread(file_names{i});
        lure_texture(lure_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
    end
end

%% trial onsets and data structures
if practice==0
    tpr=length(trial_seq); % trials per run
else
    tpr=length(matchmis_idx);
end

if debug==0 
    if practice==0 %this is not practice
        run_length=trial_onsets(end)+stim_dur*2+CP_Int+run_decay; %
    elseif practice==1 %this is practice - do not wait the initial 12 secs, just 2
        %override the onsets
        trial_onsets=trial_onsets(1:tpr)-1; %to use the made onsets, but not wait 2 secs
        run_length=trial_onsets(end)+stim_dur+1; % end 1 sec after last trial
    end
elseif debug==1
    iti=.25 * ones(size(matchmis_texture));
    trial_lengths=stim_dur + iti;
    trial_onsets=cumsum(trial_lengths,2) - (stim_dur+iti);
    run_length=trial_onsets(end)+stim_dur+1; % end 1 sec after last trial
end
%set up variables for the output mat file:
stim_onset=zeros(n_runs,tpr*2);%one for the cue and one for the probe
cueProbe=zeros(n_runs,tpr*2);%mark if cue or probe
response=zeros(n_runs,tpr);
response_times=zeros(n_runs,tpr);
response_accuracy=zeros(n_runs,tpr);
response_conf=zeros(n_runs,tpr);
cue_num=zeros(n_runs,tpr);
target_num=zeros(n_runs,tpr);
lure_num=zeros(n_runs,tpr);

%set up variables for the arrows file
arrows_resp=[];
arrows_resp_time=[];
arrows_resp_accuracy=[];
arrows_RL=[];%was the arrow to the left or right
arrows_switch=[];%was there a switch
arrows_condition=[];%which condiiton in match/mis
arrows_trial=[];%which trial in match/mis
arrows_onset=[];

% set up diagnostic plot
if fMRI==1 || debug==1
    rd = response_diagnostics(response_window, tpr);
end

%% run loop
for rep=startBlock:n_runs
    
    if practice == 0
        % set up output text file - match/mismatch
        data_file=fullfile(data_dir,['matchmis_' num2str(subj_num) subj_id '_list' num2str(iList) '.txt']);
        if exist(data_file,'file')
            data_file=[data_file(1:end-4) '1.txt'];
        end
        fid = fopen(data_file, 'w');
        fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init','day','list','cue/probe','condition', 'trial', 'onset', 'cue','target','lure', 'left/right','cue pos','resp', 'acc','conf', 'rt');
        
        % set up output text file - arrows
        data_file=fullfile(data_dir,['arrows_matchmis_' num2str(subj_num) subj_id '_list' num2str(iList) '.txt']);
        if exist(data_file,'file')
            data_file=[data_file(1:end-4) '1.txt'];
        end
        fid_arrows = fopen(data_file, 'w');
        fprintf(fid_arrows,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init','day','list','condition', 'trial', 'onset','switch','left/right','resp', 'acc','rt');
    end
    
    % print header of the match/mismatch to screen
    fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init','day','list','cue/probe', 'condition','trial', 'onset', 'cue','target','lure', 'left/right','cue pos','resp', 'acc','conf', 'rt');
    
    % set up diagnostic plot
    if fMRI==1 || debug==1
        rd = response_diagnostics(response_window, tpr);
    end
    
    %% show instructions
    tempBoundsY = Screen('TextBounds',mainWindow,instructString{1});
    for i=1:numel(instructString)
        tempBounds = Screen('TextBounds',mainWindow,instructString{i});
        Screen('drawtext',mainWindow,instructString{i},round(centerX-tempBounds(3)/2),round(centerY-tempBoundsY(4)*numel(instructString)/2+textSpacing*(i-1)),textColor);
        clear tempBounds;
    end
    Screen('Flip',mainWindow);
    
    % wait for experimenter to advance with 'q' key
    FlushEvents('keyDown');
    while(1)
        temp = GetChar;
        if (temp == 'q')
            break;
        end
    end
    
    %clear screen
    Screen(mainWindow,'FillRect',backColor);
    Screen('Flip',mainWindow);
    Priority(MaxPriority(windowIdx));
    
    % fixation until first trial
    tempBounds = Screen('TextBounds',mainWindow,'+');
    Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
    clear tempBounds;
    Screen('Flip',mainWindow);
    
    if fMRI==1 && practice == 0
        
        % wait for scanner to spit out the first back tick
        FlushEvents('keyDown');
        while(1)
            temp = GetChar;
            if (temp == '5')
                runTime=GetSecs;
                break;
            end
        end
        
    else
        runTime = GetSecs;
    end
    
    
    %% trial loop
    for trial=1:tpr
        
        % wait for next trial onset - minus 0.5s
        while GetSecs<runTime+trial_onsets(trial)-0.5; end
        
        % present a blinking fixation
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
        WaitSecs(0.1);
        Screen(mainWindow,'FillRect',backColor);
        Screen('Flip',mainWindow);
        WaitSecs(0.1);
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
        % wait for next trial onset
        while GetSecs<runTime+trial_onsets(trial); end
        
        % present the cue
        Screen('DrawTexture',mainWindow,matchmis_texture(trial),imageRect,centerRect);
        stim_start=Screen('Flip',mainWindow);
        stim_onset(rep,(trial-1)*2+1)=stim_start-runTime;
        cue_num(rep,trial)=matchmis_idx(trial);
        cueProbe(rep,(trial-1)*2+1)=0;%zero means cue,1 would mean probe
        % wait for the trial duration
        while GetSecs < stim_start + stim_dur; end
        
        %present the white fication
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColorFixRecall);%textColorFixRecall);
        clear tempBounds;
        stim_start=Screen('Flip',mainWindow);
        % wait for the fixation btw cue and probe duration
        while GetSecs < stim_start + CP_Int; end
        
        %present the two probes
        
        %build the screan
        %put in the text
        Screen(mainWindow,'TextSize',mm_text_size); %change the ext size
        tempBounds = Screen('TextBounds',mainWindow,KeyTest{1});
        Screen('drawtext',mainWindow,KeyTest{1},(leftImCenterX-tempBounds(3)/2),Ytext,textColor);
        clear tempBounds;
        tempBounds = Screen('TextBounds',mainWindow,KeyTest{2});
        Screen('drawtext',mainWindow,KeyTest{2},(rightImCenterX-tempBounds(3)/2),Ytext,textColor);
        clear tempBounds;
        %target appears on the left or on the right?
        if MatchMisDistLoc(trial)==1 %target is on the left side of the screen
            Screen('DrawTexture',mainWindow,target_texture(trial),imageRect,leftRect);
            Screen('DrawTexture',mainWindow,lure_texture(trial),imageRect,rightRect);
        else %target is on the right side of the screen
            Screen('DrawTexture',mainWindow,lure_texture(trial),imageRect,leftRect);
            Screen('DrawTexture',mainWindow,target_texture(trial),imageRect,rightRect);
        end
       
        Screen(mainWindow,'TextSize',textSize);  %change the text size back to defoult
        stim_start=Screen('Flip',mainWindow);
        stim_onset((trial-1)*2+2)=stim_start-runTime;
        stim_onset(rep,(trial-1)*2+2)=stim_start-runTime;
        target_num(rep,trial)=target_idx(trial);
        lure_num(rep,trial)=lure_idx(trial);
        cueProbe(rep,(trial-1)*2+2)=1;%zero means cue,1 would mean probe
        correctResp=MatchMisDistLoc(trial);
        %  collect reponse
        FlushEvents('keyDown');
        while (GetSecs < (stim_start + response_window)) % allows another second to respond after taking down the images
            WaitSecs(.0005);
            
            % take down image
            if GetSecs >= stim_start + stim_dur
                tempBounds = Screen('TextBounds',mainWindow,'+');
                Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
                clear tempBounds;
                Screen('Flip', mainWindow);
            end
            
            % wait for response
            %if (response(trial) == 0)
                [keyIsDown, secs, keyCode] = KbCheck(device);
                if (keyIsDown) && find(keyCode,1) ~= backtick
                    % record response button, response time, and response
                    % confidence
                    response(trial) = find(keyCode,1);
                    response_times(trial) = secs - stim_start;
                    
                    %confidence
                    switch find(keyCode,1)
                        case sure_left
                            response_conf(trial)=1;
                        case maybe_left
                            response_conf(trial)=0;
                        case maybe_right
                            response_conf(trial)=0;
                        case sure_right
                            response_conf(trial)=1;
                    end
                    
                    %accuracy
                    if correctResp==1 %target is on the left side of the screen
                        switch find(keyCode,1)
                            case sure_left
                                response_accuracy(trial)=1;
                            case maybe_left
                                response_accuracy(trial)=1;
                            case maybe_right
                                response_accuracy(trial)=0;
                            case sure_right
                                response_accuracy(trial)=0;
                        end
                    else
                        switch find(keyCode,1)
                            case sure_left
                                response_accuracy(trial)=0;
                            case maybe_left
                                response_accuracy(trial)=0;
                            case maybe_right
                                response_accuracy(trial)=1;
                            case sure_right
                                response_accuracy(trial)=1;
                        end
                    end %accuracy conditional
                end %a response was given conditional
            %end %no response yet conditional
        end %while trial is on
        
        % print cue output to screen
        fprintf('%d\t%s\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, MatchMisList(trial,2),MatchMisList(trial,3),cueProbe(rep,(trial-1)*2+1),condition(trial),trial, stim_onset((trial-1)*2+1), ...
            matchmis_idx(trial), target_idx(trial),lure_idx(trial),MatchMisDistLoc(trial), ...
            MatchMisList(trial,6),0,0,0,0); %zeros where we have responses
        % print probe output to screen
        fprintf('%d\t%s\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, MatchMisList(trial,2),MatchMisList(trial,3),cueProbe(rep,(trial-1)*2+2),condition(trial),trial, stim_onset((trial-1)*2+2), ...
            matchmis_idx(trial), target_idx(trial),lure_idx(trial),MatchMisDistLoc(trial), ...
            MatchMisList(trial,6),response(rep,trial), response_accuracy(rep,trial),response_conf(trial), response_times(rep,trial)); 
        
        if practice ==0
            % print cue output to text file
            fprintf(fid,'%d\t%s\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, MatchMisList(trial,2),MatchMisList(trial,3),cueProbe(rep,(trial-1)*2+1),condition(trial),trial, stim_onset((trial-1)*2+1), ...
            matchmis_idx(trial), target_idx(trial),lure_idx(trial),MatchMisDistLoc(trial), ...
            MatchMisList(trial,6),0,0,0,0); %zeros where we have responses
        % print probe output to text file
        fprintf(fid,'%d\t%s\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, MatchMisList(trial,2),MatchMisList(trial,3),cueProbe(rep,(trial-1)*2+2),condition(trial),trial, stim_onset((trial-1)*2+2), ...
            matchmis_idx(trial), target_idx(trial),lure_idx(trial),MatchMisDistLoc(trial), ...
            MatchMisList(trial,6),response(rep,trial), response_accuracy(rep,trial),response_conf(trial), response_times(rep,trial)); 
        end
        
        if fMRI==1 || debug==1
            % plot performance and rt ongoing
            rd.log_trial(response_times(rep,trial), 1, response_accuracy(trial));%if they were accurate - in blue, if not, in red
        end
        
        %% start the arrows - until the next trial - minus one sec after and one before
        if trial~=tpr %not the last trial
            num_arrows=(trial_onsets(trial+1)-trial_onsets(trial)-stim_dur*2-CP_Int-2);
            right_left=round(rand(num_arrows,1));
            for rl=1:length(right_left)
                if right_left(rl)
                    tempBounds = Screen('TextBounds',mainWindow,'>>>');
                    Screen('drawtext',mainWindow,'>>>',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
                    clear tempBounds;
                else
                    tempBounds = Screen('TextBounds',mainWindow,'<<<');
                    Screen('drawtext',mainWindow,'<<<',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
                    clear tempBounds;
                end
                stim_start=Screen('Flip',mainWindow);
                
                % log some parameters:
                arrows_RL(end+1)=right_left(rl);%1 neabs right, 0 means left
                if rl==1
                   arrows_switch(end+1)=1; %first one, should always response
                elseif right_left(rl)~=right_left(rl-1) %there was a switch
                   arrows_switch(end+1)=1; %first one, should always response
                else
                   arrows_switch(end+1)=0; %not the first one, and there was no switch
                end
                arrows_condition(end+1)=condition(trial);
                arrows_trial(end+1)=trial;
                arrows_onset(end+1)=stim_start-runTime;
                
                %  collect reponse
                FlushEvents('keyDown');
                arrows_resp(end+1)=0;
                while (GetSecs < (stim_start + arrow_dur)) % wait for the entire duration of the arrow
                    WaitSecs(.0005);
                    
                    % wait for response
                    if (arrows_resp(end) == 0)
                        [keyIsDown, secs, keyCode] = KbCheck(device);
                        if (keyIsDown) && find(keyCode,1) ~= backtick
                            % record response button, response time, and response
                            % accuracy
                            arrows_resp(end) = find(keyCode,1);
                            arrows_resp_time(end+1) = secs - stim_start;
                           
                            %accuracy
                            if arrows_switch(end)==1 %there was a switch, needed to respond
                                if right_left(rl) && (arrows_resp(end)==right_arrow) %arrows are to the right, responded right
                                    arrows_resp_accuracy(end+1)=1;
                                elseif ~right_left(rl) && (arrows_resp(end)==left_arrow) %arrows are to the left, responded left
                                    arrows_resp_accuracy(end+1)=1;
                                else
                                    arrows_resp_accuracy(end+1)=-1; %inaccurate
                                end
                            else %there was no switch, but there was a reponse:
                                arrows_resp_accuracy(end+1)=2; %a response when they shouldn't have responded
                            end %accuracy conditional
                        end %a response was given conditional
                    end %no response yet conditional
                end %while trial is on
                
                if arrows_resp(end)==0 %no response was given - set up the response time slot to zero
                   arrows_resp_time(end+1) = 0; 
                   arrows_resp_accuracy(end+1)=0; %no response
                end
                
                %write to a file the arrows response
                if ~practice
                fprintf(fid_arrows,'%d\t%s\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%.3f\n', ...
                         subj_num, subj_id, MatchMisList(trial,2), MatchMisList(trial,3),arrows_condition(end),arrows_trial(end),arrows_onset(end),arrows_switch(end),right_left(rl),arrows_resp(end),arrows_resp_accuracy(end),arrows_resp_time(end));
                end
            end
        end 
        
        
        % fixation until next trial
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
        
    end %ends the loop of all trials
    
end %ends the loop of all reps
    
% wait for scanner to finish
while GetSecs < runTime+run_length; end

if practice==0
    % close this run's text file
    fclose(fid);
    fclose(fid_arrows);
end



%% clean up and go home
if  practice==0
    %save main output
    mat_file=fullfile(data_dir,['matchmis_' num2str(subj_num) subj_id '_list' num2str(iList) '.mat']);
    if exist(mat_file,'file')
       mat_file=[mat_file(1:end-4) '1.mat'];
    end
    save(mat_file,'response','response_times','response_accuracy','response_conf','stim_onset','cueProbe','description','cue_num','target_num','lure_num','condition');
    %save arrows output
    mat_file=fullfile(data_dir,['arrows_matchmis_' num2str(subj_num) subj_id '_list' num2str(iList) '.mat']);
    if exist(mat_file,'file')
       mat_file=[mat_file(1:end-4) '1.mat'];
    end
    save(mat_file,'arrows_condition','arrows_trial','arrows_onset','arrows_switch','arrows_RL','arrows_resp','arrows_resp_accuracy','arrows_resp_time');
end

%present the great job screen for two seconds:
tempBounds = Screen('TextBounds',mainWindow,progressString{1});
Screen('drawtext',mainWindow,progressString{1},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
clear tempBounds;
Screen('Flip',mainWindow);
while GetSecs < runTime+run_length+btw_runs_time; end


%let's say that someone did a part of the study outside the scaner, that
%tells him/her to go get the experimenter:
% instructions to get the experimenter at the end
if fMRI==0 && ~practice && (iList==3 || iList==6)
    %% show instructions to get experimenter
    for i=1:length(progressString)
        tempBounds = Screen('TextBounds',mainWindow,progressString{i});
        Screen('drawtext',mainWindow,progressString{i},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/5+textSpacing*(i-1)),textColor);
        clear tempBounds;
    end
    Screen('Flip',mainWindow);
    
    % wait for experimenter to advance with 'q' key
    FlushEvents('keyDown');
    while(1)
        temp = GetChar;
        if (temp == 'q')
            break;
        end
    end
end

if ~fMRI && practice && length(varargin) == 3%otherwise just continue%otherwise just continue
    ListenChar(0);
    ShowCursor;
    sca
end

% clear screen
%sca