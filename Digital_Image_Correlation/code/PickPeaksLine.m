% This function allows to track multiple peaks along one axis. The
% resolution can be much higher than the cross correlation methods of
% digital image correlation.

% Written by Chris
% Revised by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY]=PickPeaksLine

    load('filenamelist.mat','FileNameList');
    NumOfImages=size(FileNameList,1);

    FirstFigure=figure;
    imshow(FileNameList(1,:));
    title('First Image');
    Image=uint8(mean(double(imread(FileNameList(1,:))),3));

    ImageTypeSelection=menu(sprintf('Which image type do you want to use for analysis?'),'Positive (as is)', 'Negative', 'Cancel');
    switch ImageTypeSelection
        case 1
            Invert=0;
        case 2
            Image=255-Image;
            imshow(Image);
            Invert=1;
        otherwise
            close all;
            return
    end
        
    OrientationSelection=menu(sprintf('Do you want to measure horizontal or vertical?'),'Horizontal', 'Vertical', 'Cancel');
    switch OrientationSelection
        case 1
            Orientation=0;
        case 2
            Image=Image';
            imshow(Image);
            Orientation=90;
        otherwise
            close all;
            return
    end

    % Select path for displacement extraction along markers
    % Select point in middle of marker
    [NumOfImageRows,NumOfImageColumns]=size(Image);
    xlabel('Location on image [Pixels]');
    ylabel('Location on image [Pixels]');
    title(['Click on the center of the sample, width: ',num2str(NumOfImageColumns),'; height: ',num2str(NumOfImageRows)]);
    SelectedPoint=round(ginput(1));
    %X=SelectedPoint(1);
    Y=SelectedPoint(2);
    hold on
    line([1 NumOfImageColumns],[Y Y],'Color','r');

    % Prompt for integration width
    Prompt={'Enter integration width [Pixels]:'};
    DlgTitle='Input integration width for the analysis';
    DefValue={'20'};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    IntegrationWidth=str2num(cell2mat(Answer(1)));
    line([1 NumOfImageColumns],[Y-IntegrationWidth/2 Y-IntegrationWidth/2],'Color','g');
    line([1 NumOfImageColumns],[Y+IntegrationWidth/2 Y+IntegrationWidth/2],'Color','g');

    % Calculate line profile data and select peaks
    XData = [1:1:NumOfImageColumns];
    YData= sum(Image((Y-IntegrationWidth/2):(Y+IntegrationWidth/2),:),1)/IntegrationWidth;

    NextFigure=figure;
    plot(XData,YData);
    xlabel('Location on image [Pixels]');
    ylabel('Pixel intensity value');

    PeakSelection = menu(sprintf('How do you want to select the peaks?'),'Single Select','Cancel'); %'Automatically'
    switch PeakSelection
        case 1 % Single
            SelectPeaks=1;
            PeakCount=1;
            hold on
            while SelectPeaks==1
                title('Click on the left of the chosen peak');
                SelectedPoint=round(ginput(1));
                XPeakLeft = SelectedPoint(1);
                %YPeakLeft = SelectedPoint(2);
                line([XPeakLeft XPeakLeft], [1 max(YData)],'Color','r');

                title('Click on the right of the chosen peak');
                SelectedPoint=round(ginput(1));
                XPeakRight = SelectedPoint(1);
                %YPeakRight = SelectedPoint(2);
                line([XPeakRight XPeakRight], [1 max(YData)],'Color','r');

                plot(XData(XPeakLeft:XPeakRight),YData(XPeakLeft:XPeakRight),'k');
                PeakPositions(PeakCount,:)=[XPeakLeft XPeakRight];

                PeakCount=PeakCount+1;
                SelectPeaks = menu(sprintf('Do you want to select another peak?'),'One more','Continue with processing');
            end
        %case 2 % Automatically (TODO)
        otherwise
            close all;
            return
    end
    
    % Adjust fitting parameters
    Options=optimoptions(@lsqcurvefit,'Algorithm','levenberg-marquardt','MaxIter',10000,'MaxFunEvals',10000);

    NumOfPeaks=size(PeakPositions,1);
    for CurrentPeak=1:NumOfPeaks
        FitXData=XData(PeakPositions(CurrentPeak,1):PeakPositions(CurrentPeak,2));
        FitYData=YData(PeakPositions(CurrentPeak,1):PeakPositions(CurrentPeak,2));

        % Initial guess
        BackgroundGuess=(YData(PeakPositions(CurrentPeak,2))+YData(PeakPositions(CurrentPeak,2)))/2;    % guess for the background level - average of the first and last grey value
        WidthGuess=(PeakPositions(CurrentPeak,2)-PeakPositions(CurrentPeak,1))/2;                       % guess for the peak width - take half of the cropping width
        AmplitudeGuess=max(FitYData);                                                                   % guess for the amplitude - take the grey value at the peak position
        PositionGuess=(PeakPositions(CurrentPeak,2)+PeakPositions(CurrentPeak,1))/2;                    % guess for the position of the peak - take the position from bwlabel

        % Fitting
        X=lsqcurvefit(@GaussOnePeak,[AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],FitXData,FitYData,[],[],Options);

        % Show fitting results
        XTest=FitXData; 
        YTest=GaussOnePeak(X,XTest);
        YGuess=GaussOnePeak([AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],XTest);
        plot(XTest,YTest,'r');
        plot(XTest,YGuess,'b');
        drawnow
        Peaks(CurrentPeak,1,:)=X;
    end
    
    ActionSelection=menu(sprintf('Do you want proceed?'),'Do it!', 'No, stop!');
    if ActionSelection==2
        close all;
        return
    end

    CutPeakPositions=PeakPositions(:,2)-PeakPositions(:,1);
    for CurrentImage=1:NumOfImages-1
        Image=((mean(double(imread(FileNameList(CurrentImage+1,:))),3)));

        if OrientationSelection==2
            Image=Image';
            imshow(Image);          
            Orientation=90;
        end
        if ImageTypeSelection==2
            Image=255-Image;
            imshow(Image);
            Invert=1;
        end

        XData=[1:1:NumOfImageColumns];
        YData= sum(Image((Y-IntegrationWidth/2):(Y+IntegrationWidth/2),:),1)/IntegrationWidth;
        plot(XData,YData);
        title(['Image Number: ',num2str(CurrentImage)]);
        hold on

        for CurrentPeak=1:NumOfPeaks
            if (Peaks(CurrentPeak,CurrentImage,2)+CutPeakPositions(CurrentPeak)/2)>NumOfImageColumns
                FitXData=XData((NumOfImageColumns-CutPeakPositions(CurrentPeak)):NumOfImageColumns);
                FitYData=YData((NumOfImageColumns-CutPeakPositions(CurrentPeak)):NumOfImageColumns);
            else
                FitXData=XData((Peaks(CurrentPeak,CurrentImage,2)-CutPeakPositions(CurrentPeak)/2):(Peaks(CurrentPeak,CurrentImage,2)+CutPeakPositions(CurrentPeak)/2));
                FitYData=YData((Peaks(CurrentPeak,CurrentImage,2)-CutPeakPositions(CurrentPeak)/2):(Peaks(CurrentPeak,CurrentImage,2)+CutPeakPositions(CurrentPeak)/2));
            end

            % Initial guess
            BackgroundGuess=Peaks(CurrentPeak,CurrentImage,4);  % guess for the background level - average of the first and last grey value
            WidthGuess=Peaks(CurrentPeak,CurrentImage,3);       % guess for the peak width - take half of the cropping width
            AmplitudeGuess=Peaks(CurrentPeak,CurrentImage,1);   % guess for the amplitude - take the grey value at the peak position
            PositionGuess=Peaks(CurrentPeak,CurrentImage,2);    % guess for the position of the peak - take the position from bwlabel

            % Fitting
            X=lsqcurvefit(@GaussOnePeak,[AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],FitXData,FitYData,[],[],Options);
            
            % Show fitting results
            XTest=FitXData; 
            YTest=GaussOnePeak(X,XTest);
            YGuess=GaussOnePeak([AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],XTest);
            plot(XTest,YTest,'r');
            plot(XTest,YGuess,'g'); 
            drawnow
            Peaks(CurrentPeak,CurrentImage+1,:)=X;
        end
        hold off
        Amplitude=Peaks(:,CurrentImage,1)';
        PeakPosition=Peaks(:,CurrentImage,2)';
        PeakWidth=Peaks(:,CurrentImage,3)';
        Background=Peaks(:,CurrentImage,4)';
        dlmwrite('backupPeakPosition.txt',PeakPosition','delimiter','\t','-append');      
        dlmwrite('backupAmplitude.txt',Amplitude','delimiter','\t','-append');       
        dlmwrite('backupPeakWidth.txt',PeakWidth','delimiter','\t','-append');
        dlmwrite('backupBackground.txt',Background','delimiter','\t','-append');
    end

    % Save data
    ValidX=Peaks(:,2:NumOfImages,2);
    %ValidY=Peaks(:,:,3); ???
    ValidY=zeros(size(ValidX));

    Amplitude=Peaks(:,:,1)';
    PeakPosition=Peaks(:,:,2)';
    PeakWidth=Peaks(:,:,3)';
    Background=Peaks(:,:,4)';

    save Peaks;
    save Amplitude.dat Amplitude -ascii -tabs;
    save PeakPosition.dat PeakPosition -ascii -tabs;
    save PeakWidth.dat PeakWidth -ascii -tabs;
    save Background.dat Background -ascii -tabs;
    save validx.dat ValidX -ascii -tabs;
    save validy.dat ValidY -ascii -tabs;