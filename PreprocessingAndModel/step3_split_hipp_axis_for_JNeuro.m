function step3_split_hipp_axis_for_JNeuro(engram)

cwd=pwd;
if engram
    mydir='/data/Bein';
else
    mydir='/Volumes/data/Bein';
end
%some definitions
proj_dir=fullfile(mydir,'/Repatime/repatime_scanner');
addpath(genpath(fullfile(mydir,'Software/CBI_tools')));
%add the fsldir, will need it for later:
addpath(genpath('/usr/local/fsl/bin'));
setenv('FSLOUTPUTTYPE','NIFTI_GZ');

%subjects I excluded:
%'15CD' - movement
%'27AC' - didn't finish the scan - only 4 scans
%'23SJ' - did very badly on day2
%'29DT' - low memory rates

%cd(project_dir);
subjects={'2ZD','3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
    '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

%subjects={'3RS','5BS','6GC','7MS','8PL','9IL','10BL','11CB','12AN','13GT','14MR','16DB',...
%    '17VW','18RA','19AB','20SA','21MY','22JP','24DL','25AL','26MM','28HM','30RK','31JC','32CC','33ML','34RB','36AN','37IR'};

roi_dir='rois/epi';


rois={'hippFromSF_noHATA','ca1_025','ca23_025','ca234dg_05','dg_025'};

for s=1:length(subjects)
    
    disp(subjects{s})
    subj_roi_dir=fullfile(proj_dir,'SubData',subjects{s},roi_dir);
    for roi=1:numel(rois) %all regions
        for hem=1:2
            curr_roi_name=rois{roi};
            if hem==1
                %right side:
                roi_name=['fs_r' curr_roi_name];
            else
                %right side:
                roi_name=['fs_l' curr_roi_name];
            end
            
            fileName=fullfile(subj_roi_dir,roi_name);
            % unzip the nifti file
            if ~exist([fileName '.nii'],'file')
                disp(['unzipping ' fileName])
                unix(['gunzip ' fileName '.nii.gz']);
            end
            
            %read file:
            [hipp,hipp_header,~] = niftiread([fileName '.nii']);
            % zip up nifti file - we took the data, so can zip again
            unix(['gzip -f ' fileName '.nii']);
           
            curr_roi=abs(hipp==1);
            %%always check the axis - if you use spm_vol permute the axis, so here the
            %%ant-post axis is actually the z axis - so need to take that
            %%[~,~,j]=ind2sub(size(curr_roi),find(curr_roi));
            %if you use niftiread - it is the Y axis.
            [~,j,~]=ind2sub(size(curr_roi),find(curr_roi));
            axis=unique(j);
            roi_length=axis(end)-axis(1);
            
            %settings if you want to use spm_read_vol:
%             AllButPost=axis(1):axis(1)+floor(roi_length*2/3); %zero these ones to create the ant hipp mask
%             AllButAnt=axis(1)+floor(roi_length/3)+1:axis(end); %zero these ones to create the post hipp mask
%             ant=axis(1):axis(1)+floor(roi_length/3);
%             post=axis(1)+floor(roi_length*2/3)+1:axis(end);
            
            %settings if you want to use niftiread:
            AllButPost=axis(1)+floor(roi_length/3)+1:axis(end); %zero these ones to create the ant hipp mask
            AllButAnt=axis(1):axis(1)+floor(roi_length*2/3); %zero these ones to create the post hipp mask
            ant=axis(1)+floor(roi_length*2/3)+1:axis(end);
            post=axis(1):axis(1)+floor(roi_length/3);
            
            %these are currently for niftiread-if using spm_vol, switch the
            %intexing to be the z axis, and maybe also don't use the
            %hipp_header argumaent (this is how the script was when using
            %the spm_read_vol option
            
            roi_ant=curr_roi;
            roi_ant(:,AllButAnt,:)=0;
            outputFileName=fullfile(subj_roi_dir,sprintf('%s_ant.nii',roi_name));
            niftiwrite(outputFileName,roi_ant,hipp_header);
            unix(['gzip -f ' outputFileName]);
            
            roi_mid=curr_roi;
            roi_mid(:,post,:)=0;
            roi_mid(:,ant,:)=0;
            outputFileName=fullfile(subj_roi_dir,sprintf('%s_mid.nii',roi_name));
            niftiwrite(outputFileName,roi_mid,hipp_header);
            unix(['gzip -f ' outputFileName]);
            
            roi_post=curr_roi;
            roi_post(:,AllButPost,:)=0;
            outputFileName=fullfile(subj_roi_dir,sprintf('%s_post.nii',roi_name));
            niftiwrite(outputFileName,roi_post,hipp_header);
            unix(['gzip -f ' outputFileName]);
        end
        
        %now combine rois to create bilateral hipp using fsl:
        cd(subj_roi_dir); 
        rroi=['fs_r' curr_roi_name];
        lroi=['fs_l' curr_roi_name];
        bilateralroi=['fs_' curr_roi_name];
        
        unix(['/usr/local/fsl/bin/fslmaths ' rroi '_ant -add ' lroi '_ant ' bilateralroi '_ant']);
        unix(['/usr/local/fsl/bin/fslmaths ' rroi '_mid -add ' lroi '_mid ' bilateralroi '_mid']);
        unix(['/usr/local/fsl/bin/fslmaths ' rroi '_post -add ' lroi '_post ' bilateralroi '_post']);
        cd(cwd)
    end
end
