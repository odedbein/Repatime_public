function repatimeS_encoding(subj_num,subj_id,iList,rep,varargin)
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
nItemsPerEvent=4;
nPracTrials=nItemsPerEvent*2; %usually two events
fMRI=varargin{1};
practice=varargin{2};
debug=varargin{3};
if length(varargin) == 4
mainWindow=varargin{4};
end

if (length(varargin)==4) || (length(varargin)==5)
    startList=varargin{4};
else
    startList=1;
end


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
%addpath(fullfile(stim_dir))
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

if ~practice
    run_delay = 2;
    run_decay = 12;
else
    run_delay = 2;
    run_decay = 1;
end

if debug
    stim_dur = 0.1;
    response_window = 0.1;
    dur_fix_pre=0.05;
    run_delay=2;
    run_decay=2;
else
    stim_dur = 2;
    response_window = 3;
    dur_fix_pre=0.5;
end
ISI=4;
btw_runs_time=2;%time to wait between runs
%% keyboard and key presses
device=-1; %allows use all keyboard platforms
KbName('UnifyKeyNames');

if fMRI == 1
    LEFT = KbName('7&'); %right hand: middle fingure
    RIGHT = KbName('6^'); %left hand: index finger
elseif fMRI == 0
    LEFT = KbName('j');
    RIGHT = KbName('k');
end
backtick=KbName('5%');

% counterbalance response presses by subject
if (mod(subj_num,2) == 0)
    if fMRI
        instructString{1} = 'Object/color task:';
        instructString{2} = 'Visualize each object in the background color'; 
        instructString{3} = 'and decide whether the object/color combination is pleasing ';
        instructString{4} = 'If pleasing, press your index finger';
        instructString{5} = 'If unpleasing, press your middle finger';
        instructString{6} = 'Try to remember the color of the background for each object';
        instructString{7} = 'and the order that the objects appear in.';
        instructString{8} = 'Please remember to make a story linking the objects as you study them.';
    else
        instructString{1} = 'Object/color task:';
        instructString{2} = 'Visualize each object in the background color'; 
        instructString{3} = 'and decide whether the object/color combination is pleasing ';
        instructString{4} = 'If pleasing, press your index finger (''L'')';
        instructString{5} = 'If unpleasing, press your middle finger (''K'')';
        instructString{6} = 'Try to remember the color of the background for each object';
        instructString{7} = 'and the order that the objects appear in.';
        instructString{8} = 'Please remember to make a story linking the objects as you study them.';
    end
    pleasent=RIGHT; unpleasent=LEFT;
else
    if fMRI
        instructString{1} = 'Object/color task:';
        instructString{2} = 'Visualize each object in the background color'; 
        instructString{3} = 'and decide whether the object/color combination is pleasing ';
        instructString{4} = 'If unpleasing, press your index finger';
        instructString{5} = 'If pleasing, press your middle finger';
        instructString{6} = 'Try to remember the color of the background for each object';
        instructString{7} = 'and the order that the objects appear in.';
        instructString{8} = 'Please remember to make a story linking the objects as you study them.';
    else
        instructString{1} = 'Object/color task:';
        instructString{2} = 'Visualize each object in the background color'; 
        instructString{3} = 'and decide whether the object/color combination is pleasing ';
        instructString{4} = 'If unpleasing, press your index finger (''L'')';
        instructString{5} = 'If pleasing, press your middle finger (''K'')';
        instructString{6} = 'Try to remember the color of the background for each object';
        instructString{7} = 'and the order that the objects appear in.';
        instructString{8} = 'Please remember to make a story linking the objects as you study them.';
    end
    
    pleasent=LEFT; unpleasent=RIGHT;
end

if practice==1
    instructString{end+1} = '(practice round)';
end

%end of section:
progressString{1} = 'Great job!';


%% set screen information
backColor = 128;
textColor = 0;
textFont = 'Arial';
textSize = 34;
textSpacing = 38;
fixColor = 0;
imageSize=350; % assumed square
fixationSize = 8; % pixels
screens = Screen('Screens');

colorboxSize = 600;
whiteboxSize = 350;
whitebox = 255.*ones(whiteboxSize,whiteboxSize,3); % generates the white box that item stimuli will be placed inside
%colors
colormat=[255 0   0   %1-red
    51  221 0   %2-green
    0   0   255 %3-blue
    255 255 0  %4-yellow
    255 127 0  %5-orange
    255 0   255 %6-magenta
    ];    
    
if fMRI
    % present stimuli in second screen
    windowIdx=max(screens);
    [Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
elseif debug
    % present stimuli on second screen, but smaller
    windowIdx=max(screens);
    %[Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
    Screen_X = 1280;
    Screen_Y = 1024;
else
    % behavioral: run in testing room
    windowIdx=min(screens);
    [Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
%       Screen_X = 1280/2; %these are the dimentions of the testing room screen
%       Screen_Y = 1024/2;
end
centerX = Screen_X/2;
centerY = Screen_Y/2;

% placeholder for images
imageRect = [0,0,imageSize,imageSize];

% position of images
centerRect = [centerX-imageSize/2,centerY-imageSize/2,centerX+imageSize/2,centerY+imageSize/2];

% position of fixation dot
colorRect = [centerX-colorboxSize/2,centerY-colorboxSize/2,centerX+colorboxSize/2,centerY+colorboxSize/2];

%% load trial sequences - based on the correct section
load([data_dir '/encoding.mat'],'encodingLists','enc_onsets');

%select the current list:
enc_idx=encodingLists(encodingLists(:,3)==iList,7);
color_col=8;
%enc_idx is a matrixt with
%rows: number of sessions
%columns: order of presenting the stimuli - negative items should be responded
%with "smaller" and positivenumbers with "bigger"

if practice==1
    
    % override number of encoding trials and stim folder
    nReps=1;
    nLists=1;
    
    enc_idx=1:nPracTrials;
    dir_list=dir([project_dir '/practiceEnc']);
    
    % skip stuff that isn't an image
    dir_list = dir_list(3:end);               % skip . & ..
    if (strcmp(dir_list(1).name,'.DS_Store')==1) % also skip .DS_Store
        dir_list = dir_list(2:end);
    end
    
    prac_file_names={};
    % grab some objects
    for f=enc_idx
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

% stupid hack
if practice==1
    idx_to_find=unique(enc_idx);
    enc_texture=zeros(size(enc_idx));
    for i=idx_to_find %the number of the stimuli
        
        %enc_idx is the order of the stimuli
        % match encoding index to the list of all indices for this subject
        %all_idx is an array of numbers - possibly, this is the array that sets
        %which image is "image number x" it is different in each subject
        %takes "image number 1" finds it in loc - say, number 40.
        %temp_idx=all_idx==i;
        
        % read in images in the order of encoding presentation
        temp_image = imread(prac_file_names{i}); %now in temp image, the first 1, there is the 40th image in the folder
        
        % return index of images that can be called by 'DrawTexture'
        enc_texture(enc_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
elseif practice==0
    idx_to_find=unique(enc_idx)';
    enc_texture=zeros(size(enc_idx));
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
        enc_texture(enc_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
end

%% trial onsets and data structures

tpr=length(enc_texture); % trials per run

if debug==0 
    if ~practice %this is not practice
        run_length=enc_onsets(end)+stim_dur+run_decay; %
    elseif practice %this is practice - do not wait the initial 12 secs, just 2
        rand_onsets = ones(1,nPracTrials)*ISI;
        trial_lengths=stim_dur + rand_onsets;
        trial_onsets=cumsum(trial_lengths,2) - (trial_lengths)+2;
        run_length=(stim_dur+ISI)*tpr+run_decay; %
    end
elseif debug==1
    iti=.25 * ones(size(enc_texture));
    trial_lengths=stim_dur + iti;
    trial_onsets=cumsum(trial_lengths,2) - (stim_dur+iti);
    run_length=trial_onsets(end)+stim_dur+run_decay; % end 1 sec after last trial
end


%% run loop
curr_encoding=encodingLists(encodingLists(:,3)==iList,:);
if ~debug
    curr_onsets=enc_onsets;
else
    curr_onsets=trial_onsets;
end

if practice
    curr_onsets=trial_onsets;
    curr_encoding=curr_encoding(1:tpr,:);
    curr_encoding(1:nPracTrials/2,4)=2; %green
    curr_encoding(nPracTrials/2+1:end,4)=1;%red
end

%% show encoding instructions - in the begining of each rep
for i=1:length(instructString)
    tempBounds = Screen('TextBounds',mainWindow,instructString{i});
    Screen('drawtext',mainWindow,instructString{i},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)*numel(instructString)/2+textSpacing*(i-1)),textColor);
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

% fixation until first trial - wait for the back tick
tempBounds = Screen('TextBounds',mainWindow,'+');
Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
clear tempBounds;
Screen('Flip',mainWindow);

%% prepare the place holder for the vrialbes that save what happened in the experiment:
stim_onset=zeros(tpr,1);
response=zeros(tpr,1);
response_times=zeros(tpr,1);
response_pleasentness=zeros(tpr,1);

if practice == 0
    % set up output text file
    data_file=fullfile(data_dir,['encoding_' num2str(subj_num) subj_id '_list' num2str(iList) '_rep' num2str(rep) '.txt']);
    if exist(data_file,'file')
        data_file=[data_file(1:end-4) '1.txt'];
    end
    fid = fopen(data_file, 'w');
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
        'subj', 'init','day','list','rep','eventNum','color','position','trial', 'onset', 'image','resp_bt', 'pleasentness', 'rt');
end

% print header to screen
fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
    'subj', 'init','day','list','rep','eventNum','color','position','trial', 'onset', 'image','resp_bt', 'pleasentness', 'rt');

% set up diagnostic plot
if fMRI==1 || debug==1
    rd = response_diagnostics(response_window, tpr);
end


%wait for the scanner, or not:
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
    
    % gap between trials
    if trial==1
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
    else
        Screen(mainWindow,'FillRect',colormat(curr_encoding(trial-1,color_col),:),colorRect);
        Screen(mainWindow,'FillRect',255,centerRect);
        Screen('Flip',mainWindow);
    end
    % wait for next trial onset - minus the dur_fix_pre
    while GetSecs<runTime+curr_onsets(trial)-dur_fix_pre; end
    
    %present the pre-trial fixation:
    if trial==1
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
    else
        Screen(mainWindow,'FillRect',colormat(curr_encoding(trial-1,color_col),:),colorRect);
        Screen(mainWindow,'FillRect',255,centerRect);
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
    end
    
    % wait for next trial onset
    while GetSecs<runTime+curr_onsets(trial); end
    
    % present images on background
    Screen(mainWindow,'FillRect',colormat(curr_encoding(trial,color_col),:),colorRect);
    Screen(mainWindow,'FillRect',255,centerRect);
    Screen('DrawTexture',mainWindow,enc_texture(trial),imageRect,centerRect);
    stim_start=Screen('Flip',mainWindow);
    stim_onset(trial)=stim_start-runTime;
    
    %  collect reponse
    removed=0;
    FlushEvents('keyDown');
    while GetSecs < stim_start + response_window
        WaitSecs(.0005);
        
        % take down image even if no response yet
        if ~removed && GetSecs >= stim_start + stim_dur
            removed = 1;
            Screen(mainWindow,'FillRect',colormat(curr_encoding(trial,color_col),:),colorRect);
            Screen(mainWindow,'FillRect',255,centerRect);
            Screen('Flip', mainWindow);
        end
        
        % wait for response
        if (response(trial) == 0)
            
            [keyIsDown, secs, keyCode] = KbCheck(device);
            %[keyIsDown, secs, keyCode] = KbCheck();
            if (keyIsDown) && find(keyCode,1) ~= backtick
                
                % record response button and response time
                response(trial) = find(keyCode,1);
                response_times(trial) = secs - stim_start;
                
                % record pleasentness
                if find(keyCode,1) == pleasent
                    response_pleasentness(trial) = 1;
                else
                    response_pleasentness(trial) = 0;
                end
                
            end
        end
    end
    
    % white square until next trial
    if trial==tpr %if it's the last one - don't draw the background color
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
    else
        Screen(mainWindow,'FillRect',colormat(curr_encoding(trial,color_col),:),colorRect);
        Screen(mainWindow,'FillRect',255,centerRect);
    end
    Screen('Flip',mainWindow);
    
    % print output to screen and text file
    fprintf('%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%.3f\n', ...
        subj_num, subj_id, curr_encoding(trial,2), iList, rep, curr_encoding(trial,5), curr_encoding(trial,8), curr_encoding(trial,6), trial, stim_onset(trial), enc_idx(trial), ...
        response(trial), response_pleasentness(trial), response_times(trial));
    
    if practice ==0
        fprintf(fid,'%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%.3f\n', ...
        subj_num, subj_id, curr_encoding(trial,2), iList, rep, curr_encoding(trial,5), curr_encoding(trial,8), curr_encoding(trial,6), trial, stim_onset(trial), enc_idx(trial), ...
        response(trial), response_pleasentness(trial), response_times(trial));
    end
    
    if fMRI==1 || debug==1
        % plot performance and rt ongoing
        rd.log_trial(response_times(trial), 1, response_pleasentness(trial)); %pleasent will be blue, unpleasent in red
    end
end

% wait for scanner to finish
while GetSecs < runTime+run_length; end

if practice==0
    % close this run's text file
    fclose(fid);
end
%% save stuff
if  ~practice
    mat_file=fullfile(data_dir,['encoding_' num2str(subj_num) subj_id '_list' num2str(iList) '_rep' num2str(rep) '.mat']);
    if exist(mat_file,'file')
        mat_file=[mat_file(1:end-4) '1.mat'];
    end
    save(mat_file,'response','response_times','response_pleasentness','stim_onset')
end

%present the great job screen for two seconds:
tempBounds = Screen('TextBounds',mainWindow,progressString{1});
Screen('drawtext',mainWindow,progressString{1},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
clear tempBounds;
Screen('Flip',mainWindow);
while GetSecs < runTime+run_length+btw_runs_time; end


if ~fMRI && practice && length(varargin) == 3%otherwise just continue%otherwise just continue
    ListenChar(0);
    ShowCursor;
    sca
end

% clear screen
%sca
end