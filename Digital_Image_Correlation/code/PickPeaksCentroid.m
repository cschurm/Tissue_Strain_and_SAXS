% This function allows to track multiple peaks in region of interest. The
% resolution can be much higher than the cross correlation methods of
% digital image correlation.

% Written by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY]=PickPeaksCentroid

    load('filenamelist.mat','FileNameList');
    NumOfImages=size(FileNameList,1);    

    Prompt={'How many peaks do you want to track?'};
    DlgTitle='Manual peak picking';
    DefValue={'2'};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    NumOfPeaks=str2num(cell2mat(Answer(1,1)));

    Image=uint8(mean(double(imread(FileNameList(1,:))),3));
    [ImageSizeX,ImageSizeY]=size(Image);
    figure,imshow(FileNameList(1,:));
    axis('equal');
    drawnow
    title(sprintf('Mark the region of interest:\nClick on the on the lower left corner and and then on the upper right corner'));
    hold on
    CropLength=7;
    CroppedLabelsXY(1,1:CropLength)=0;

    for CurrentPeak=1:NumOfPeaks;
        
        % Get region of interest
        [X,Y]=ginput(2); 
        CroppedLabelsXY(CurrentPeak,1)=CurrentPeak;
        CroppedLabelsXY(CurrentPeak,2)=(round(X(2,1)-X(1,1))/2)+X(1,1);
        CroppedLabelsXY(CurrentPeak,3)=(round(Y(1,1)-Y(2,1))/2)+Y(2,1);
        CroppedLabelsXY(CurrentPeak,4)=X(1,1);
        CroppedLabelsXY(CurrentPeak,5)=Y(2,1);
        CroppedLabelsXY(CurrentPeak,6)=round((X(2,1)-X(1,1))/2);
        CroppedLabelsXY(CurrentPeak,7)=round((Y(1,1)-Y(2,1))/2);

        plot(CroppedLabelsXY(CurrentPeak,2),CroppedLabelsXY(CurrentPeak,3),'o');
        drawnow
    end
    
    XDirectionPoints=[2,6,7];
    YDirectionPoints=[3,7,6];
    XDirectionSum=1;
    YDirectionSum=2;
    WidthRatio=1;

    tic;
    LabelCount=0;
    WaitBar=waitbar(0,'Processing image');
    NumOfCroppedLabels=size(CroppedLabelsXY,1); 
    for CurrentLabel=1:NumOfCroppedLabels
        waitbar(CurrentLabel/(NumOfCroppedLabels-1));
        
        % Crop the region around the detected peak
        CroppedImage=imcrop(Image,[round(CroppedLabelsXY(CurrentLabel,4)) round(CroppedLabelsXY(CurrentLabel,5)) round(CroppedLabelsXY(CurrentLabel,6))*2 round(CroppedLabelsXY(CurrentLabel,7))*2]);
        
        % Calculation in x-direction
        WidthGuessX=CroppedLabelsXY(CurrentLabel,XDirectionPoints(1,2))/WidthRatio;                        
        PositionGuessX=CroppedLabelsXY(CurrentLabel,XDirectionPoints(1,1));                                  
        X=CalculatePeakCentroid(CroppedImage,XDirectionPoints,CroppedLabelsXY,CurrentLabel,XDirectionSum,PositionGuessX,WidthGuessX);
        
        % Calculation in y-direction
        WidthGuessY=CroppedLabelsXY(CurrentLabel,YDirectionPoints(1,2))/WidthRatio;                        
        PositionGuessY=CroppedLabelsXY(CurrentLabel,YDirectionPoints(1,1));                                  
        Y=CalculatePeakCentroid(CroppedImage,YDirectionPoints,CroppedLabelsXY,CurrentLabel,YDirectionSum,PositionGuessY,WidthGuessY);
 
        LabelCount=LabelCount+1; 
        FitLabelsXY(LabelCount,1)=CurrentLabel;                     % point number
        FitLabelsXY(LabelCount,2)=abs(X);                           % fitted position of the peak x-direction
        FitLabelsXY(LabelCount,3)=abs(Y);                           % fitted position of the peak y-direction
        FitLabelsXY(LabelCount,4)=CroppedLabelsXY(CurrentLabel,6); % cropping width in x-direction
        FitLabelsXY(LabelCount,5)=CroppedLabelsXY(CurrentLabel,7); % cropping width in y-direction
    end
    
    close(WaitBar);
    Time(1,1)=toc;
    EstimatedTotalTimeHours=Time(1,1)*NumOfImages/3600;
    TotalTimeHours=sum(Time);
    close all
    
    % Plot image with peaks picked by user (crosses) and the chosen points which are easy to fit with a gaussian distribution (circles)
    figure, image(Image);
    title(sprintf(['Number of selected Images: ',num2str(NumOfImages), '; Estimated time [h]: ',num2str((round(EstimatedTotalTimeHours*10)/10)),...
           '\n Crosses are determined peaks, circles are chosen for the analysis.\n If you want to run the analysis hit ENTER']));
    axis('equal');
    hold on;
    plot(CroppedLabelsXY(:,2),CroppedLabelsXY(:,3),'+','Color','white'); % peaks from user
    plot(FitLabelsXY(:,2),FitLabelsXY(:,3),'o','Color','white');         % "good" points
    drawnow
    
    TotalProgress=1/NumOfImages;
    pause
    close all
    
    LabelLength=5;
    NumOfLabels=size(FitLabelsXY,1);

    for CurrentImage=1:NumOfImages-1
        tic;
        LabelCount=0;
        Image=mean(double(imread(FileNameList(CurrentImage+1,:))),3);
        WaitBar=waitbar(0,'Working on Image');

        for CurrentLabel=1:NumOfLabels % for all labels
            waitbar(CurrentLabel/(NumOfLabels-1));

            LabelNumber=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+1);
            WidthGuessX=CroppedLabelsXY(CurrentLabel,XDirectionPoints(1,2))/WidthRatio;                        
            PositionGuessX=CroppedLabelsXY(CurrentLabel,XDirectionPoints(1,1));    
            WidthGuessY=CroppedLabelsXY(CurrentLabel,YDirectionPoints(1,2))/WidthRatio;                        
            PositionGuessY=CroppedLabelsXY(CurrentLabel,YDirectionPoints(1,1));                  
            CropX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+4);
            CropY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+5);      
            
            CroppedImage=imcrop(Image,[(round(PositionGuessX)-round(CropX)) (round(PositionGuessY)-round(CropY)) 2*round(CropX) 2*round(CropY)]);

            % Calculation in x-direction
            X=CalculatePeakCentroid(CroppedImage,XDirectionPoints,CroppedLabelsXY,CurrentLabel,XDirectionSum,PositionGuessX,WidthGuessX);
              
            % Calculation in y-direction
            Y=CalculatePeakCentroid(CroppedImage,YDirectionPoints,CroppedLabelsXY,CurrentLabel,YDirectionSum,PositionGuessY,WidthGuessY);
         
            LabelCount=LabelCount+1;
            LabelStep=CurrentImage*LabelLength;
            FitLabelsXY(LabelCount,LabelStep+1)=LabelNumber;
            FitLabelsXY(LabelCount,LabelStep+2)=abs(X);
            FitLabelsXY(LabelCount,LabelStep+3)=abs(Y);
            FitLabelsXY(LabelCount,LabelStep+4)=CropX;
            FitLabelsXY(LabelCount,LabelStep+5)=CropY;
        end
        
        NumOfLabels=LabelCount;
        %drawnow
        TimeAllFiles(CurrentImage)=toc;
        TotalTimeSeconds=sum(TimeAllFiles);
        TotalTimeHours=TotalTimeSeconds/3600;
        ImageTimeSeconds=TotalTimeSeconds/CurrentImage;
        EstimatedTotalTimeHours=ImageTimeSeconds*NumOfImages/3600;
        %ProgressPercent=TotalTimeHours/EstimatedTotalTimeHours*100;
        TotalProgress=(CurrentImage+1)/(NumOfImages)*100;
        close(WaitBar);
    end  
    
    % save data
    save fitxy.dat FitLabelsXY -ascii -tabs

    TotalLabelLength=LabelLength*NumOfImages;
    ValidX=FitLabelsXY(:,2+LabelLength:LabelLength:TotalLabelLength);
    ValidY=FitLabelsXY(:,3+LabelLength:LabelLength:TotalLabelLength);
    disp('Processing images finished!');
    save validx.mat ValidX;
    save validy.mat ValidY;
    save validx.dat ValidX -ascii -tabs;
    save validy.dat ValidY -ascii -tabs;