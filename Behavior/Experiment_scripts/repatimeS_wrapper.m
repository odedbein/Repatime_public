function repatimeS_wrapper(subj_num,subj_id,day,varargin)
%repatime8 wrapper
%runs a block:
%1. similarity pre
%2. one block of encoding
%3. temporal memory test
%4. 4 more repetitions of encoding
%5. similarity post
%6. match-mismatch task
fMRI=varargin{1};
practice=varargin{2};
debug=varargin{3};

%some ptb stuff:
Priority(0);
Screen('Preference', 'SkipSyncTests', 1 );
Screen('Preference', 'VisualDebugLevel', 1);

%% set up starting points, reps etc.
nRepsEnc=5;
startRep=1;
if strcmp(day,'day1')
    start_list=1;
    nLists=3;
elseif strcmp(day,'day2')
    start_list=4;
    nLists=6;
else
    display('wrong day input');
end

if length(varargin) == 4
start_list=varargin{4};
end

if practice
    nRepsEnc=2;
    start_list=1;
    nLists=1;
end


%% set screen information
screens = Screen('Screens');
backColor = 127;
if fMRI
    % present stimuli in second screen
    windowIdx=1;%max(screens); %in Avi's scripts, the scanner is 1 and debug is 0, so should be fine.
    %[Screen_X, Screen_Y]=Screen('WindowSize',windowIdx);
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

%set up the main window and present a grey screen
if fMRI && ~debug
    mainWindow = Screen(windowIdx,'OpenWindow',backColor,[]);
else
    mainWindow = Screen(windowIdx,'OpenWindow',backColor,[0 0 Screen_X Screen_Y]);
end

Screen(mainWindow,'FillRect',backColor);
Screen('Flip',mainWindow);

%% run the show:
for iList=start_list:nLists
repatimeS_similarity(subj_num, subj_id,'PRE',iList,fMRI,practice,debug,mainWindow);
for iRep=startRep:nRepsEnc
    repatimeS_encoding(subj_num,subj_id,iList,iRep,fMRI,practice,debug,mainWindow);
end
repatimeS_similarity(subj_num, subj_id,'POST',iList,fMRI,practice,debug,mainWindow);

%run match mismatch
repatimeS_matchmis(subj_num,subj_id,iList,fMRI,practice,debug,mainWindow)
end


%experiment ended:
sca % clear screen

if ~debug
    ListenChar(0);
    ShowCursor;
end



    