function repatimeS_similarity(subj_num, subj_id,part,iList,varargin)
% function encoding(subj_num, subj_initials, fMRI, practice, debug, [mainwindow])
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
    ISI=0.02;
    ITI=0.14;
else
    stim_dur = 1;
    response_window = 1.8;
end

run_delay = 2;
run_decay = 13;
btw_runs_time=2;
%% keyboard and key presses
device=-1;%-1; %allows use all keyboard platforms
KbName('UnifyKeyNames');

if fMRI == 1
    repeat_bt = KbName('6^');
elseif fMRI == 0
    repeat_bt = KbName('h');
end

backtick=KbName('5%');

if ~fMRI
    instructString{1} = 'Immediate repetition task:';
    instructString{2} = 'Press your index finger (''L'')';
    instructString{3} = 'when an object repeats itself back-to-back';
else
    instructString{1} = 'Immediate repetition task:';
    instructString{2} = 'Press your index finger';
    instructString{3} = 'when an object repeats itself back-to-back';
end

%if for some reason running not in the scanner - let the participant know he/she should press "q": 
if ~fMRI && ~practice
    instructString{end+1} = 'Press ''q'' to begin!';
end

if practice==1
    instructString{end+1} = '(practice round)';
end

%end of section:
progressString{1} = 'Great job!';



%% set screen information
backColor = 127;
textColor = 0;
textFont = 'Arial';
textSize = 34;
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
    Screen_X = 640;
    Screen_Y = 480;
else
    % behavioral: run in testing room
    windowIdx=min(screens);
    [Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
%     Screen_X = 640;
%     Screen_Y = 480;
end
centerX = Screen_X/2;
centerY = Screen_Y/2;

% placeholder for images
imageRect = [0,0,imageSize,imageSize];

% position of images
centerRect = [centerX-imageSize/2,centerY-imageSize/2,centerX+imageSize/2,centerY+imageSize/2];

%% load trial sequences
load([data_dir '/similarity'],'similarityList','sim_onsets');

%select the current list:
similarityList=similarityList(similarityList(:,3)==iList,:);
trial_seq=similarityList(:,7);
condition=similarityList(:,11);
sim_idx=trial_seq;
trial_onsets=sim_onsets(iList,:);
n_runs=1;

if practice==1
    
    % override number of encoding trials and stim folder
    n_runs=1;
    temp_enc_idx=randperm(6);
    rep_item=randperm(6);
    rep_item=rep_item(1:2);
    sim_idx=zeros(8,1);
    i=1;
    for trial=1:8
        sim_idx(trial)=temp_enc_idx(i);
        if trial==rep_item(1) || trial==rep_item(2)
        else
            i=i+1;
        end
    end
    
    % skip stuff that isn't an image
    dir_list=dir([project_dir '/practiceSim']);
    dir_list = dir_list(3:end);               % skip . & ..
    if (strcmp(dir_list(1).name,'.DS_Store')==1) % also skip .DS_Store
        dir_list = dir_list(2:end);
    end
    
    prac_file_names={};
    % grab some objects
    for image=1:numel(dir_list)
        prac_file_names{image}=[project_dir '/practiceSim/' dir_list(image).name];
    end
end

%preparing a correct_response array - to be filled in each trial later on
correct_response=condition>1;
response_accuracy=zeros(n_runs,length(trial_seq));

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
    idx_to_find=unique(sim_idx);
    sim_texture=zeros(size(sim_idx));
    for i=1:6 %the number of the stimuli
        
        %enc_idx is the order of the stimuli
        % match encoding index to the list of all indices for this subject
        %all_idx is an array of numbers - possibly, this is the array that sets
        %which image is "image number x" it is different in each subject
        %takes "image number 1" finds it in loc - say, number 40.
        %temp_idx=all_idx==i;
        
        % read in images in the order of encoding presentation
        temp_image = imread(prac_file_names{i}); %now in temp image, the first 1, there is the 40th image in the folder
        
        % return index of images that can be called by 'DrawTexture'
        sim_texture(sim_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
elseif practice==0
    idx_to_find=unique(sim_idx)';
    sim_texture=zeros(size(sim_idx));
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
        sim_texture(sim_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
        %makes an array of images ready to be displayed
        %put in where there is the number "1" in enc_idx, the 40th image in the folder.
        %so, all_idx and he order in which items appear in enc_idx set the
        %randomization
    end
end

%% trial onsets and data structures
if practice==0
    tpr=length(trial_seq); % trials per run
else
    tpr=8;
end

if debug==0 
    if practice==0 %this is not practice
        run_length=trial_onsets(end)+stim_dur+run_decay; %
    elseif practice==1 %this is practice - do not wait the initial 12 secs, just 2
        %override the onsets
        rand_onsets=[1 1 3 5 1 1 3 5 1 3];
        rand_onsets=rand_onsets(randperm(length(rand_onsets)));
        trial_lengths=response_window + rand_onsets;
        trial_onsets=cumsum(trial_lengths,2) - (trial_lengths)+2;
        run_length=trial_onsets(end)+response_window+1; % end 1 sec after last trial
    end
elseif debug==1
    iti=.25 * ones(size(sim_texture));
    trial_lengths=response_window + iti;
    trial_onsets=cumsum(trial_lengths,2) - (response_window+iti);
    run_length=trial_onsets(end)+response_window+1; % end 1 sec after last trial
end

stim_onset=zeros(n_runs,tpr);
response=zeros(n_runs,tpr);
response_times=zeros(n_runs,tpr);
response_accuracy=zeros(n_runs,tpr);
repeat_trial=zeros(n_runs,tpr);
stim_num=zeros(n_runs,tpr);
%% run loop
for rep=startBlock:n_runs
    
    if practice == 0
        % set up output text file
        data_file=fullfile(data_dir,['similarity' part '_' num2str(subj_num) subj_id '_list' num2str(iList) '.txt']);
        if exist(data_file,'file')
            data_file=[data_file(1:end-4) '1.txt'];
        end
        fid = fopen(data_file, 'w');
        fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init', 'day','list','trial', 'onset', 'image', 'condition','repeat_trial', 'resp', 'acc', 'rt');
    end
    
    % print header to screen
    fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init', 'day','list','trial', 'onset', 'image', 'condition','repeat_trial', 'resp', 'acc', 'rt');
    
    % set up diagnostic plot
    if fMRI==1 || debug==1
        rd = response_diagnostics(response_window, tpr);
    end
    
    %% show encoding instructions
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
        %repeat trial?
        if (trial>1) && (sim_texture(trial)==sim_texture(trial-1))
            repeat_trial(rep,trial)=1;
            correct_response=1; %set up for the log
        else
            correct_response=0; %set up for the log
        end
        
        % wait for next trial onset
        while GetSecs<runTime+trial_onsets(trial); end
            
        % present images
        Screen('DrawTexture',mainWindow,sim_texture(trial),imageRect,centerRect);
        stim_start=Screen('Flip',mainWindow);
        stim_onset(rep,trial)=stim_start-runTime;
        stim_num(rep,trial)=sim_idx(trial);
        %  collect reponse
        removed=0;
        FlushEvents('keyDown');
        while GetSecs < stim_start + response_window
            WaitSecs(.0005);
            
            % take down image even if no response yet
            if ~removed && GetSecs >= stim_start + stim_dur
                removed = 1;
                %Screen(mainWindow,'FillOval',fixColor,fixDotRect);
                tempBounds = Screen('TextBounds',mainWindow,'+');
                Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
                clear tempBounds;
                Screen('Flip', mainWindow);
            end
            
            % wait for response
            if (response(rep,trial) == 0)
                
                [keyIsDown, secs, keyCode] = KbCheck(device);
                if (keyIsDown) && find(keyCode,1) ~= backtick
                    
                    % record response button and response time
                    response(rep,trial) = find(keyCode,1);
                    response_times(rep,trial) = secs - stim_start;
                    
                    % record accuracy
                    if (find(keyCode,1) == repeat_bt) && (repeat_trial(rep,trial)==1)%pressed when should
                        response_accuracy(rep,trial) = 1;
                    elseif (find(keyCode,1) == repeat_bt) && (repeat_trial(rep,trial)==0) %pressed when shouldn't
                        response_accuracy(rep,trial) = 2;
                    else %not a repeat trial, or no response:
                        response_accuracy(rep,trial) = 0;
                    end
                    
                end
            end
        end
        
        end_section=GetSecs;
        % fixation until next trial
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
        
        % print output to screen and text file
        fprintf('%d\t%s\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id,similarityList(trial,2),similarityList(trial,3), trial, stim_onset(rep,trial), sim_idx(trial), ...
            condition(trial),repeat_trial(rep,trial),...
            response(rep,trial), response_accuracy(rep,trial), response_times(rep,trial)); %'condition', 'triad', 'loc_in_triad', 'size',
        
        if practice ==0
            fprintf(fid,'%d\t%s\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
                subj_num, subj_id,similarityList(trial,2),similarityList(trial,3),trial, stim_onset(rep,trial), sim_idx(trial), ...
                condition(trial),repeat_trial(rep,trial),...
                response(rep,trial), response_accuracy(rep,trial), response_times(rep,trial)); %'condition', 'triad', 'loc_in_triad', 'size',
        end
        
        if fMRI==1 || debug==1
            % plot performance and rt ongoing
            rd.log_trial(response_times(rep,trial), correct_response, response_accuracy(rep,trial));
        end
        
    end %ends the loop of all trials
    
end %ends the loop of all reps
    
% wait for scanner to finish
while GetSecs < runTime+run_length; end

if practice==0
    % close this run's text file
    fclose(fid);
end


%% clean up and go home
if  practice==0
    mat_file=fullfile(data_dir,['similarity' part '_' num2str(subj_num) subj_id '_list' num2str(iList) '.mat']);
    if exist(mat_file,'file')
       mat_file=[mat_file(1:end-4) '1.mat'];
    end
    save(mat_file,'response','response_times','response_accuracy','stim_onset','condition','repeat_trial','stim_num')
end

%present the great job screen for two seconds:
tempBounds = Screen('TextBounds',mainWindow,progressString{1});
Screen('drawtext',mainWindow,progressString{1},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
clear tempBounds;
Screen('Flip',mainWindow);
while GetSecs < runTime+run_length+btw_runs_time; end


if ~fMRI && practice && length(varargin) == 3%otherwise just continue
    ListenChar(0);
    ShowCursor;
    sca
end

% clear screen
%sca