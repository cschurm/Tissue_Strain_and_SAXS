% The peak labelling function is an alternative method to the
% calculate correlations function. The difference between the two functions is
% that the calculate correlations function uses the correlation coefficient to
% track a fixed grid of markers, while the peak labelling function searches
% for peaks in a base image and tries to fit a gauss function to it. 
% Therefore, the image should have a very low background and bright
% round peaks. If this is the case, peak labelling will find these peaks 
% and fit the gauss function in x and y direction to each of the peaks and 
% then track all peaks in all images. The output files are fitxy.dat,
% validx.dat and validy.dat, which will end up in the current directory of
% matlab. Attention: with each run these files will be overwritten. 
%
% The peak labelling function is a bit less sensible to image noise,
% only tracks markers in the image which are actually there and can under
% certain circumstances provide a higher accuracy for larger markers.

% Written by Chris
% Revised by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY]=LabelPeaks

    [ImageName,PathImage]=uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.png','Image files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg;*.png)';'*.*','All Files (*.*)'},'Open image for peak labelling');
    cd(PathImage);
    load('filenamelist.mat','FileNameList');
    NumOfImages=size(FileNameList,1);
    Image=mean(double(imread(ImageName)),3);
    figure, image(Image);
    axis('equal');
    drawnow
    
    % Get region of interest
    title(sprintf('Mark the region of interest:\nClick on the lower left corner and then on the upper right corner'));
    [X,Y]=ginput(2);
    XMin=X(1,1);
    XMax=X(2,1);
    YMin=Y(2,1);
    YMax=Y(1,1);
    
    % Subtract image background
    tic;
    MsgBox=msgbox('Subtracting image background, please wait.','Processing...');
    CorrectedImage=imsubtract(Image,imopen(Image,strel('disk',15)));
    close(MsgBox);
    image(CorrectedImage); 
    axis('equal');
    Time(1,1)=toc;
    drawnow
    
    % Subtract grey values to work only with real peaks
    tic;
    ROI=(CorrectedImage>10); 
    [Labels]=bwlabel(ROI,8); % label all peaks - very important function, crucial for the whole process; see matlab manual
    LabelProperties=regionprops(Labels,'basic'); % get peak properties from bwlabel
    LabelArea=[LabelProperties.Area];
    LabelCentroid=[LabelProperties.Centroid];
    LabelBoundingBox=[LabelProperties.BoundingBox];
    NumOfLabelCentroids=length(LabelCentroid)/2;
    LabelsXY=zeros(NumOfLabelCentroids,8);
    for CurrentLabel=1:NumOfLabelCentroids;
        LabelsXY(CurrentLabel,1)=CurrentLabel;
        LabelsXY(CurrentLabel,2)=LabelCentroid(1,(CurrentLabel*2-1)); % x coordinate of particle position
        LabelsXY(CurrentLabel,3)=LabelCentroid(1,(CurrentLabel*2)); % y coordinate of particle position
        LabelsXY(CurrentLabel,4)=LabelBoundingBox(1,(CurrentLabel*4)-3); % x coordinate of bounding box
        LabelsXY(CurrentLabel,5)=LabelBoundingBox(1,(CurrentLabel*4)-2); % y coordinate of bounding box
        LabelsXY(CurrentLabel,6)=LabelBoundingBox(1,(CurrentLabel*4)-1); % width (x) of bounding box
        LabelsXY(CurrentLabel,7)=LabelBoundingBox(1,(CurrentLabel*4)); % height (y) of bounding box
        LabelsXY(CurrentLabel,8)=LabelArea(1,CurrentLabel); % area of bounding box
    end

    % Crop in x direction to reduce to the region of interest, crop away peaks which are too small or too big
    MinPeakSize=10;
    MaxPeakSize=1000;
    LabelCount=0;
    for CurrentLabel=1:NumOfLabelCentroids;
        if XMin<LabelsXY(CurrentLabel,2) % crop all points left from Region Of Interest (ROI)
            if LabelsXY(CurrentLabel,2)<XMax % crop all points right from Region Of Interest (ROI)
                if YMin<LabelsXY(CurrentLabel,3) % crop all points below the Region Of Interest (ROI)
                    if LabelsXY(CurrentLabel,3)<YMax % crop all points above the Region Of Interest (ROI)
                        if MinPeakSize<LabelsXY(CurrentLabel,8) % crop all points with a small peak area 
                            if LabelsXY(CurrentLabel,8)<MaxPeakSize % crop all points with a big peak area
                                LabelCount=LabelCount+1;
                                CroppedLabelsXY(LabelCount,1)=LabelCount; % peaks get a new number 
                                CroppedLabelsXY(LabelCount,2)=LabelsXY(CurrentLabel,2); % x
                                CroppedLabelsXY(LabelCount,3)=LabelsXY(CurrentLabel,3); % y
                                CroppedLabelsXY(LabelCount,4)=LabelsXY(CurrentLabel,4); % x bounding box
                                CroppedLabelsXY(LabelCount,5)=LabelsXY(CurrentLabel,5); % y bounding box
                                CroppedLabelsXY(LabelCount,6)=LabelsXY(CurrentLabel,6); % width (x) bounding box
                                CroppedLabelsXY(LabelCount,7)=LabelsXY(CurrentLabel,7); % height (y) bounding box
                                CroppedLabelsXY(LabelCount,8)=LabelsXY(CurrentLabel,8); % area bounding box
                            end
                        end
                    end
                end
            end
        end
    end
    close all
    Time(1,2)=toc;
    
    % Adjust fitting parameters
    Options=optimoptions(@lsqcurvefit,'Algorithm','levenberg-marquardt','MaxIter',10000,'MaxFunEvals',10000);

    % Start fitting the peaks which are labeled by bwlabel
    tic;
    LabelCount=0;
    WaitBar=waitbar(0,'Processing image');
    NumOfCroppedLabels=size(CroppedLabelsXY,1);
    for CurrentLabel=1:NumOfCroppedLabels 
        waitbar(CurrentLabel/(NumOfCroppedLabels-1));
        
        % Crop the region around the detected peak
        CroppedImage=imcrop(Image,[(round(CroppedLabelsXY(CurrentLabel,2))-round(CroppedLabelsXY(CurrentLabel,6))) (round(CroppedLabelsXY(CurrentLabel,3))-round(CroppedLabelsXY(CurrentLabel,7))) ...
                                    round(CroppedLabelsXY(CurrentLabel,6))*2 round(CroppedLabelsXY(CurrentLabel,7))*2]);
                                
        XDirectionPoints=[2,6,7];
        YDirectionPoints=[3,7,6];
        XDirectionSum=1;
        YDirectionSum=2;
        ShowFit=1;
        ResNormRef=10000;
        
        % Fitting in x-direction
        [X,ResNormX,ExitFlagX]=FitPeak(CroppedImage,XDirectionPoints,CroppedLabelsXY,CurrentLabel,XDirectionSum,Options,ShowFit);
        
        % Fitting in y-direction
        [Y,ResNormY,ExitFlagY]=FitPeak(CroppedImage,YDirectionPoints,CroppedLabelsXY,CurrentLabel,YDirectionSum,Options,ShowFit);
       
        % Sort out the bad points and save the good ones in FitLabelsXY 
        if ExitFlagX>0 && ExitFlagY>0 
            if X(3)>1 && Y(3)>1 % width of the peak should be wider than 1 pixel
                if ResNormX/CroppedLabelsXY(CurrentLabel,6)<ResNormRef && ResNormY/CroppedLabelsXY(CurrentLabel,7)<ResNormRef % goodness of fit, see Mathematics: Data Analysis and Statistics: Analyzing Residuals
                    LabelCount=LabelCount+1; 
                    FitLabelsXY(LabelCount,1)=CurrentLabel;                       % point number 
                    FitLabelsXY(LabelCount,2)=abs(X(1));                          % fitted amplitude x-direction
                    FitLabelsXY(LabelCount,3)=abs(X(2));                          % fitted position of the peak x-direction
                    FitLabelsXY(LabelCount,4)=abs(X(3));                          % fitted peak width in x-direction
                    FitLabelsXY(LabelCount,5)=abs(X(4));                          % fitted background in x-direction
                    FitLabelsXY(LabelCount,6)=abs(Y(1));                          % fitted amplitude y-direction
                    FitLabelsXY(LabelCount,7)=abs(Y(2));                          % fitted position of the peak y-direction
                    FitLabelsXY(LabelCount,8)=abs(Y(3));                          % fitted peak width in y-direction
                    FitLabelsXY(LabelCount,9)=abs(Y(4));                          % fitted background in y-direction
                    FitLabelsXY(LabelCount,10)=CroppedLabelsXY(CurrentLabel,6);   % cropping width in x-direction
                    FitLabelsXY(LabelCount,11)=CroppedLabelsXY(CurrentLabel,7);   % cropping width in y-direction
                end
            end
        end
    end
    close(WaitBar);
    Time(1,3)=toc;
    EstimatedTotalTimeHours=Time(1,3)*NumOfImages/3600;
    TotalTimeHours=sum(Time);
    close all

    % Plot image with peaks labeled by bwlabel (crosses) and the chosen points which are easy to fit with a gaussian distribution (circles)
    figure, image(CorrectedImage);
    title(sprintf(['Number of selected Images: ',num2str(NumOfImages),'; Estimated time [h]: ', num2str((round(EstimatedTotalTimeHours*10)/10)),...
           '\n Crosses are determined peaks, circles are chosen for the analysis.\n If you want to run the analysis hit ENTER']));
    axis('equal');
    hold on;
    plot(CroppedLabelsXY(:,2),CroppedLabelsXY(:,3),'+','Color','white'); % peaks from bwlabel
    plot(FitLabelsXY(:,3),FitLabelsXY(:,7),'o','Color','white');         % "good" points
    drawnow
    
    TotalProgress=1/NumOfImages;
    pause
    close all
    
    LabelLength=12;
    NumOfFittedLabels=size(FitLabelsXY,1);
    for CurrentImage=1:NumOfImages-1
        tic;
        LabelCount=0;
        Image=mean(double(imread(FileNameList(CurrentImage+1,:))),3);
        WaitBar=waitbar(0,'Working on Image');

        for CurrentLabel=1:NumOfFittedLabels % for all fitted labels
            waitbar(CurrentLabel/(NumOfFittedLabels-1));
            
            LabelNumber=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+1);
            AmplitudeGuessX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+2);
            PositionGuessX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+3);
            WidthGuessX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+4);
            BackgroundGuessX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+5);
            AmplitudeGuessY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+6);
            PositionGuessY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+7);
            WidthGuessY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+8);
            BackgroundGuessY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+9);
            CropX=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+10);
            CropY=FitLabelsXY(CurrentLabel,(CurrentImage-1)*LabelLength+11);

            CroppedImage=imcrop(Image,[(round(PositionGuessX)-round(CropX)) (round(PositionGuessY)-round(CropY)) 2*round(CropX) 2*round(CropY)]);

            % Refitting in x-direction
            [X,ResNormX,ExitFlagX]=ReFitPeak([AmplitudeGuessX PositionGuessX WidthGuessX BackgroundGuessX],CropX,CropY,CroppedImage,FileNameList(CurrentImage,:),1,Options,...
                                             ShowFit,TotalTimeHours,EstimatedTotalTimeHours,TotalProgress);
            
            % Refitting in y-direction
            [Y,ResNormY,ExitFlagY]=ReFitPeak([AmplitudeGuessY PositionGuessY WidthGuessY BackgroundGuessY],CropY,CropY,CroppedImage,FileNameList(CurrentImage,:),2,Options,...
                                             ShowFit,TotalTimeHours,EstimatedTotalTimeHours,TotalProgress);

            if ExitFlagX>0 && ExitFlagY>0
                    LabelCount=LabelCount+1;
                    LabelStep=CurrentImage*LabelLength;
                    FitLabelsXY(LabelCount,LabelStep+1)=LabelNumber;
                    FitLabelsXY(LabelCount,LabelStep+2)=abs(X(1));
                    FitLabelsXY(LabelCount,LabelStep+3)=abs(X(2));
                    FitLabelsXY(LabelCount,LabelStep+4)=abs(X(3));
                    FitLabelsXY(LabelCount,LabelStep+5)=abs(X(4));
                    FitLabelsXY(LabelCount,LabelStep+6)=abs(Y(1));
                    FitLabelsXY(LabelCount,LabelStep+7)=abs(Y(2));
                    FitLabelsXY(LabelCount,LabelStep+8)=abs(Y(3));
                    FitLabelsXY(LabelCount,LabelStep+9)=abs(Y(4));
                    FitLabelsXY(LabelCount,LabelStep+10)=CropX;
                    FitLabelsXY(LabelCount,LabelStep+11)=CropY;
                    FitLabelsXY(LabelCount,LabelStep+12)=ResNormX;
            end
        end

        plot(FitLabelsXY(:,CurrentImage*LabelLength+1),FitLabelsXY(:,CurrentImage*LabelLength+12),'+');
        title(['Filename: ',FileNameList(CurrentImage,:), '; Progress [%]: ',num2str((round(TotalProgress*10))/10), '; Tot. t [h] ', num2str((round(TotalTimeHours*10)/10)), ...
               '; Est. t [h] ', num2str((round(EstimatedTotalTimeHours*10)/10))]);
        NumOfFittedLabels=LabelCount;
        drawnow
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

    ResNormRef=1000;
    [ValidX,ValidY]=ExtractGoodPoints(FitLabelsXY,ResNormRef,LabelLength);
    title('Processing images finished!');
    save validx.mat ValidX;
    save validy.mat ValidY;
    save validx.dat ValidX -ascii -tabs;
    save validy.dat ValidY -ascii -tabs;
