function [ValidX,ValidY]=Clean_Tracks(ValidX,ValidY)
%% Remove markers moving relative to their neighbours:
% This is a filter which helps to find jumpy data points which are oscillating or stop moving. The Filter starts by finding the next 10 data point neighbours, 
% calculates their mean position and then plots the difference between each data point and its neighbours versus image number. If a data point is jumping around, it will show up as a spike. But
% be careful, one bad one will also affect its neighbours, therefore it is worthwhile to use this filter step by step.


Displ1=GetMeanDisplacement(ValidX);
Displ2=GetMeanDisplacement(ValidY);

        
% WriteToLogFile(LogFileName,'Remove jumpers in direction',Direction,'s');
% CurrentFigureHandle=UseCurrentFigureHandle(0);
    NumOfNeighbors=8; %can change to make filter more/less robust
    Continue=1;

    while Continue==1
        SizeValidX=size(ValidX);
        NumOfPoints=SizeValidX(1,1);
        NumOfImages=SizeValidX(1,2);
        
        % Calculate the distance to all other points
        MeanDistance=zeros(SizeValidX);
        MaxDistance=zeros(NumOfPoints,1);
        MinDistance=zeros(NumOfPoints,1);
        
        Waitbar=waitbar(0,'Processing the markers...');
        for CurrentPoint=1:NumOfPoints
            waitbar(CurrentPoint/NumOfPoints);
            Distance=(((ValidX(:,1)-ValidX(CurrentPoint,1)).^2+(ValidY(:,1)-ValidY(CurrentPoint,1)).^2).^(0.5));

            % Find the next neighbours by smallest distance
            [~,DistanceSortedIndices]=sort(Distance);

            % Take the mean position of the closest data points for all images
            MeanDistance(CurrentPoint,:)= ValidX(CurrentPoint,:)-mean(ValidX(DistanceSortedIndices(2:NumOfNeighbors),:),1);
            MaxDistance(CurrentPoint,1)= max(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)));
            MinDistance(CurrentPoint,1)= min(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)));
        end
        close(Waitbar)
        
        for CurrentPoint=1:NumOfPoints
            plot(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)))
            hold on
        end
         
        % Select upper and lower boundary
        xlabel('image number');
        ylabel(['relative marker displacement [pixel]']);
        title(['Define the upper and lower bound by clicking above and below the valid points',sprintf('\n(number of markers #: %1g, ',NumOfPoints),sprintf('number of images #: %1g).',NumOfImages)]);

        Point1=(ginput(1));
        plot([1;NumOfImages],[Point1(2);Point1(2)],'r');
        Point2=(ginput(1));
        plot([1;NumOfImages],[Point2(2);Point2(2)],'r');
        hold off

        PointsY=[Point1(2);Point2(2)];
        UpperBound=max(PointsY);
        LowerBound=min(PointsY);

        ValidXTemp=ValidX;
        ValidYTemp=ValidY;
        MeanDistanceTemp=MeanDistance;

        RemoveIndices=find(MaxDistance>UpperBound | MinDistance<LowerBound);
        ValidXTemp(RemoveIndices,:)=[];
        ValidYTemp(RemoveIndices,:)=[];
        MeanDistanceTemp(RemoveIndices,:)=[];
        SizeValidXTemp=size(ValidXTemp);
        NumOfPointsTemp=SizeValidXTemp(1,1);

        for CurrentPoint=1:NumOfPointsTemp
            plot(diff(MeanDistanceTemp(CurrentPoint,:)-MeanDistanceTemp(CurrentPoint,1)));
            hold on
        end
        plot([1;NumOfImages],[Point1(2);Point1(2)],'r');
        plot([1;NumOfImages],[Point2(2);Point2(2)],'r');
        xlabel('image number');
        ylabel(['relative marker displacement [pixel]']);
        title(['Define the upper and lower bound by clicking above and below the valid points',sprintf('\n(number of markers #: %1g, ',NumOfPoints),sprintf('number of deleted markers #: %1g).',NumOfPoints-NumOfPointsTemp)]);
        hold off
        
        Selection = menu('Do you like the result?','Apply','Apply and refine','Revert and try again','Cancel');
        switch Selection
            case 1
                if SizeValidXTemp(1,1)>0 % avoid to remove all markers
                    ValidX=ValidXTemp;
                    ValidY=ValidYTemp;
                end
                Continue=0;
            case 2
                if SizeValidXTemp(1,1)>0 % avoid to remove all markers
                    ValidX=ValidXTemp;
                    ValidY=ValidYTemp;
                end
                Continue=1;
            case 3
                Continue=1;
            otherwise
                return
        end
    end

%% Clear Non-Moving Points
% This sections removes points that do not move between their first and
% final locations

[m,n]=size(ValidX);
ValidX_fix=ValidX.*1000; %to avoid round-off errors
ValidY_fix=ValidY.*1000;
ii=1;
while ii <= m
    if ValidX_fix(ii,1) == ValidX_fix(ii,n) && ValidY_fix(ii,1) == ValidY_fix(ii,n)
       ValidX_fix(ii,:)=[];
       ValidY_fix(ii,:)=[];
    else
       ii=ii+1;
    end
    [m,~]=size(ValidX_fix);
end
ValidX=ValidX_fix./1000;
ValidY=ValidY_fix./1000;

%% Treshold Cleaning - Jiggling
%This section removes points whose final displacements are not larger than
%a certain percentage of their initial displacement. Removes groups of
%points that may jiggle in space uncorrelated to image movement.

[m,n]=size(ValidX);
ValidX_fix=ValidX;
ValidY_fix=ValidY;
ii=1;
tol=0.05; %change this value to adjust tolerance, dec value to include more points
while ii <= m
        x1=[ValidX_fix(ii,1),ValidY_fix(ii,1);ValidX_fix(ii,2),ValidY_fix(ii,2)];
        x2=[ValidX_fix(ii,1),ValidY_fix(ii,1);ValidX_fix(ii,n),ValidY_fix(ii,n)];
        d1=pdist(x1,'euclidean');
        d2=pdist(x2,'euclidean');
        dist_tol=(d2/d1)/100;
    if dist_tol < tol || isnan(dist_tol)
        ValidX_fix(ii,:)=[];
        ValidY_fix(ii,:)=[];
    else
       ii=ii+1;
    end
    [m,~]=size(ValidX_fix);
end
ValidX=ValidX_fix;
ValidY=ValidY_fix;

%% This Section Removes Points if a step size falls above # of stdvs

[m,n]=size(ValidX);
d=zeros(m,n-1);
for jj =2:n-1 %step across columns
    for ii = 2:m-1 %step down rows
pair=[ValidX(ii,jj),ValidY(ii,jj); ValidX(ii,jj-1),ValidY(ii,jj-1)];
d(ii,jj)=pdist(pair,'euclidean');
    end
end

step_mean=mean(d);
step_stdv=std(d);
upthresh=step_mean+step_stdv; %change value here to raise/lower threshold. 1 std will keep 66% of original points, 2 will keep 97%
ValidX_fix=ValidX;
ValidY_fix=ValidY;
ii=1;
while ii < m-1
        for jj = 1:n-1
            if d(ii,jj) > upthresh(jj)
            ValidX_fix(ii,:)=[];
            ValidY_fix(ii,:)=[];
            [m,~]=size(ValidX_fix);
            break
            end
        end
    ii=ii+1;
end
ValidX=ValidX_fix;
ValidY=ValidY_fix;

%% Plot new points 
load('filenamelist.mat')
NumOfImages=size(ValidX,2);
for CurrentImage=1:NumOfImages
        imshow(FileNameList(CurrentImage,:));%prior edit CurrentImage+1 8/17/17
        hold on
        title(['Marker positions in x-y-direction',sprintf(' (Current image #: %1g)',CurrentImage)]);
        plot(ValidX(:,CurrentImage),ValidY(:,CurrentImage),'.g','MarkerSize',10)
        hold off
        drawnow
end

%% Finishing Touches ;)
% Clean markers further individually or by area

m=menu('Clean Additional Points Manually?','By Single Points','By Area','No');
    if m == 1
        close
        [ValidX,ValidY] = RemovePoint(ValidX,ValidY,'x','postproc.log');
    elseif m == 2
        close
        [ValidX,ValidY] = RemoveArea(ValidX,ValidY,'x','postproc.log');
    end

save validx_clean.dat ValidX -ascii ;
save validy_clean.dat ValidY -ascii ;
end

%% Draw grid
function DrawGrid(Valid1,Valid2,Displ1,SelectedImage)

    % Find max and min point
    MinDispl1=find(Displ1(:,SelectedImage)==min(Displ1(:,SelectedImage)));
    MaxDispl1=find(Displ1(:,SelectedImage)==max(Displ1(:,SelectedImage)));
    
    GridSizeX=10*round(min(min(Valid1))/10):10:10*round(max(max(Valid1))/10);
    GridSizeY=10*round(min(min(Valid2))/10):10:10*round(max(max(Valid2))/10);
    [XI,YI]=meshgrid(GridSizeX,GridSizeY);
    
    ZI=griddata(Valid1(:,SelectedImage),Valid2(:,SelectedImage),Displ1(:,SelectedImage),XI,YI,'cubic');
    EpsXX = gradient(ZI,10,10);
    pcolor(XI,YI,EpsXX);
    axis('equal');
    caxis([min(min(EpsXX)) max(max(EpsXX))]);
    colorbar;
    shading('interp');
    hold on
    plot3(Valid1(:,SelectedImage),Valid2(:,SelectedImage),Displ1(:,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    plot3(Valid1(MinDispl1,SelectedImage),Valid2(MinDispl1,SelectedImage),Displ1(MinDispl1,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','y','MarkerFaceColor','b');
    plot3(Valid1(MaxDispl1,SelectedImage),Valid2(MaxDispl1,SelectedImage),Displ1(MaxDispl1,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','y','MarkerFaceColor','r');
    axis([min(min(XI))-10 max(max(XI))+10 min(min(YI))-10 max(max(YI))+10]);
    set(gca,'Ydir','reverse')
    drawnow
    hold off
end
%% Remove bad markers (point)
function [Valid1,Valid2,CurrentFigureHandle]=RemovePoint(Valid1,Valid2,Direction,LogFileName)
  
    WriteToLogFile(LogFileName,'Remove markers by point in direction',Direction,'s'); 
    
    CurrentFigureHandle=UseCurrentFigureHandle(0);
    CurrentSelection=1;
    SelectedImage=0;

    % More bad points to mark
    while CurrentSelection==1
        SizeValid1=size(Valid1);
        NumOfImages=SizeValid1(1,2);

        % Get displacement
        Displ1=GetDisplacement(Valid1);

        % Update temporary data
        Displ1Temp=Displ1;
        Valid1Temp=Valid1;
        Valid2Temp=Valid2;
       
        % Select image
        SelectedImage=NumOfImages;

        % Draw figure
        DrawGrid(Valid1,Valid2,Displ1,SelectedImage);
      

        % Get point position
        title('Click on the bad point');
        BadPoint=ginput(1);

        % Find point at given position (smallest distance)
        RelativePos=abs(Valid1(:,SelectedImage)-BadPoint(1,1))+abs(Valid2(:,SelectedImage)-BadPoint(1,2));
        SelectedPoint=find(RelativePos==min(RelativePos));

        % Update temporary data and delete point
        Displ1Temp(SelectedPoint,:)=[];
        Valid1Temp(SelectedPoint,:)=[];
        Valid2Temp(SelectedPoint,:)=[];
        
        
        % Update figure
        DrawGrid(Valid1Temp,Valid2Temp,Displ1Temp,SelectedImage);

        % Delete points permanently?
        Selection=menu(sprintf('Do you want to delete this point permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Image',SelectedImage,'d');
            SelectedPoint=sprintf(' (%f,%f)',BadPoint(1,1),BadPoint(1,2));
            WriteToLogFile(LogFileName,'Point',SelectedPoint,'s'); 
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
        end
        CurrentSelection = menu(sprintf('Do you want to mark another bad point?'),'Yes','No');
        
        % Abort
        if CurrentSelection==2
            save validx_clean.dat Valid1 -ascii ;
            save validy_clean.dat Valid2 -ascii ;
            return
        end
    end
end
   
  %% Remove bad markers (area)
  function [Valid1,Valid2,CurrentFigureHandle]=RemoveArea(Valid1,Valid2,Direction,LogFileName)
      
    WriteToLogFile(LogFileName,'Remove markers by area in direction',Direction,'s'); 

    CurrentFigureHandle=UseCurrentFigureHandle(0);
    CurrentSelection=1;
    SelectedImage=0;

    % More bad points to mark
    while CurrentSelection==1
        SizeValid1=size(Valid1);
        NumOfImages=SizeValid1(1,2);

        % Get displacement
        Displ1=GetDisplacement(Valid1);

        % Update temporary data
        Displ1Temp=Displ1;
        Valid1Temp=Valid1;
        Valid2Temp=Valid2;

        % Select image
        SelectedImage=NumOfImages;
      
         % Draw figure
        DrawGrid(Valid1,Valid2,Displ1,SelectedImage);

        title('Define the region of interest. All points inside that region will be deleted.');
        [XGrid,YGrid]=ginput(2);
        X(1,1)=XGrid(1);
        X(1,2)=XGrid(2);
        Y(1,1)=YGrid(2);
        Y(1,2)=YGrid(1);

        SelectedPoints=find(Valid1Temp(:,SelectedImage)>min(X) & Valid1Temp(:,SelectedImage)<max(X) & Valid2Temp(:,SelectedImage)<max(Y) & Valid2Temp(:,SelectedImage)>min(Y));

        % Update temporary data and delete points
        Displ1Temp(SelectedPoints,:)=[];
        Valid1Temp(SelectedPoints,:)=[];
        Valid2Temp(SelectedPoints,:)=[];
       
        % Update figure
        DrawGrid(Valid1Temp,Valid2Temp,Displ1Temp,SelectedImage);
        
        % Delete points permanently?
        Selection=menu(sprintf('Do you want to delete these points permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Image',SelectedImage,'d');
            SelectedArea=sprintf('rect point 1: (%f,%f), rect point 2: (%f,%f)',XGrid(1),YGrid(1),XGrid(2),YGrid(2));
            WriteToLogFile(LogFileName,'Area',SelectedArea,'s');
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
        end
        CurrentSelection = menu(sprintf('Do you want to mark more bad points?'),'Yes','No');
        
        % Abort
        if CurrentSelection==2
            save validx_clean.dat Valid1 -ascii ;
            save validy_clean.dat Valid2 -ascii ;
            return
        end
    end
  end    