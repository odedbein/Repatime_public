function ResultsEncSimOnlyNum=vector_like_analysis_encoding_anatomical_raw_data(engram)

warning('off','all')
cwd=pwd;
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end

proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');


%THIS HAS ALL IN THE STUDY:
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL',...
    '10BL','11CB','12AN','13GT','14MR','16DB','17VW','18RA','19AB',...
    '20SA','21MY','22JP','24DL','25AL','26MM','28HM',...
    '30RK','31JC','32CC','33ML','34RB','36AN','37IR'};


%subjects={'21MY'};
task='encoding';
smoothing='no_smooth';
modeling='filtered100s_mtc_clean_mc_wmcsf_3sphere';
remove_vox=1;

TRs={'thirdTR'};
results_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling);
results_dir=fullfile(results_dir,'voxel_removed');

if ~exist(results_dir)
    mkdir(results_dir);
end

reg_mat_dir=fullfile(proj_dir,'results',task,'rsa',smoothing,modeling,'regions_matfiles');
behav_dir=fullfile(proj_dir,'behavior','data');

%choose regions:
region='hipp_all'; %'hipp_subreg'
region_subj='hipp'; %for each sub, it's still all hipp regions together
results_filename=fullfile(results_dir,[ region '_encoding_vector_analysis_' modeling '.mat']);
if strcmp(region,'hipp_all')
    reg_names={...
        'fs_hippFromSF_noHATA',...%1
        'fs_rhippFromSF_noHATA',...%2
        'fs_lhippFromSF_noHATA',...%3
        'fs_hippFromSF_noHATA_ant',...%4
        'fs_rhippFromSF_noHATA_ant',...%5
        'fs_lhippFromSF_noHATA_ant',...%6
        'fs_hippFromSF_noHATA_mid',...%7
        'fs_rhippFromSF_noHATA_mid',...%8
        'fs_lhippFromSF_noHATA_mid',...%9
        'fs_hippFromSF_noHATA_post',...%10
        'fs_rhippFromSF_noHATA_post',...%11
        'fs_lhippFromSF_noHATA_post',...%12
        };
elseif strcmp(region,'hipp_subreg')
    reg_names={...
        
        'fs_ca1_025',...
        'fs_rca1_025',...
        'fs_lca1_025',...
        'fs_ca23_025',...
        'fs_rca23_025',...
        'fs_lca23_025',...
        'fs_dg_025',...
        'fs_rdg_025',...
        'fs_ldg_025',...
        };

end %ends the regions condition


num_trials=24;
num_lists=6;
num_reps=5;
Exclude_SD=3;
%% prepare the structures and headers:
ResultsEncSimOnlyNum={};

%% by TRs
for tr=1:numel(TRs)
    for reg=1:numel(reg_names)
        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.norm_diff=nan(numel(subjects),num_trials,num_trials,num_reps,num_lists);
        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.abs_norm_diff=nan(numel(subjects),num_trials,num_trials,num_reps,num_lists);
        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.ndp=nan(numel(subjects),num_trials,num_trials,num_reps,num_lists);
        
    end %ends the regions loop
end %ends the choose TR loop


%% actually analyze the data:
for subj=1:numel(subjects)
    fprintf('analyzing subj %s\n',subjects{subj});
    %load the data:
    load(fullfile(reg_mat_dir,[ region_subj '_data_' subjects{subj} '.mat']),'reg_data');
        
    for l=1:num_lists
        %% break by the different TRs
        for tr=1:numel(TRs)
            for reg=1:numel(reg_names)
               
                %pull the data and remove outliers:
                curr_data_temp=reg_data.(TRs{tr}).(reg_names{reg});
                curr_data_temp=reshape(curr_data_temp,[size(curr_data_temp,1)*size(curr_data_temp,2)*size(curr_data_temp,3)*size(curr_data_temp,4),1]);
 
                t_std=nanstd(curr_data_temp);
                t_av=nanmean(curr_data_temp);
                curr_data=reg_data.(TRs{tr}).(reg_names{reg});
                curr_data(curr_data > t_av+(Exclude_SD*t_std))=nan;
                curr_data(curr_data < t_av-(Exclude_SD*t_std))=nan;
           
                for r=1:num_reps
                    
                    %take the data of the current rep
                    data=squeeze(curr_data(:,:,l,r)); %get the data of the current region, in the current list and repetition
                    if size(data,2) ~= num_trials
                        fprintf('subj %s reg %s list %d part %d has more or less then 24 columns, check \n',subjects{subj},reg_names{reg},l,r);
                    end
                    if (size(data,1) <= 10) %
                        fprintf('subj %s reg %s list %d part %d has 10 voxels or less, excluded \n',subjects{subj},reg_names{reg},l,r)
                    else
                        
                        %calculate the vector norm: %vecnorm does not
                        %exclude nans... so we'll have to go column by
                        %column
                        mat_norm=nan(1,num_trials);
                        for tt=1:num_trials
                            curr_vec=data(~isnan(data(:,tt)),tt);
                            mat_norm(tt)=norm(curr_vec);
                        end
                        mat_norm_diff=mat_norm-mat_norm'; %this one goes by the columns so in this matrix,
                        %the value in row3 col1 is item1 minus item3.
                        
                        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.norm_diff(subj,:,:,r,l)=mat_norm_diff;
                        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.abs_norm_diff(subj,:,:,r,l)=abs(mat_norm_diff);
                        
                        %now calculate the NDP btw two vectors:
                        %(NDP: normalized dot product).
                        mat_ndp=nan(num_trials);
                        for tt=1:num_trials
                            for tt2=(tt+1):num_trials
                                %exclude Nans from both based on either:
                                vecs=data(:,[tt,tt2]);
                                vecs=vecs(~isnan(vecs(:,1)),:);
                                vecs=vecs(~isnan(vecs(:,2)),:);
                                NDP=dot(vecs(:,1),vecs(:,2))/(norm(vecs(:,1))*norm(vecs(:,2)));
                                mat_ndp(tt,tt2)=NDP;
                            end
                        end
                        ResultsEncSimOnlyNum.(TRs{tr}).(reg_names{reg}).byList.SimMat.ndp(subj,:,:,r,l)=mat_ndp;
                       
                    end %ends the size of region conditional
                end %ends the reps loop
            end %ends the regions loop
        end %ends the choose Trs loop
        
    end %ends the list loop
end %ends the subjects loop

save(results_filename,'ResultsEncSimOnlyNum');
end

