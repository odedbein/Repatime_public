function repatimeS_color(subj_num, subj_id, varargin)
% function recognition(subj_num, subj_initials, fMRI, debug)
% Inputs:
%   subjectNumber: start first subject as 1, used to counterbalance button
%                       box response mappings (integer)
%   subj_initials:      subject initials, used to write output file names (string)
%   fMRI:               [0 / 1] looks for scanner pulse/trigger if fMRI,
%                       restricts KbCheck to button box
%   debug:              [0 / 1] if debug, not whole screen

%% boiler plate

fMRI=varargin{1};
practice=varargin{2};
debug=varargin{3};

if length(varargin) == 4
    startRun=varargin{4};
else
    startRun=1;
end

if ~debug;
    ListenChar(2);
    HideCursor;
end

Priority(0);
Screen('Preference', 'SkipSyncTests', 1 );
Screen('Preference', 'VisualDebugLevel', 1);

%% paths
project_dir='.';
%addpath(fullfile(project_dir,'scripts'))
stim_dir=fullfile(project_dir,'images');
data_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id));


if ~exist(data_dir,'dir')
    correct_part='n';
    while correct_part=='n'
        prompt='data_dir does not exist, are you sure you''re running the correct section?[y/terminate]';
        correct_part=input(prompt,'s');
    end
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
%% experiment parameters
% stimulus and sequence info loaded in from encoding task


if practice
    run_delay = 1;
    run_decay = 1;
    nPracTrials=5;
else
    run_delay = 2;
    run_decay = 12;
end

btw_runs_time = 2;
% end
if debug
    stim_dur = 0.1;           %sec
    response_window = 0.2;    %sec
    run_delay = 2;
    run_decay = 2;
    arrow_dur=0.1;
else
    stim_dur = 3;           %sec - will be self paced - that' the maximum time
    response_window = 6;    %sec
    arrow_dur=1;
end

%% keyboard and key presses

device=-1; %allows use all keyboard platforms
KbName('UnifyKeyNames');

if fMRI
    instructString{1} = 'Color memory task: In which color background did the object appear?';
    instructString{2} = 'The object will appear first. Try to recall the background color.';
    instructString{3} = 'After 3 seconds, the object will disappear';
    instructString{4} = 'and the color options will appear on the screen.';
    instructString{5} = 'Choose one of the colors appearing on the screen by pressing';
    instructString{6} = 'your index, middle or ring finger of either the right or left hand';
    instructString{7} = 'Try your best to remember the color.';
    instructString{8} = 'If you cannot remember, don''t press anything';
    instructString{9} = 'Between trials you''ll see arrows, just as before.';
    instructString{10} = 'Please respond with your right/left index finger';
    instructString{11} = 'to indicate the direction of the arrows';
else
    instructString{1} = 'Color memory task: In which color background did the object appear?';
    instructString{2} = 'The object will appear first. Try to recall the background color.';
    instructString{3} = 'After 3 seconds, the object will disappear';
    instructString{4} = 'and the color options will appear on the screen.';
    instructString{5} = 'Choose one of the colors appearing on the screen by pressing';
    instructString{6} = 'the keys: D,F,G,J,K,L';
    instructString{7} = 'Try your best to remember the color.';
    instructString{8} = 'If you cannot remember, don''t press anything';
    instructString{9} = 'Between trials you''ll see arrows, just as before.';
    instructString{10} = 'Please respond with your right/left index finger';
    instructString{11} = 'Press ''q'' to begin!';
end

if practice == 1
    instructString{end+1} = '(practice)';
end

% instructions to get the experimenter at the end
if fMRI==0
    progressString{1} = 'Great job!';
    progressString{2} = 'Please find the experimenter in the other room.';
elseif fMRI==1
    progressString{1} = 'Great job!';
end

%% set screen information
backColor = 128;
textColor = 0;
textFont = 'Arial';
textSize = 34; %change here for larger fixations, arrows and begining text.
color_text_size=28; %text size of the colors
textSpacing = 38;
imageSize=350; % assumed square
screens = Screen('Screens');
gap=40;%set the gap between the color options and the "don't know"


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

end
centerX = Screen_X/2;
centerY = Screen_Y/2;

% position of images
centerRect = [centerX-imageSize/2,centerY-imageSize/2,centerX+imageSize/2,centerY+imageSize/2];

% placeholder for images
imageRect = [0,0,imageSize,imageSize]; %x1,y1,x2,y2


%% load images

% load priming trial sequences
load([data_dir '/color_test.mat'],'ColorTestList','color_onsets','color_keys');
nRuns=size(color_onsets,1);

% set the color keys and text:
color_names={'red','green','blue','yellow','orange','magenta'};
color_txt=[color_names{color_keys(1)} '   /   ' color_names{color_keys(2)} '   /   ' color_names{color_keys(3)} '          /          ' color_names{color_keys(4)} '   /   ' color_names{color_keys(5)} '   /   ' color_names{color_keys(6)}];
keys=zeros(numel(color_names),1);
if ~fMRI
    keys(1) = KbName('d');
    keys(2) = KbName('f');
    keys(3) = KbName('g');
    keys(4) = KbName('j');
    keys(5) = KbName('k');
    keys(6) = KbName('l');
    %space_key=KbName('space');
    
    left_arrow = KbName('g');
    right_arrow = KbName('j');
else
    keys(1) = KbName('8*'); %should be left hand
    keys(2) = KbName('7&'); %should be left hand
    keys(3) = KbName('6^'); %should be left hand
    keys(4) = KbName('1!'); %should be right hand
    keys(5) = KbName('2@'); %should be right hand
    keys(6) = KbName('3#'); %should be right hand
    
    left_arrow = KbName('1!');
    right_arrow = KbName('6^');
end

backtick=KbName('5%');
% create main window
if fMRI && ~debug
    mainWindow = Screen(windowIdx,'OpenWindow',backColor,[]);
else
    mainWindow = Screen(windowIdx,'OpenWindow',backColor,[0 0 Screen_X Screen_Y]);
end
Screen(mainWindow,'TextFont',textFont);
Screen(mainWindow,'TextSize',textSize);

%% practice
if practice==1
    
    % override number of encoding trials and stim folder
    nRuns=1;
    
    dir_list=dir([project_dir '/PracticeEnc']);
    
    % skip stuff that isn't an image
    dir_list = dir_list(3:end);               % skip . & ..
    if (strcmp(dir_list(1).name,'.DS_Store')==1) % also skip .DS_Store
        dir_list = dir_list(2:end);
    end
    
    prac_file_names={};
    % grab some objects
    rand_prac=(randperm(nPracTrials));
    for f=1:nPracTrials
        prac_file_names{f}=[project_dir '/PracticeEnc/' dir_list(rand_prac(f)).name];
    end
    
end

%% run each priming section:
for run=startRun:nRuns
    load([data_dir '/color_test.mat'],'ColorTestList','color_onsets','color_keys');
    ColorTestList=ColorTestList(ColorTestList(:,10)==run,:);
    color_onsets=color_onsets(run,:);
    
    %load the sequences:
    trial_seq=ColorTestList(:,7);
    trial_onsets=color_onsets;
    run_length=trial_onsets(end)+response_window+run_decay; % end 1 sec after last trial
    %re-set the onsets if debug/practice
    if debug
        iti=.25 * ones(size(trial_seq));
        trial_lengths=response_window + iti;
        trial_onsets=cumsum(trial_lengths,2) - (response_window+iti);
        run_length=trial_onsets(end)+response_window+1; % end 1 sec after last trial
    else
        if practice %this is practice - do not wait the initial 12 secs, just 2
            %override the onsets
            trial_onsets=trial_onsets(1:nPracTrials)-10; %to use the made onsets, but not wait 12 secs
            run_length=trial_onsets(end)+stim_dur+1; % end 1 sec after last trial
        end
        
    end

    if practice==1
        prac_idx=1:nPracTrials;
        idx_to_find=unique(prac_idx);
        color_texture=zeros(size(prac_idx));
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
            color_texture(prac_idx==i) = Screen('MakeTexture',mainWindow,temp_image);
            %makes an array of images ready to be displayed
            %put in where there is the number "1" in enc_idx, the 40th image in the folder.
            %so, all_idx and he order in which items appear in enc_idx set the
            %randomization
        end
        
        %these are unecessary in the practice, they are here only so that
        %the script won't break
        %preparing a stimuli size array
        color_sequence=trial_seq;
    else %not practice
        %grab currtn trial sequence, response,condition:
        color_sequence=trial_seq;
        color_texture=zeros(size(color_sequence));
        for i=1:length(color_sequence)
            image_num=color_sequence(i);
            % read in images in the order of encoding presentation
            temp_image = imread(file_names{image_num}); %now in temp image, the first 1, there is the 40th image in the folder

            % return index of images that can be called by 'DrawTexture'
            color_texture(color_sequence==image_num) = Screen('MakeTexture',mainWindow,temp_image);

        end
    end

    %% trial onsets and data structures
    tpr=length(color_texture);
%     trial_lengths=response_window + iti;
%     trial_onsets=run_delay + cumsum(trial_lengths) - trial_lengths;
    stim_onset=zeros(tpr,1);
    response_accuracy=zeros(tpr,1);
    response_times=zeros(tpr,1);
    response=zeros(tpr,1);
    response_loc=zeros(tpr,1);
    response_color=zeros(tpr,1);
    %just for convenience, pull the encoding and retrieval details
    background_color=ColorTestList(:,8);
    OtherList=zeros(length(background_color),1);
    OtherList(mod(background_color,2)==1)=background_color(mod(background_color,2)==1)+1;
    OtherList(mod(background_color,2)==0)=background_color(mod(background_color,2)==0)-1;
    event_position=ColorTestList(:,6);
    eventNum=ColorTestList(:,5);
    listNum=ColorTestList(:,3);
    boundary_condition=ColorTestList(:,6)==1;
    dayNum=ColorTestList(:,2);
    
    %set up variables for the arrows file
    arrows_resp=[];
    arrows_resp_time=[];
    arrows_resp_accuracy=[];
    arrows_RL=[];%was the arrow to the left or right
    arrows_switch=[];%was there a switch
    arrows_trial=[];%which trial in match/mis
    arrows_onset=[];
    arrows_event_position=[];
    arrows_background_color=[];
    arrows_boundary_condition=[];
    arrows_day=[];
    arrows_list=[];
    
    % set up diagnostic plot
    if fMRI==1 || debug==1
        rd = response_diagnostics(response_window, tpr);
    end

    % set up output text file
    if practice==0
        data_file=fullfile(data_dir,['colorTest_' num2str(subj_num) subj_id '_run'  num2str(run) '.txt']);
        if exist(data_file,'file')
            data_file=[data_file(1:(end-4)) '1.txt'];
        end
        fid = fopen(data_file, 'w');
        
        fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj','init','block', 'trial', 'onset', 'image','day', 'list', 'eventNum','event_position','bg_color','OtherList_color','boundary','resp','response_loc','response_color','acc', 'rt');
        
        % set up output text file - arrows
        data_file=fullfile(data_dir,['arrows_colorTest_' num2str(subj_num) subj_id '_run'  num2str(run) '.txt']);
        if exist(data_file,'file')
            data_file=[data_file(1:end-4) '1.txt'];
        end
        fid_arrows = fopen(data_file, 'w');
        fprintf(fid_arrows,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init','day','list','block','trial', 'onset','event_position','bg_color','boundary','switch','left/right','resp', 'acc','rt');
    end
    % print header to screen
    fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subj', 'init', 'block', 'trial', 'onset', 'image','day', 'list', 'eventNum','event_position','bg_color','OtherList_color','boundary','resp','response_loc','response_color','acc', 'rt');

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
        
        % wait for next trial onset minus 1 sec
        while GetSecs<runTime+trial_onsets(trial)-1; end
        
        %draw fixation until the next trial
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
        % wait for next trial onset
        while GetSecs<runTime+trial_onsets(trial); end
        
        % present images
        Screen('DrawTexture',mainWindow,color_texture(trial),imageRect,centerRect);
        stim_start=Screen('Flip',mainWindow);
        stim_onset(trial)=stim_start-runTime;
        WaitSecs(stim_dur);
        
        Screen(mainWindow,'TextSize',color_text_size); %change the ext size
        tempBounds = Screen('TextBounds',mainWindow,color_txt);
        Screen('drawtext',mainWindow,color_txt,round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        tempBounds = Screen('TextBounds',mainWindow,'don''t know --');
        Screen('drawtext',mainWindow,'don''t know  --',round(centerX-tempBounds(3)/2),round(centerY+(gap*2)-tempBounds(4)/2),textColor);
        
        Screen('Flip',mainWindow); 
        Screen(mainWindow,'TextSize',textSize);  %change the text size back to defoult
        %  collect reponse
        
        FlushEvents('keyDown');
        while (GetSecs < stim_start + response_window)
            WaitSecs(.0005);
            
            % take down image even if no response yet
            if GetSecs >= (stim_start + response_window) %response window is 6 sec
                
                tempBounds = Screen('TextBounds',mainWindow,'+');
                Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
                clear tempBounds;
                Screen('Flip', mainWindow);
            end
            
            % wait for response
            %if response(trial) == 0
                
                [keyIsDown, secs, keyCode] = KbCheck(device);
                if (keyIsDown) && find(keyCode,1) ~= backtick
                    
                    % record response button, response time
                    response(trial) = find(keyCode,1);
                    response_times(trial) = secs - stim_start;
                    switch find(keyCode,1)
                        case keys(1)
                             response_loc(trial)=1;
                        case keys(2)
                             response_loc(trial)=2;
                        case keys(3)
                             response_loc(trial)=3;
                        case keys(4)
                             response_loc(trial)=4;
                        case keys(5)
                             response_loc(trial)=5;
                        case keys(6)
                             response_loc(trial)=6;
                    end
                    % set up the color
                    if response_loc(trial)==0
                        response_color(trial)=0;
                    else
                        response_color(trial)=color_keys(response_loc(trial));
                    end
                    % record accuracy
                    if response_color(trial) == background_color(trial) %the target
                        response_accuracy(trial) = 3;
                    elseif response_color(trial) == OtherList(trial) %the other color in the list
                        response_accuracy(trial) = 2;
                    elseif response_color(trial) == 0
                        response_accuracy(trial) = 0;
                    else
                        response_accuracy(trial) = 1; %gave a response, but not the correct one
                    end
                    
                end
            %end
        end
        
        % print output to screen and text file
        fprintf('%d\t%s\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, run, trial, stim_onset(trial), color_sequence(trial),dayNum(trial),listNum(trial),eventNum(trial),event_position(trial),background_color(trial),OtherList(trial),boundary_condition(trial),...
            response(trial),response_loc(trial), response_color(trial), response_accuracy(trial), response_times(trial));
        
        if ~practice
            fprintf(fid,'%d\t%s\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
            subj_num, subj_id, run, trial, stim_onset(trial), color_sequence(trial),dayNum(trial),listNum(trial),eventNum(trial),event_position(trial),background_color(trial),OtherList(trial),boundary_condition(trial),...
            response(trial),response_loc(trial), response_color(trial), response_accuracy(trial), response_times(trial));
        end
        
        %plot performance and rt ongoing
        if fMRI==1 || debug==1
            rd.log_trial(response_times(trial), 1, 1); %I want to see that they respond and RTs very easily, but don't tell me if they're right or wrong
        end
         %% start the arrows - until the next trial - minus one sec after and one before
        if trial~=tpr %not the last trial
            num_arrows=(trial_onsets(trial+1)-trial_onsets(trial)-response_window-1);
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
                
                arrows_trial(end+1)=trial;
                arrows_onset(end+1)=stim_start-runTime;
                arrows_event_position(end+1)=event_position(trial);
                arrows_background_color(end+1)=background_color(trial);
                arrows_boundary_condition(end+1)=boundary_condition(trial);
                arrows_day(end+1)=dayNum(trial);
                arrows_list(end+1)=listNum(trial);
    
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
                
                if ~practice
                fprintf(fid_arrows,'%d\t%s\t%d\t%d\t%d\t%d\t%.3f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f\n', ...
                         subj_num, subj_id, dayNum(trial),listNum(trial),run,arrows_trial(end),arrows_onset(end),arrows_event_position(trial),arrows_background_color(trial),arrows_boundary_condition(trial),...
                         arrows_switch(end),right_left(rl),arrows_resp(end),arrows_resp_accuracy(end),arrows_resp_time(end));
                end

            end
        end 
        
        % fixation until next trial
        tempBounds = Screen('TextBounds',mainWindow,'+');
        Screen('drawtext',mainWindow,'+',round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
        clear tempBounds;
        Screen('Flip',mainWindow);
       
    end %ends all the trials
    
    
    % wait for scanner to finish
    if  ~practice
        while GetSecs < runTime+run_length; end
        
        %save color test output
        mat_file=fullfile(data_dir,['colorTest_' num2str(subj_num) subj_id '_run'  num2str(run) '.mat']);
        if exist(mat_file,'file')
            mat_file=[mat_file(1:end-4) '1.mat'];
        end
        save(mat_file,'response','response_times','response_loc','response_accuracy','stim_onset','color_sequence','listNum','eventNum','event_position','background_color','OtherList','boundary_condition','response_color','ColorTestList','color_onsets');
        % close this run's text file
        fclose(fid);
        
         %save arrows output
        mat_file=fullfile(data_dir,['arrows_colorTest_' num2str(subj_num) subj_id '_run'  num2str(run) '.mat']);
        if exist(mat_file,'file')
            mat_file=[mat_file(1:end-4) '1.mat'];
        end
        
        save(mat_file,'arrows_trial','arrows_onset','arrows_switch','arrows_RL','arrows_resp','arrows_resp_accuracy','arrows_resp_time',...
                      'arrows_event_position','arrows_background_color','arrows_boundary_condition','arrows_day','arrows_list');
        % close this run's text file
        fclose(fid_arrows);
    end
    
    %present the great job screen for two seconds:
    tempBounds = Screen('TextBounds',mainWindow,progressString{1});
    Screen('drawtext',mainWindow,progressString{1},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)/2),textColor);
    clear tempBounds;
    Screen('Flip',mainWindow);
    while GetSecs < runTime+run_length+btw_runs_time; end
end %end all runs

%% clean up and go home
if ~practice && ~fMRI
    
    %% show instructions to get experimenter
    for i=1:length(progressString)
        tempBounds = Screen('TextBounds',mainWindow,progressString{i});
        Screen('drawtext',mainWindow,progressString{i},round(centerX-tempBounds(3)/2),round(centerY-tempBounds(4)*numel(instructString)/2+textSpacing*(i-1)),textColor);
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

if ~debug
    ListenChar(0);
    ShowCursor;
end

% clear screen
sca
end