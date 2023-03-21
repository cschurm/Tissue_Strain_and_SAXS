% This function allows to track multiple peaks in region of interest. The
% resolution can be much higher than the cross correlation methods of
% digital image correlation.

% Written by Chris
% Revised by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY]=PickPeaks

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
    
    % Adjust fitting parameters
    Options=optimoptions(@lsqcurvefit,'Algorithm','levenberg-marquardt','MaxIter',10000,'MaxFunEvals',10000);

    tic;
    LabelCount=0;
    WaitBar=waitbar(0,'Processing image');
    NumOfCroppedLabels=size(CroppedLabelsXY,1); 
    for CurrentLabel=1:NumOfCroppedLabels
        waitbar(CurrentLabel/(NumOfCroppedLabels-1));
        
        % Crop the region around the detected peak
        CroppedImage=imcrop(Image,[round(CroppedLabelsXY(CurrentLabel,4)) round(CroppedLabelsXY(CurrentLabel,5)) round(CroppedLabelsXY(CurrentLabel,6))*2 round(CroppedLabelsXY(CurrentLabel,7))*2]);

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

        if ExitFlagX>0 && ExitFlagY>0   
            if X(3)>0.05 && Y(3)>0.05 % width of the peak should be wider than 1 pixel
                if ResNormX<ResNormRef && ResNormY<ResNormRef % goodness of fit, see Mathematics: Data Analysis and Statistics: Analyzing Residuals
                    if (round(X(2))-round(CroppedLabelsXY(CurrentLabel,6)))>0 && (round(X(2))+round(CroppedLabelsXY(CurrentLabel,6)))<ImageSizeX ...
                    && (round(Y(2))-round(CroppedLabelsXY(CurrentLabel,7)))>0 && (round(Y(2))+round(CroppedLabelsXY(CurrentLabel,7)))<ImageSizeY
                        LabelCount=LabelCount+1; 
                        FitLabelsXY(LabelCount,1)=CurrentLabel;                     % point number
                        FitLabelsXY(LabelCount,2)=abs(X(1));                        % fitted amplitude x-direction
                        FitLabelsXY(LabelCount,3)=abs(X(2));                        % fitted position of the peak x-direction
                        FitLabelsXY(LabelCount,4)=abs(X(3));                        % fitted peak width in x-direction
                        FitLabelsXY(LabelCount,5)=abs(X(4));                        % fitted background in x-direction
                        FitLabelsXY(LabelCount,6)=abs(Y(1));                        % fitted amplitude y-direction
                        FitLabelsXY(LabelCount,7)=abs(Y(2));                        % fitted position of the peak y-direction
                        FitLabelsXY(LabelCount,8)=abs(Y(3));                        % fitted peak width in y-direction
                        FitLabelsXY(LabelCount,9)=abs(Y(4));                        % fitted background in y-direction
                        FitLabelsXY(LabelCount,10)=CroppedLabelsXY(CurrentLabel,6); % cropping width in x-direction
                        FitLabelsXY(LabelCount,11)=CroppedLabelsXY(CurrentLabel,7); % cropping width in y-direction
                    end
                end
            end
        end
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
        
        plot(FitLabelsXY(:,CurrentImage*LabelLength+1),FitLabelsXY(:,CurrentImage*LabelLength+12),'+'); % label number and res norm
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