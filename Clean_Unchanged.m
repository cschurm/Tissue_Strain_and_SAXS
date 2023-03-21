
%% Clear Non-Moving Points
% This sections removes points that do not move between their first and
% final locations
load('validx.dat')
load('validy.dat')
[m,n]=size(validx);
validx_fix=validx.*1000; %to avoid round-off errors
validy_fix=validy.*1000;
ii=1;
while ii <= m
    if validx_fix(ii,1) == validx_fix(ii,n) && validy_fix(ii,1) == validy_fix(ii,n)
       validx_fix(ii,:)=[];
       validy_fix(ii,:)=[];
    else
       ii=ii+1;
    end
    [m,~]=size(validx_fix);
end
validx=validx_fix./1000;
validy=validy_fix./1000;

%% Treshold Cleaning
%This section removes points who's final displacements are not larger than
%a certain percentage of their initial displacement. Removes groups of
%points that may jiggle in space uncorrelated to image movement

[m,n]=size(validx);
validx_fix=validx;
validy_fix=validy;
ii=1;
tol=0.1; %change this value to adjust tolerance
while ii <= m
        x1=[validx_fix(ii,1),validy_fix(ii,1);validx_fix(ii,2),validy_fix(ii,2)];
        x2=[validx_fix(ii,1),validy_fix(ii,1);validx_fix(ii,n),validy_fix(ii,n)];
        d1=pdist(x1,'euclidean');
        d2=pdist(x2,'euclidean');
        dist_tol=(d2/d1)/100;
    if dist_tol < tol || isnan(dist_tol)
        validx_fix(ii,:)=[];
        validy_fix(ii,:)=[];
    else
       ii=ii+1;
    end
    [m,~]=size(validx_fix);
end
validx=validx_fix;
validy=validy_fix;

% Plot New 
[FileNameListName,FileNameListPath]=uigetfile('*.mat','Open filenamelist.mat');
cd(FileNameListPath);
NumOfImages=size(validx,2);
load(strcat(FileNameListPath,FileNameListName))
for CurrentImage=1:NumOfImages
        imshow(FileNameList(CurrentImage,:));
        hold on
        title(['Marker positions in x-y-direction',sprintf(' (Current image #: %1g)',CurrentImage)]);
        plot(validx(:,CurrentImage),validy(:,CurrentImage),'.g','MarkerSize',10)
        hold off
        drawnow
end




    