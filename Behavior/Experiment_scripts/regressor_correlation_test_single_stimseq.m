% convolve regressors with HRF and assess collinearity

% define an HRF curve for a given TR
TP = 0.5; %seconds - not really TR, the time gaps in the jittering
hrf = spm_hrf(TP);

%load('example_stim_sequence') % run by numStims: each stimulus represented by a unique number
%load('example_jitter_sequence') % run by numStims: intertrial intervals (in seconds) before each stim
load('SEL1_jitter_sequence'); % run by numStims: intertrial intervals (in seconds) before each stim
%load('SEL1_stimuli_sequence.mat');
% test on first run
%stim_sequence=stim_sequence(1,:);
%jitter_sequence=jitter_sequence(1,:);
jitter_sequence=jitter_optseq2';
ngood=1;

%stim_sequence=[randperm(72) randperm(72) randperm(72)];
stim_sequence=stimuli_optseq2';

labels = unique(stim_sequence);
numRegs = length(labels);
stimDuration = 1; % duration of each stimulus
numTPs = sum(jitter_sequence+stimDuration)/TP;

% convert to binary format
regressors=zeros(numRegs,numTPs);
for reg = 1:numRegs
    inds=find(stim_sequence==labels(reg));
    for i = 1:length(inds)
        regressors(reg,sum(jitter_sequence(1:(inds(i)-1))+stimDuration)/TP+1)=1;
    end
end

% convolve regressors with HRF
conv_regressors = NaN(numRegs,numTPs);
for reg = 1:numRegs
    convolution = conv(regressors(reg,:),hrf);
    conv_regressors(reg,:) = convolution(1:numTPs); % truncate
end

figure(1)
subplot(1,2,1)
imagesc(conv_regressors);
title('Convolved regressors')
ylabel('regressor')
xlabel('TRs')

%compute correlation between regressors
 correlations = corr(conv_regressors');
subplot(1,2,2)
 abovediag=triu(ones(numRegs));
 correlations(abovediag>0)=0;
imagesc(correlations);
title('Regressor correlations')
ylabel('regressor')
xlabel('regressor')
colorbar

% check if largest correlation is less than .3
max_corr=max(max(abs(correlations)));

disp(['max correlation: ' num2str(max_corr)]); 
if max_corr<.3
    disp('You are good to go! Your regressors are sufficiently uncorrelated.');
    f=find(abs(tril(correlations,-1)));
    mean_corr=mean(abs(correlations(f)));
    stim_seq(ngood,:)=[stim_sequence mean_corr max_corr];
    corr_reg(:,:,ngood)=correlations;
    ngood=ngood+1;
else
    disp('WARNING! Your regressors are too correlated!');
end
