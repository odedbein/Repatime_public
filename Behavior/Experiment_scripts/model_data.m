function [tStat, pValue]=model_data(design,design_conv,tr,hrf,activity)
baseline=100;

num_tryouts=2; %how many different variations of the amplitude and noise rate there will be
num_tryouts=num_tryouts-1;%note that indexes start from zero for convienence of the code,
                          %so to get to the desired number, we need to subtract 1 from num_tryouts.
max_amp=1.5; %set the maximum amplitude
min_amp=1; %set the mininum amplitude
min_noiseSD = 0.2; %set the maximum noiseSD
max_noiseSD = 0.2; %set the minimun noiseSD
driftRate = 0.00; %set the drift rate
VoxErrorBarGap=20; %set the gap between voxels for which the SD error bar will be presented.
%if set to 20, it means that once in every 20 voxels an arror bar will be presented.


%prepare the data set
neuralActivity=[design(:,1)*max_amp design(:,2:end)*min_amp];
% for col=1:6
%     neuralActivity_conv(:,col)=conv(neuralActivity(:,col),hrf);
% end
% neuralActivity_conv=baseline + sum(neuralActivity_conv,2);
neuralActivity=sum(neuralActivity,2);
fmriSignal = baseline + conv(neuralActivity,hrf);
fmriSignal = fmriSignal(1:size(design,1));
%downsample to the TR:
fmriSignal=fmriSignal(1:(tr/0.5):end,:);

% Make a time series of "images", each with 2000 voxels, half of which will be
% activated and the other half not activated:
nTime = length(fmriSignal);
% Fill nonactive voxels with baseline image intensity
nonactiveVoxels = baseline * ones(nTime,1000);
% Fill active voxels, each with a copy of fmriSignal
activeVoxels = repmat(fmriSignal(:),[1,1000]);

% put the two together, one above the other
data = [activeVoxels nonactiveVoxels]; %so each voxel is a column
% The result is a 2d array: nTimePoints x nVoxels
%size(data);

% add drift
for t_point=1:nTime
    data(t_point,:) = data(t_point,:) + t_point*driftRate;
end

%Column 1-6: the conditions
model=design_conv(1:(tr/0.5):end,:);
%% Column 7: linear drift.
modelDrift = [1:nTime];
% Column 8: constant, baseline image intensity.
modelConstant = ones(1,nTime)';

% Build the design matrix by putting the columns together:
model = [model modelDrift(:) modelConstant(:)];
%model = [model modelConstant(:)];

modelInv = pinv(model); %we'll need that for later

reg_num=size(model,2);
n=0;
%for n=0:num_tryouts %noise variations
    % add noise
    noiseSD = min_noiseSD+((max_noiseSD-min_noiseSD)*(n/num_tryouts));
    noise = noiseSD * randn(size(data));
    data = data + noise;
    
    % Now estimate b (the beta weights), together with the SDs.
    nVoxels = size(data,2);
    b = zeros(reg_num,nVoxels);
    bmin = zeros(reg_num,nVoxels);
    bmax = zeros(reg_num,nVoxels);
    for voxel=1:nVoxels
        [btmp,bint,r,rint,stats] = regress(data(:,voxel),model,0.05);
        b(:,voxel) = btmp;
        bmin(:,voxel) = bint(:,1);
        bmax(:,voxel) = bint(:,2);
    end
    
    % Plot the parameter estimates (from every VoxErrorBarGap-th voxel) with error bars
    subVox = [1:VoxErrorBarGap:nVoxels];
    figure;
    %subplot((num_tryouts+1)^2,3,1);
    hold on
    for i=1:6
        errorbar(subVox,b(i,subVox),b(i,subVox)-bmin(i,subVox),bmax(i,subVox)-b(i,subVox));
    end
    set(gca,'xlim',[-20 2000]);
    set(gca,'ylim',[0-(max_noiseSD*2),(activity(1)+(max_noiseSD*2))]);
    %set(gca,'ylim',[-1.5,1.5]);
    title(sprintf('Amplitude: %0.1f, noise SD: %0.1f',activity(1)/activity(2),noiseSD))
    ylabel('Amplitude (arb units)');
    xlabel('voxel #');
    hold off;
    
    %%% Residuals and noise estimation
    modelPredictions = model * b;
    residuals = (data - modelPredictions);
    residualSD = std(residuals);
    residualVar = residualSD.*residualSD;
    c = [1 -1 0 0 0 0 0 0]'; %residualSD is a 1 dim vec, but the model inv is 3 rows. so this is to select just the first
    
    % Compute the parameter SD for each voxel:
    bSD = zeros(size(residualSD));
    for voxel=1:nVoxels
        bSD(voxel) = sqrt(c' * modelInv * modelInv' * c * residualVar(voxel));
    end
    con=(c'*b);
    tStat = con./bSD;
    pValue = 1-tcdf(tStat,117);
    
    % Plot 'em
    figure;
    %subplot((num_tryouts+1)^2,3,((amp*(num_tryouts+1)+(n+1)-1)*3)+2);
    plot(tStat);
    title('T statistic')
    ylabel('T value')
    xlabel('Position (voxel #)')
    figure;
    plot(pValue);
    title('P value')
    ylabel('P value')
    xlabel('Position (voxel #)')
    
%end %ends the loop for noise variations

end

