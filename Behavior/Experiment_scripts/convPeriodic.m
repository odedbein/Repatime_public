function [convVec, convM]=convPeriodic(input,conv)
if size(conv,1)~=1 conv=conv'; end %the function works with conv as a row vector, transpose if not inputed this way
if size(input,2)~=1 input=input'; end %the function works with input as a row vector, transpose if not inputed this way

convM=zeros(length(input),length(input)+length(conv)-1);
for i=1:length(input)
    convM(i,i:i+length(conv)-1)=conv;
end

%now curculate the boundaries:
convM(:,1:length(conv)-1)=convM(:,1:length(conv)-1)+convM(:,end-(length(conv)-2):end);
convM=convM(1:length(input),1:length(input));
convVec=convM*input;
end
