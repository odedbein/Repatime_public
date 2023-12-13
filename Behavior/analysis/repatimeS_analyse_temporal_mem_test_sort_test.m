function [sorted_RTmemoryTest,sorted_RTmemoryTestOnlyNum]=repatimeS_analyse_temporal_mem_test_sort_test(engram,savefile)
%subjects numbers:  an array of number of the subjects you currently want to analys
%subjects names:    a structure with the names of the subjects, each name in a cell
%can be externally or internally defined

% this script was just used to create the initial data structure. Then,
% used the script 'compile... then stats were done in R
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end
proj_dir=fullfile(mydir,'/Repatime/repatime_scanner/behavior');

results_filename='sorted_RTmemoryTest_outliers_removed_quick100ms_N30';
if savefile
    fprintf('you are saving the results into %s \n',results_filename)
end
%all of them:
%subjects_names={'ZD','RS','BS','GC','MS','PL','IL','BL','CB','AN','GT','MR','DB','VW','RA','AB','SA','MY','JP','SJ','DL','AL','MM','HM','DT','RK','JC','CC','ML','RB','AN','IR'};
%subjects_numbers=[2,3,5:14 16:22 23:26 28:34 36 37];

%subjects I excluded:
%'15CD' - movement
%'27AC' - didn't finish the scan - only 4 scans
%'23SJ' - did very badly on day2
%'29DT' - low memory rates

subjects_names={'ZD','RS','BS','GC','MS','PL','IL','BL','CB','AN','GT','MR','DB','VW','RA','AB','SA','MY','JP','DL','AL','MM','HM','RK','JC','CC','ML','RB','AN','IR'};
subjects_numbers=[2,3,5:14 16:22 24:26 28 30:34 36 37];

total_subj_num=numel(subjects_numbers);

too_quick_resp_thresh=100;
ExcludeOutliers=1;

sorted_RTmemoryTest={};
sorted_RTmemoryTestOnlyNum.rem=nan(numel(subjects_numbers),24,6);
sorted_RTmemoryTestOnlyNum.hc=sorted_RTmemoryTestOnlyNum.rem;
sorted_RTmemoryTestOnlyNum.forg=sorted_RTmemoryTestOnlyNum.rem;
sorted_RTmemoryTestOnlyNum.condition=sorted_RTmemoryTestOnlyNum.rem;
sorted_RTmemoryTestOnlyNum.temporalTestRT=sorted_RTmemoryTestOnlyNum.rem;
sorted_RTmemoryTestOnlyNum.temporalTestOrderAllTrials=sorted_RTmemoryTestOnlyNum.rem;
sorted_RTmemoryTestOnlyNum.temporalTestOrderPerCondition=sorted_RTmemoryTestOnlyNum.rem;

for subj=1:numel(subjects_numbers)
    curr_sub=subjects_numbers(subj);
    subj_name=['S' num2str(curr_sub) subjects_names{subj}];
    fprintf('currently analyzing subject %s \n',subj_name);
    
    %analyze temproal memory
    curr_sub_data=analyze_temporal_mem_test_single_sub(curr_sub,subjects_names{subj},proj_dir,too_quick_resp_thresh,ExcludeOutliers,total_subj_num,subj,sorted_RTmemoryTestOnlyNum);
    sorted_RTmemoryTest.(subj_name)=curr_sub_data;
    sorted_RTmemoryTestOnlyNum.rem(subj,:,:)=curr_sub_data.rem;
    sorted_RTmemoryTestOnlyNum.hc(subj,:,:)=curr_sub_data.hc;
    sorted_RTmemoryTestOnlyNum.forg(subj,:,:)=curr_sub_data.forg;
    %we don't need the condition - but it's good as a check that the code
    %is working
    sorted_RTmemoryTestOnlyNum.condition(subj,:,:)=curr_sub_data.condition;
    sorted_RTmemoryTestOnlyNum.temporalTestRT(subj,:,:)=curr_sub_data.temporalTestRT;
    sorted_RTmemoryTestOnlyNum.temporalTestOrderAllTrials(subj,:,:)=curr_sub_data.temporalTestOrderAllTrials;
    sorted_RTmemoryTestOnlyNum.temporalTestOrderPerCondition(subj,:,:)=curr_sub_data.temporalTestOrderPerCondition;

end

if savefile
    save(fullfile(proj_dir,'analysis',[results_filename '.mat']),'sorted_RTmemoryTest','sorted_RTmemoryTestOnlyNum');
end

end

function curr_sub_data=analyze_temporal_mem_test_single_sub(subj_num,subj_id,project_dir,too_quick_resp_thresh,ExcludeOutliers,total_subj_num,subj,sorted_RTmemoryTestOnlyNum)

data_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id),sprintf('%d%s',subj_num,subj_id));

nLists=6;
start_list=1;
Exclude_SD=3; %exclusion criteria

%prepare the structure per participant
curr_sub_data.rem=nan(24,6);
curr_sub_data.hc=curr_sub_data.rem;
curr_sub_data.forg=curr_sub_data.rem;
curr_sub_data.condition=curr_sub_data.rem;
curr_sub_data.temporalTestRT=curr_sub_data.rem;
curr_sub_data.temporalTestOrderAllTrials=curr_sub_data.rem;
curr_sub_data.temporalTestOrderPerCondition=curr_sub_data.rem;

%outliers marking:
outlierThreshAllLists=zeros(2,nLists);%rows - 1)slow bar, 2)high bar; columns: Lists.
subplot(ceil(sqrt(total_subj_num)),ceil(sqrt(total_subj_num)), subj);
hold on
for l = 1:nLists %for each list
    %first repetition in the current List:
    if ~(subj_num==27 && (l==5 || l==6)) %didn't do these scans (excluded anyway, see above)
        %fileName=['temporal_mem_test_' num2str(subj_num) subj_id '_list' num2str(l) '.mat'];
        fileName=['matchmis_' num2str(subj_num) subj_id '_list' num2str(l) '.mat'];
        curr_part=fullfile(data_dir,fileName);
        load(curr_part);
        RT=response_times;
        
        %find too quick responses - these are mistakes, remove them
        RT=RT*1000;
        RT(response_accuracy==0)=0;
        too_quick=(RT<too_quick_resp_thresh); %this will remove zeros, which are for inaccurate or no responses
        if ~isempty(too_quick)
            RT=RT(~too_quick);
        end
        RT_std=std(RT);
        RT_av=mean(RT);
        
        SlowBar=RT_av+(Exclude_SD*RT_std);
        FastBar=RT_av-(Exclude_SD*RT_std);
        outlierThreshAllLists(1,l)=SlowBar;
        outlierThreshAllLists(2,l)=FastBar;
        
        slow_outliers=find(RT>(RT_av+(Exclude_SD*RT_std)));
        fast_outliers=find(RT<(RT_av-(Exclude_SD*RT_std)));
        outliers=sort([slow_outliers;fast_outliers]);
        
        %scatter plot:
        c=zeros(length(RT),3);
        c(outliers,1)=1; %c is the color in RGB, mark all outliers in R.
        if ~isempty(outliers)
            %display:
            %outliers
            fprintf('\n');
            fprintf('match-mis - outleirs RT list %d: %.0f \n',l,RT(outliers));
        end
        
        scatter(1:length(RT),RT,[],c)
        ylabel('RTs (ms)');
        title([num2str(subj_num) subj_id]);
        
    end
    
end
hold off
RT=[];

for l=start_list:nLists
    
    fileName=['matchmis_' num2str(subj_num) subj_id '_list' num2str(l) '.mat'];
    curr_part=fullfile(data_dir,fileName);
    load(curr_part);
    response_times=response_times*1000;
    
    
    %% analyze
    too_quick=(response_times<too_quick_resp_thresh);%find too quick responses - these are mistakes, remove them from all relevant
    response_accuracy(too_quick)=0;%if by chance they were accurate - remove them from accuracy.
    response_accuracy_forRT=response_accuracy;
    response_times(too_quick)=nan;
    num_cond=length(unique(condition));
    
    if ExcludeOutliers
        response_accuracy_forRT(response_times>outlierThreshAllLists(1,l))=nan;
        response_accuracy_forRT(response_times<outlierThreshAllLists(2,l))=nan;
        response_times(response_times>outlierThreshAllLists(1,l))=nan;
        response_times(response_times<outlierThreshAllLists(2,l))=nan;
    end
    
    %find the order per condition:
    cond_ord=nan(1,17);
    for curr_cond=1:3
        a=find(condition==curr_cond);
        cond_ord(a)=1:numel(a);
    end
    
    %get encoding data:
    enc_data=load(fullfile(data_dir,'encoding.mat'));
    %get the 7th column of the current list. column 3 has the list,
    %column 7 is the item number
    cue_order_enc=enc_data.encodingLists(enc_data.encodingLists(:,3)==l,7);
    sort_enc_ret=nan(24,1);
    for ier=1:numel(cue_num)
        curr_loc=find(cue_order_enc==cue_num(ier));
        sort_enc_ret(curr_loc)=ier;
        if response_accuracy(ier)
            curr_sub_data.rem(curr_loc,l)=1; %otherwise leave NaN
            %place the RT:
            curr_sub_data.temporalTestRT(curr_loc,l)=response_times(ier); %otherwise, they were wrong, leave RT Nan
            if response_conf(ier)
                curr_sub_data.hc(curr_loc,l)=1; %otherwise leave NaN
            end
        else
            curr_sub_data.forg(curr_loc,l)=1; %otherwise leave NaN
        end
        %we don't really need it, but just for fun:
        curr_sub_data.condition(curr_loc,l)=condition(ier);
        
        %trial number during memory test:
        curr_sub_data.temporalTestOrderAllTrials(curr_loc,l)=ier;
        curr_sub_data.temporalTestOrderPerCondition(curr_loc,l)=cond_ord(ier);
    end
        
    
end

end %ends the function for a single participant





