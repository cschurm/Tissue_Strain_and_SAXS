% Select markers
% Programmed by Chris
% Revised by Melanie
% Last revision: 04/28/16
function [ValidX,ValidY]=SelectMarkers(ValidX,ValidY)

    % Choose image
    NumOfImages=size(ValidX,2);
    SelectedImage=SelectImage(NumOfImages);
    SelectedViewIndices=[1,2]; % xpos vs. ypos
    [ValidX,ValidY,~,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,0);
    close(CurrentFigureHandle); 

% Select grid type
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)

    GridSelection = menu(sprintf('Which type of grid do you want to use'),'Two Markers','Rectangular','Two Rectangles of Markers','Circular','Line','Change View','Cancel');
    switch GridSelection
        case 1 % Two Markers
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=Select2PointGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        case 2 % Rectangular
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        case 3 % Two Rectangles of Markers
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectTwoRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        case 4 % Circular
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectCircularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        case 5 % Line
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectLineGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        case 6 % Change View
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=ChangeView(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end
    
% Get view data (ValidX,ValidY,DisplX,DisplY) for x- and y-direction by selected view indices
function [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices)
    
    DisplX=GetDisplacement(ValidX);
    DisplY=GetDisplacement(ValidY);

    Data={ValidX,ValidY,DisplX,DisplY};
    XViewData=Data{1,SelectedViewIndices(1,1)};
    YViewData=Data{1,SelectedViewIndices(1,2)};

% Change View
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=ChangeView(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)

    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle);
   
    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    title('Select view');

    ChangeViewSelection = menu(sprintf('Do you want to change the coordinate system to select markers?'),...
                                       'x-position vs. y-position','x-position vs. x-displacement','y-position vs. x-displacement','x-position vs. y-displacement','y-position vs. y-displacement',...
                                       'Go back to grid-type selection');
    switch ChangeViewSelection
        case 1
            SelectedViewIndices=[1,2];
        case 2
            SelectedViewIndices=[1,3];
        case 3
            SelectedViewIndices=[2,3];
        case 4
            SelectedViewIndices=[1,4];
        case 5
            SelectedViewIndices=[2,4];
        otherwise % Go back
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
            return      
    end
    % Change view in cases 1 - 5 by SelectedViewIndices
    [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=ChangeView(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);

% Two Markers
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=Select2PointGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)
    
    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle);

    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    title('Pick two markers');
    hold on

    [XPos,YPos]=ginput(1);
    RelativePos=abs(XViewData(:,SelectedImage)-XPos)+abs(YViewData(:,SelectedImage)-YPos);
    SelectedPoint1=find(RelativePos==min(RelativePos));
    plot(XViewData(SelectedPoint1,SelectedImage),YViewData(SelectedPoint1,SelectedImage),'+r');

    [XPos,YPos]=ginput(1);
    RelativePos=abs(XViewData(:,SelectedImage)-XPos)+abs(YViewData(:,SelectedImage)-YPos);
    SelectedPoint2=find(RelativePos==min(RelativePos));
    plot(XViewData(SelectedPoint2,SelectedImage),YViewData(SelectedPoint2,SelectedImage),'+r');
    hold off

    % Accept the chosen markers, try again or go back
    ConfirmSelection = menu(sprintf('Do you want to use these two markers?'),'Yes','No, try again','Go back to grid-type selection');

    switch ConfirmSelection
        case 1
            ValidX=[ValidX(SelectedPoint1,:);ValidX(SelectedPoint2,:)];
            ValidY=[ValidY(SelectedPoint1,:);ValidY(SelectedPoint2,:)];
        case 2
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=Select2PointGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        otherwise % Go back
        [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end
    
% Rectangular
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)

    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle);

    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    title(sprintf('Define the region of interest. Pick (single click) a point in the LOWER LEFT of your selection.\n  Do the same for a point in the UPPER RIGHT.'));
    hold on
    [XPos(1,1),YPos(1,1)]=ginput(1);
    hold on
    plot(XPos(1,1),YPos(1,1),'+b');
    drawnow

    [XPos(2,1),YPos(2,1)]=ginput(1);
    hold on
    plot(XPos(2,1),YPos(2,1),'+b');
    drawnow

    XMin = min(XPos);
    XMax = max(XPos);
    YMin = min(YPos);
    YMax = max(YPos);

    LowerLine=[XMin YMin; XMax YMin];
    UpperLine=[XMin YMax; XMax YMax];
    LeftLine=[XMin YMin; XMin YMax];
    RightLine=[XMax YMin; XMax YMax];

    plot(LowerLine(:,1),LowerLine(:,2),'-b');
    plot(UpperLine(:,1),UpperLine(:,2),'-b');
    plot(LeftLine(:,1),LeftLine(:,2),'-b');
    plot(RightLine(:,1),RightLine(:,2),'-b');

    SelectedPoints=find(XViewData(:,SelectedImage)>min(XPos) & XViewData(:,SelectedImage)<max(XPos) & YViewData(:,SelectedImage)<max(YPos) & YViewData(:,SelectedImage)>min(YPos));
    XViewData=XViewData(SelectedPoints,:);
    YViewData=YViewData(SelectedPoints,:);
    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','r');
    title('Red dots represent your new raster.');
    hold off

    % Accept the chosen markers, try again or go back
    ConfirmSelection = menu(sprintf('Do you want to use this raster?'),'Yes','No, try again','Go back to raster-type selection');

    switch ConfirmSelection
        case 1
            ValidX=XViewData;
            ValidY=YViewData;
        case 2
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        otherwise % Go back
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end
    
% Two Rectangles of Markers
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle] = SelectTwoRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)
    
    [ValidX1,ValidY1,SelectedViewIndices,CurrentFigureHandle]=SelectRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    [ValidX2,ValidY2,SelectedViewIndices,CurrentFigureHandle]=SelectRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    
    ValidXNew=[ValidX1;ValidX2];
    ValidYNew=[ValidY1;ValidY2];
    
    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    [XViewDataNew,YViewDataNew]=GetViewData(ValidXNew,ValidYNew,SelectedViewIndices);
    
    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    hold on
    plot(XViewDataNew(:,SelectedImage),YViewDataNew(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','r');
    hold off

    % Accept the chosen markers, try again or go back
    ConfirmSelection = menu(sprintf('Do you want to use these markers?'),'Yes','No, try again','Go back to grid-type selection');

    switch ConfirmSelection
        case 1
            ValidX=ValidXNew;
            ValidY=ValidYNew;
        case 2
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle] = SelectTwoRectangularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        otherwise % Go back
            [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end

% Circular
 function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectCircularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)

    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle);
     
    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    hold on
    title('Pick three points on the circle in clockwise order with the highest radius');

    [XPos(1,1),YPos(1,1)]=ginput(1);
    plot(XPos(1,1),YPos(1,1),'+b');
    [XPos(2,1),YPos(2,1)]=ginput(1);
    plot(XPos(2,1),YPos(2,1),'+b');
    [XPos(3,1),YPos(3,1)]=ginput(1);
    plot(XPos(3,1),YPos(3,1),'+b');

    % Calculate center between the 3 sorted points and the normal slope of the vectors
    Slope12=-1/((YPos(2,1)-YPos(1,1))/(XPos(2,1)-XPos(1,1)));
    Slope23=-1/((YPos(3,1)-YPos(2,1))/(XPos(3,1)-XPos(2,1)));
    Center12(1,1)=(XPos(2,1)-XPos(1,1))/2+XPos(1,1);
    Center12(1,2)=(YPos(2,1)-YPos(1,1))/2+YPos(1,1);
    Center23(1,1)=(XPos(3,1)-XPos(2,1))/2+XPos(2,1);
    Center23(1,2)=(YPos(3,1)-YPos(2,1))/2+YPos(2,1);
    plot(Center12(1,1),Center12(1,2),'+b');
    plot(Center23(1,1),Center23(1,2),'+b');

    if Slope12==Slope23
        [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectCircularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end

    % Calculate the crossing point of the two vectors
    Y1=Center12(1,2)-Center12(1,1)*Slope12;
    Y2=Center23(1,2)-Center23(1,1)*Slope23;
    XCross=(Y2-Y1)/(Slope12-Slope23);
    YCross=Slope12*XCross+Y1;
    XData=min(XPos):XCross;
    YData1=Y1+Slope12*XData;
    YData2=Y2+Slope23*XData;

    % Calculate radius
    R=sqrt((XCross-XPos(1,1))*(XCross-XPos(1,1))+(YCross-YPos(1,1))*(YCross-YPos(1,1)));

    % Calculate angle between vectors
    XVector=[1;0];
    X1vec(1,1)=XPos(1,1)-XCross;
    X1vec(2,1)=YPos(1,1)-YCross;
    X3vec(1,1)=XPos(3,1)-XCross;
    X3vec(2,1)=YPos(3,1)-YCross;
    Alpha13=acos((dot(X1vec,X3vec))/(sqrt(X1vec'*X1vec)*sqrt(X3vec'*X3vec)))*180/pi;
    Alpha01=acos((dot(XVector,X1vec))/(sqrt(X1vec'*X1vec)*sqrt(XVector'*XVector)))*180/pi;
    if YPos(1,1)<YCross
        Alpha01=Alpha01*(-1)+360;
    end
    Alpha03=acos((dot(XVector,X3vec))/(sqrt(XVector'*XVector)*sqrt(X3vec'*X3vec)))*180/pi;
    if YPos(3,1)<YCross
        Alpha03=Alpha03*(-1)+360;
    end
    TotalAngle=Alpha13;
    MinAngle=Alpha01;
    MaxAngle=Alpha03;

    AngleDiv=abs(round(TotalAngle))*10;
    AngleStep=(TotalAngle/AngleDiv);
    AngleAll(1:AngleDiv+1)=MinAngle-AngleStep*(1:AngleDiv+1)-AngleStep;
    XCircle(1:AngleDiv+1)=XCross+R*cos(AngleAll(1:AngleDiv+1)/180*pi);
    YCircle(1:AngleDiv+1)=YCross+R*sin(AngleAll(1:AngleDiv+1)/180*pi);
    plot(XCircle,YCircle,'-b');
    drawnow

    % Accept the chosen circle, try again or give up 
    ConfirmSelection = menu(sprintf('Do you want to use this circle as basis?'),'Yes','No, try again','Go back to grid-type selection');
    
    switch ConfirmSelection
        case 1
            % Pick the lower bound in the image
            title('Pick lower bound for the raster');

            [XPos(4,1),YPos(4,1)]=ginput(1);
            %hold on
            plot(XPos(1,1),YPos(1,1),'+r');

            R2=sqrt((XCross-XPos(4,1))*(XCross-XPos(4,1))+(YCross-YPos(4,1))*(YCross-YPos(4,1)));
            XCrossMatrix=ones(size(XViewData(:,SelectedImage)))*XCross;
            YCrossMatrix=ones(size(YViewData(:,SelectedImage)))*YCross;

            % Calculate radius for all points
            RAll=sqrt((XCrossMatrix-XViewData(:,SelectedImage)).*(XCrossMatrix-XViewData(:,SelectedImage))+(YCrossMatrix-YViewData(:,SelectedImage)).*(YCrossMatrix-YViewData(:,SelectedImage)));

            % Calculate angle for all points relative to circle center
            XViewDataNew=XViewData(:,SelectedImage)-XCross;
            YViewDataNew=YViewData(:,SelectedImage)-YCross;
            AngleAllPoints=acos((XViewDataNew.*XVector(1,1)+YViewDataNew.*XVector(2,1))./(sqrt(XViewDataNew.*XViewDataNew+YViewDataNew.*YViewDataNew).*sqrt(XVector(1,1).*XVector(1,1)+XVector(2,1).*XVector(2,1))))*180/pi;
            NegativeAngle=find(YViewData(:,SelectedImage)<YCross);
            AngleAllPoints(NegativeAngle)=AngleAllPoints(NegativeAngle)*(-1)+360;
            SelectedPoints=find(RAll>min(R,R2) & RAll<max(R,R2) & AngleAllPoints>MaxAngle & AngleAllPoints<MinAngle);
            XViewData=XViewData(SelectedPoints,:);
            YViewData=YViewData(SelectedPoints,:);
            plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','r');
            drawnow
            hold off

            % Accept the raster circle, try again or give up 
            ConfirmSelectionRaster = menu(sprintf('Do you want to use this raster?'), 'Yes','No, try again','Go back to raster-type selection');

            switch ConfirmSelectionRaster
                case 1
                    ValidX=XViewData;
                    ValidY=YViewData;
                case 2   
                    [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectCircularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
                otherwise % Go back
                    [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
            end
    case 2
        hold off
        [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectCircularGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    otherwise % Go back
        hold off
        [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
    end       
    
% Line
function [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectLineGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle)

    [XViewData,YViewData]=GetViewData(ValidX,ValidY,SelectedViewIndices);
    CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle);

    plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    title('Pick two points on the sample');
    hold on

    [XPos(1,1),YPos(1,1)]=ginput(1);
    plot(XPos(1,1),YPos(1,1),'+g');
    [XPos(2,1),YPos(2,1)]=ginput(1);
    plot(XPos(2,1),YPos(2,1),'+g');

    CenterPoint=[XPos(1,1)+(XPos(2,1)-XPos(1,1))/2; YPos(1,1)+(YPos(2,1)-YPos(1,1))/2];
    plot(CenterPoint(1,1),CenterPoint(2,1),'+b');

    LineLength=sqrt((XPos(2,1)-XPos(1,1))*(XPos(2,1)-XPos(1,1))+(YPos(2,1)-YPos(1,1))*(YPos(2,1)-YPos(1,1)));
    LineSlope=(YPos(2,1)-YPos(1,1))/(XPos(2,1)-XPos(1,1));
    IntersectY=YPos(1,1)-LineSlope*XPos(1,1);
    YCalc=zeros(2,1);
    YCalc=LineSlope*XPos+IntersectY;
    plot(XPos(:,1),YCalc(:,1),'-b');
    Y=[0; CenterPoint(2,1)-CenterPoint(1,1)*(-1/LineSlope)];

    DistanceFromLine=(abs((XPos(2,1)-XPos(1,1))*(YPos(1,1)-YViewData(:,SelectedImage))-(XPos(1,1)-XViewData(:,SelectedImage))*(YPos(2,1)-YPos(1,1))))...
                          /sqrt((XPos(2,1)-XPos(1,1))*(XPos(2,1)-XPos(1,1))+(YPos(2,1)-YPos(1,1))*(YPos(2,1)-YPos(1,1)));
    DistanceFromCenterPoint=(abs((Y(1,1)-CenterPoint(1,1))*(CenterPoint(2,1)-YViewData(:,SelectedImage))-(CenterPoint(1,1)-XViewData(:,SelectedImage))*(Y(2,1)-CenterPoint(2,1))))...
                                 /sqrt((Y(1,1)-CenterPoint(1,1))*(Y(1,1)-CenterPoint(1,1))+(Y(2,1)-CenterPoint(2,1))*(Y(2,1)-CenterPoint(2,1)));

    LineWidthQuestion=0;
    LineWidth=20;

    while LineWidthQuestion==0
        Prompt={'Enter the width of the line in [pixel]:'};
        DlgTitle='Input for grid creation';
        DefValue={num2str(LineWidth)};
        Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
        LineWidth=str2num(cell2mat(Answer(1,1)));

        SelectedPoints=find(DistanceFromLine<LineWidth & DistanceFromCenterPoint<LineLength/2);
        plot(XViewData(SelectedPoints,SelectedImage),YViewData(SelectedPoints,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','r');
        drawnow

        % Accept the chosen line, try again (different line width / different line) or go back
        ConfirmSelection = menu(sprintf('Do you want to use these markers?'),'Yes','No, try different linewidth','No, different line','Go back to grid-type selection');
        
        switch ConfirmSelection
            case 1   
                LineWidthQuestion=1;
                ValidX=XViewData(SelectedPoints,:);
                ValidY=YViewData(SelectedPoints,:);
                hold off
            case 2
                hold off
                plot(XViewData(:,SelectedImage),YViewData(:,SelectedImage),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
                hold on
                plot(XPos(:,1),YCalc(:,1),'-b');
                plot(XPos(1,1),YPos(1,1),'+g');
                plot(XPos(2,1),YPos(2,1),'+g');
            case 3
                LineWidthQuestion=1;
                hold off
                [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectLineGrid(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
            otherwise % Go back
                LineWidthQuestion=1;
                hold off
                [ValidX,ValidY,SelectedViewIndices,CurrentFigureHandle]=SelectGridType(ValidX,ValidY,SelectedViewIndices,SelectedImage,CurrentFigureHandle);
        end

    end


