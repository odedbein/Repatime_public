function make_distractor_sets(subj_num,subj_id)
rand('state',sum(100.*clock));%solve the randperm problem in matlab from being consistent
% [~, hostname]=system('hostname');
% if strcmp(hostname(1:6),'joanna')%the hostname command gives 1X7 char output, we only need the first 6.
%     project_dir='/Volumes/Oded/Bein/Repatime/repatime7_3Reps6Col6ItemPerEvent';
% else
%     project_dir='/Volumes/davachilab/Bein/Repatime/repatime7_3Reps6Col6ItemPerEvent';
% end
project_dir='.';
scripts_dir='scripts';
scritps_dir=fullfile(project_dir,scripts_dir);
subj_dir=fullfile(project_dir,'data',sprintf('%d%s',subj_num,subj_id));
if ~exist(subj_dir), mkdir(subj_dir); end

% MAKE_DISTRACTOR_SETS
% make sets of distractor math problems with 3 numbers and one possible answer. 
% It's split between having about half as true and half as false. 
% Of the false, half are the correct answer + 1,
% half are the correct answer - 1.

% set up all possibilities, then randomize 3x.
% set the mininum and maximum possible number to use, as well use these
% several times below.
min_num = 1;
max_num = 9;
% set the number of numbers used in each question.
nproblems = (max_num-min_num+1)^3;
all_problems_ordered = zeros(nproblems,3);

% set up all possible orderings of numbers for each position in the
% equation: each column of all_problems_ordered corresponds to one number in the
% equation.
all_problems_ordered(:,1) = repmat((min_num:max_num)',max_num^2,1);
temp2 = repmat((min_num:max_num)',1,max_num)';
all_problems_ordered(:,2) = repmat(temp2(:),max_num,1);
temp3 = repmat((min_num:max_num)',1,max_num^2)'; 
all_problems_ordered(:,3) = temp3(:);

% set up answers.
all_answers_ordered = sum(all_problems_ordered,2);

% randomize problem/answer order, as well as which are true/false, and if
% the latter +1/-1.
% NOTE: all_responses is the T/F expected response, whereas all_solutions is the
% actual numerical answer, which we'll need to set the test responses.
response_set = [zeros(ceil(.5*nproblems),1); ...
    ones(floor(.25*nproblems),1); -1*ones(floor(.25*nproblems),1)];

% make a randomized order of all of the problems
randomized_rows_for_probs = randperm(nproblems);

% set the correct answers accordingly
all_answers_random = all_answers_ordered(randomized_rows_for_probs);

% randomly generate where the solutions are correct, or +/- 1 of the correct
all_diffs_random = response_set(randperm(nproblems));

% set the equations based on the randomized order:
all_equations = zeros(nproblems,4);
all_equations(:,1:3) = all_problems_ordered(randomized_rows_for_probs,:);

% set the equation solution: 
% for each row, the answer is just the actual answer +/0 difference.
all_equations(:,4)=all_answers_random + all_diffs_random;

% the true/false response is simply whether the difference is 0 or not.
correct_responses = all_diffs_random == 0;
    
% save this somewhere...
save([subj_dir '/distractors.mat'],'all_equations','correct_responses');