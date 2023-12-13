function encoding_background_connectivity_plot(ResultsBackgroundConnectivityOnlyNum,reg_names,closePrev,regions1,regions2)

if closePrev
    close all
end
plotSubj=0;
Fisher=1; %connectivity values - you always want to transform
if Fisher %fisher transform the data, that is usually desireable.
    Fisher_title=' (F-trans)';
else
    Fisher_title='';
end


%get subjects colors:
figure;
subs_col=get(gca,'colororder');
close(gcf)
itemsPerEvent=4;
num_lists=6;
num_reps=5;
%some ploting paramters:
%linewidth:
line_wdt=[6, 1.5, 1.5, 1.5, 6];
%ylabel size:
ylabel_size=16;
yticks_size=ylabel_size-4;
xlabel_size=ylabel_size;
xticks_size=yticks_size;
title_size=14;
%yLimits=[0.92 1.06];

% green colors:
color=[linspace(38,14,num_reps)' linspace(198,79,num_reps)' linspace(5,1,num_reps)'];
colorGreen=color/255;

fnames=reg_names;

%things for stats:
paired_RepStruct={'rep','Rep1','Rep2','Rep3','Rep4','Rep5'};
paired_RepStruct(2:num_reps+1,1)={'Rep1';'Rep2';'Rep3';'Rep4';'Rep5'};

struct_reg_names=fieldnames(ResultsBackgroundConnectivityOnlyNum.perList);

%% plot all regions
for r1=regions1 %numel(fnames)
    for r2=regions2
        if r1 ~= r2
            color=colorGreen;
            
            if r1 < r2 %itll be r1_r2
                reg=['reg' num2str(r1) '_reg' num2str(r2)];
            else %r2 is smaller, so it'll be r1_r2
                reg=['reg' num2str(r2) '_reg' num2str(r1)];
            end
            
            %get regs names:
            reg_name1=fnames{r1};
            reg_name2=fnames{r2};
            
            %get the data
            data=ResultsBackgroundConnectivityOnlyNum.perList.(reg);
            if Fisher %fisher transform the data, that is usually desireable.
                data=atanh(data);
            end
            
            %% plot all 5 repetitions, average on lists
            %average on lists
            curr_data=squeeze(mean(data,2));
            nSubj=size(curr_data,1);
            %num_reps=size(data,2);
            Av_data=nanmean(curr_data,1);
            %yLimits=[-0.7 0.2];
            SEM=nanstd(curr_data,1)/sqrt(nSubj);
            
            %calculate yLimits:
            yupperlim=max(Av_data+SEM)+0.05;
            ylowerlim=min(Av_data-SEM)-0.05;
            
            figure('Name',[reg_name1 '-' reg_name2],'NumberTitle','off');
            subplot(1,2,1);
            hold on
            bar(1:num_reps,zeros(1,num_reps),'FaceColor','none');
            for i=1:num_reps
                bar(i,Av_data(i),'FaceColor',color(i,:));
                errorbar(i,Av_data(i),SEM(i),'k');
            end
            ylabel(['All lists: bg connectivity' Fisher_title],'Fontsize',ylabel_size);
            
            xlabel('Repetition','Fontsize',xlabel_size);
            xlim([0.5 num_reps+0.5]);
            set(gca,'xtick',1:num_reps,'Fontsize',xticks_size);
            
            % Plot subject data
            subjDataX=[];
            subjDataY=[];

            if plotSubj
                for i=1:num_reps
                    subjDataX = [subjDataX ones(1,nSubj)*i];
                    subjDataY = [subjDataY curr_data(:,i)'];
                end
                scatter(subjDataX,subjDataY, 10,'MarkerEdgeColor',[0.7 0.7 0.7]) %, 'MarkerFaceColor',0.8
                %Plot lines connecting within/across
                for ii = 1:nSubj
                    plot(1:num_reps,curr_data(ii,:), 'Color', subs_col((mod(ii,size(subs_col,1))+1),:))
                end
                
            end
            if ~plotSubj
                ylim([ylowerlim yupperlim]);
            end
            
            hold off;
            
            %one way ANOVA:
            fprintf('%s, ALL LISTS: one-way ANOVA: \n',[reg_name1 '-' reg_name2]);
            stats_data=curr_data(~isnan(curr_data(:,1)),:);
            n=size(stats_data,1);
            Y=reshape(stats_data,size(stats_data,1)*size(stats_data,2),1);
            S=repmat([1:n]',num_reps,1);
            F1=[ones(n,1);ones(n,1)*2;ones(n,1)*3;ones(n,1)*4;ones(n,1)*5];%number of reos
            X=[Y F1 S];
            
            %run the anova:
            alpha=.05;
            showtable=1;
            P = RMAOV1_mod_oded(X,alpha,showtable);
            %%compare reps:
            paired_tests=nan(num_reps);
            paired_RepStruct(2:num_reps+1,2:num_reps+1)=num2cell(nan);
            fprintf('%s, btw repetitions: \n',[reg_name1 '-' reg_name2]);
            for rep=1:(num_reps-1)
                for rr=(rep+1):num_reps
                    %fprintf('t-tests comp %s: rep %d vs. rep %d \n',comps{g,c},rep,(rr));
                    [h,p,ci,stats]=ttest(stats_data(:,rep),stats_data(:,rr));
                    paired_tests(rep,rr)=p;
                    paired_tests(rr,rep)=p;
                end
                
            end
            paired_RepStruct(2:num_reps+1,2:num_reps+1)=num2cell(paired_tests);
            disp(paired_RepStruct);
            %print mean and STD rep1 and 5:
            all_reps_std=nanstd(curr_data,1);
            fprintf('REP1: M = %.2f, SD = %.2f \n',Av_data(1),all_reps_std(1));
            fprintf('REP2: M = %.2f, SD = %.2f \n',Av_data(2),all_reps_std(2));
            fprintf('REP3: M = %.2f, SD = %.2f \n',Av_data(3),all_reps_std(3));
            fprintf('REP4: M = %.2f, SD = %.2f \n',Av_data(4),all_reps_std(4));
            fprintf('REP5: M = %.2f, SD = %.2f \n',Av_data(5),all_reps_std(5));
            [h,p,ci,stats]=ttest(stats_data(:,1),stats_data(:,5));
            diff_std=nanstd(curr_data(:,5)-curr_data(:,1));
            c_d=(Av_data(5)-Av_data(1))/diff_std;
            fprintf('REP1 vs. REP5 ttest: t = %.3f, p = %.3f, Cohens d: %.3f \n',stats.tstat,p,c_d);
            %% acount for time - take out the first rep1 and the last rep2-5, so that on average, rep1 now comes after reps2-5
            %average on lists
            curr_data=data;
            curr_data(:,1,1)=nan;%remove first list, first rep
            curr_data(:,6,2:5)=nan;%remove last list, reps 2-5, so now rep1 on average is after all the rest
            curr_data=squeeze(nanmean(curr_data,2));
            nSubj=size(curr_data,1);
            %num_reps=size(data,2);
            Av_data=nanmean(curr_data,1);
            SEM=nanstd(curr_data,1)/sqrt(nSubj);
            %calculate yLimits:
            yupperlim=max(Av_data+SEM)+0.05;
            ylowerlim=min(Av_data-SEM)-0.05;
            subplot(1,2,2)
            hold on
            bar(1:num_reps,zeros(1,num_reps),'FaceColor','none');
            for i=1:num_reps
                bar(i,Av_data(i),'FaceColor',color(i,:));
                errorbar(i,Av_data(i),SEM(i),'k');
            end
            ylabel(['cont. time: bg connectivity' Fisher_title],'Fontsize',ylabel_size);
            ylim([ylowerlim yupperlim]);
            xlabel('Repetition','Fontsize',xlabel_size);
            xlim([0.5 num_reps+0.5]);
            set(gca,'xtick',1:num_reps,'Fontsize',xticks_size);
            hold off;
            
            %one way ANOVA:
            fprintf('%s, CONTROL TIME: one-way ANOVA: \n',[reg_name1 '-' reg_name2]);
            stats_data=curr_data(~isnan(curr_data(:,1)),:);
            n=size(stats_data,1);
            Y=reshape(stats_data,size(stats_data,1)*size(stats_data,2),1);
            S=repmat([1:n]',num_reps,1);
            F1=[ones(n,1);ones(n,1)*2;ones(n,1)*3;ones(n,1)*4;ones(n,1)*5];%number of reos
            X=[Y F1 S];
            
            %run the anova:
            alpha=.05;
            showtable=1;
            P = RMAOV1_mod_oded(X,alpha,showtable);
            %%compare reps:
            paired_tests=nan(num_reps);
            paired_RepStruct(2:num_reps+1,2:num_reps+1)=num2cell(nan);
            fprintf('%s, btw repetitions: \n',[reg_name1 '-' reg_name2]);
            for rep=1:(num_reps-1)
                for rr=(rep+1):num_reps
                    %fprintf('t-tests comp %s: rep %d vs. rep %d \n',comps{g,c},rep,(rr));
                    [h,p,ci,stats]=ttest(stats_data(:,rep),stats_data(:,rr));
                    paired_tests(rep,rr)=p;
                    paired_tests(rr,rep)=p;
                end
                
            end
            paired_RepStruct(2:num_reps+1,2:num_reps+1)=num2cell(paired_tests);
            disp(paired_RepStruct);
            
        end %ends the r1 ~= r2
    end %ends the loop for regions2
    
end %ends the loop for regions1


end

function x = mymod(n,m)
x=mod(n,m);
if x==0
    x=m;
end
end

