function do_math_distractor(subj_num,subj_id)
% DO_MATH_DISTRACTOR: code for the math distractor task.
% Note that this was embedded in some Psychtoolbox code
% [~, hostname]=system('hostname');
% if strcmp(hostname(1:6),'joanna')%the hostname command gives 1X7 char output, we only need the first 6.
%     project_dir='/Volumes/Oded/Bein/Repatime/repatime7_3Reps6Col6ItemPerEvent';
% else
%     project_dir='/Volumes/davachilab/Bein/Repatime/repatime7_3Reps6Col6ItemPerEvent';
% end
project_dir='.';
subj_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id));

% set how long we want the distractor, in seconds
dist_total_time = 5*60;

% save an output file of their responses as you go along
fidOutD = fopen('outfiledist.txt','at');
fprintf(fidOutD,'%s\t      %s\t    %s\t        %s\t        %s', ...
    'problem','answer','iscorrect','prestime','resptime');
fprintf(fidOutD,'\n');

%prep_the participant's distractors
make_distractor_sets(subj_num,subj_id);
% load in the file created with make_distractor_sets
load(fullfile(subj_dir,'distractors.mat'));
% set a counter to keep track of which problem the subject is on
dcount = 1;

% set some things for Psychtoolbox
% set the keys to use with responses.
YesResp=KbName('j');
NoResp=KbName('k');
KbName('UnifyKeyNames');

% initialize Psychtoolbox
try
[window, windrect] = Screen('OpenWindow', 0); % set the screen
white=WhiteIndex(window);
Screen('FillRect', window,white); % Colors the entire window white.
priorityLevel=MaxPriority(window);  % get the max available priority for this computer
Priority(priorityLevel); % set the priority to this level, trying to keep Matlab on top

% format the font
Screen('TextFont',window, 'Helvetica'); % set the font
Screen('TextColor',window,[0 0 0]);
 
% get the center point of screen - we'll use this a lot
[cx,cy]=RectCenter(windrect);

% get the start time for the distractor.
dist_start_time = GetSecs;

while (GetSecs-dist_start_time)<= dist_total_time
    resp_num = NaN;

    % set the text size -- I used different sizes for the questions and
    % equations, but obviously feel free to ignore.
    Screen('TextSize',window, 72); 
    
    % draw the answers
    DrawFormattedText(window,'Yes               No','center',cy+135);
    DrawFormattedText(window,'j                 k','center',cy+270);
    
    % draw the questions
    Screen('TextSize',window, 100);
    taskText = sprintf('%i + %i + %i = %i ?',all_equations(dcount,:));
    DrawFormattedText(window,taskText,'center',cy-135);
    
    % initialize key for response
    [~, ~, KeyCode]=KbCheck;
    
    % Show stimulus on screen & record onset time
    stimrt=Screen('Flip', window,0);
    
    % record response if applicable
    responded = false;
    % give them all of the time they want, except if they've run out of time
    while ~responded && ((GetSecs-dist_start_time)<= dist_total_time)
        [~, resprt,KeyCode]=KbCheck; % check to see if they did respond this time
        if any(KeyCode) % if they did press something, then classify
            responded = true;
            [~, resprt, KeyCode]=KbCheck;
            keyresp = KbName(KeyCode);
            if KeyCode(YesResp)|| KeyCode(NoResp)
                switch keyresp
                    case('h')
                        resp_num = 1;
                    case('j')
                        resp_num = 0;
                end
            end % end if for pressing relevant keys or not
        end % end if they pressed anything
    end %while there is still time and they haven't responded
    
    % calculate cumulative timing
    stimtime=stimrt - dist_start_time;
    % if there's no good response - only happens if they run out of time
    if isnan(resp_num)
        resptime = stimtime;
    else
        resptime=resprt - dist_start_time;
    end
    
    fprintf(fidOutD,'%s\t      %i\t     %i\t   %i\t        %i\n',...
        taskText,correct_responses(dcount),...
        isequal(resp_num,correct_responses(dcount)), stimtime, resptime);
    %  'problem','answer','correct','prestime','resptime');
    
    Screen('FillRect', window, white);
    Screen('Flip',window,0);
    
    % if we don't wait between responses, sometimes the keys get stuck (i.e. Psychtoolbox
    % thinks that what was pressed for the previous problem was meant for the current problem, or
    % a subject can just press a single key
    WaitSecs(.4);
    
    dcount = dcount+1;
    
end % distractor time

% if you're applying this code more than once: if you don't update the count again here, 
% it will start with problem they left off with last time
dcount = dcount+1; 

% close the output file
fclose(fidOutD);

catch
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    psychrethrow(psychlasterror);
end

Screen('CloseAll');
ShowCursor;
Priority(0);