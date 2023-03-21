% Average images: average marker positions over multiple image numbers
% Programmed by Chris
% Revised by Melanie
% Last revision: 04/28/16
function [ValidXMean,ValidYMean]=AverageImages(ValidX,ValidY,Direction)

    ValidXMean=ValidX;
    ValidYMean=ValidY;

    switch Direction
        case 'x' % x-direction
            Valid1=ValidX;
            Valid2=ValidY;
        case 'y' % y-direction
            Valid1=ValidY;
            Valid2=ValidX;
        otherwise % invalid
            return
    end

    TimeFile='Open timeimage.txt';
    TimeFileExt='*.txt';
    Valid2Mean=mean(Valid2);
    Selection = menu(sprintf('How do you want to average over time?'),'Average images by intervals','Average images by steps','Go Back');
    
    switch Selection
        case 1 % Average images by intervals (former find_and_mean_images)
            Selection = menu(sprintf('How do you want to average over time?'),'Large differences','Fixed interval length','Go Back');
            
            switch Selection
                case 1 % Large differences
                    Prompt={'Enter difference threshold'};
                    DlgTitle='Average images';
                    Threshold=5;
                    DefValue={num2str(Threshold)};
                    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
                    Threshold=str2double(cell2mat(Answer(1,1)));
                    TimeStepPositions=[find(abs(diff(Valid2Mean))>Threshold) length(Valid2Mean)];
                case 2
                    % Interval
                    Prompt={'Enter time interval length'};
                    DlgTitle='Average over time';
                    IntervalLength=10;
                    DefValue={num2str(IntervalLength)};
                    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
                    IntervalLength=str2num(cell2mat(Answer(1,1)));
                    Valid2MeanLength=length(Valid2Mean);
                    TimeStepPositions=1:IntervalLength:Valid2MeanLength;
                    EndOffset=(IntervalLength-2);
                    if ((TimeStepPositions(1,end)+EndOffset)<=Valid2MeanLength)
                        TimeStepPositions=TimeStepPositions+EndOffset;
                    end
                otherwise
                    return
            end
            ExtractedTime = menu(sprintf('Do you want to use the extracted time from images or the image number for display of averaged results?'),'Time','Image #','Go Back');

            % Time
            if ExtractedTime==1
                drawnow
                TimeName=uigetfile(TimeFileExt,TimeFile);
                if TimeName==0
                    disp('You did not select a file!');
                    return
                end
                TimeStamps=importdata(TimeName);
                TimeStamps(1,:)=[]; % first image serves as base for calculationg correlations
                TimeData=TimeStamps(:,2);
                SelectedTimeData=TimeStamps(TimeStepPositions,2);
                XLabel='Time stamp';

            % Image # 
            else
                TimeData=1:size(Valid1,2);
                SelectedTimeData=TimeStepPositions;
                XLabel='Image #';
            end

            figure;
            plot(TimeData,Valid2Mean,'.-');
            hold on
            plot(SelectedTimeData,Valid2Mean(1,TimeStepPositions),'.r');
            xlabel(XLabel);
            ylabel([Direction,'-position [pixel]']);
            hold off

            NumOfPoints=size(Valid2,1);
            NumOfTimeStepPositions=size(TimeStepPositions,2);
            StartPos=1;
            Valid1Mean=zeros(NumOfPoints,NumOfTimeStepPositions);
            Valid2Mean=zeros(NumOfPoints,NumOfTimeStepPositions);
            for CurPos=1:NumOfTimeStepPositions
                EndPos=TimeStepPositions(1,CurPos);
                if EndPos==StartPos
                    Valid1Mean(:,CurPos)=Valid1(:,StartPos);
                    Valid2Mean(:,CurPos)=Valid2(:,StartPos);
                else
                    Valid1Mean(:,CurPos)=(mean((Valid1(:,StartPos:EndPos)),2))';
                    Valid2Mean(:,CurPos)=(mean((Valid2(:,StartPos:EndPos)),2))';
                end
                StartPos=EndPos+1;
            end

            figure;
            plot(SelectedTimeData,mean(Valid2Mean));
            title('Average position over time');
            xlabel(XLabel);
            ylabel(['Averaged ',Direction,'-position [pixel]']);
            hold off 
            
            switch Direction
                case 'x' % x-direction
                    ValidXMean=Valid1Mean;
                    ValidYMean=Valid2Mean;
                case 'y' % y-direction
                    ValidXMean=Valid2Mean;
                    ValidYMean=Valid1Mean;
                otherwise % invalid
                    return
            end
            
        case 2 % Average images by steps (former validxy_mean)
            Time=1;
            TimeImage=[];
            drawnow
            [TimeName,PathTime]=uigetfile(TimeFileExt,TimeFile);
            if TimeName==0
                Time=0;
            else
                cd(PathTime);
                TimeImage=importdata(TimeName,'\t');
            end

            Prompt={'Enter time step size'};
            DlgTitle='Average images';
            TimeStepSize=3;
            DefValue={num2str(TimeStepSize)};
            Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
            TimeStepSize=str2num(cell2mat(Answer(1,1)));
            [NumOfPoints NumOfImges]=size(Valid1);
            for Step=1:TimeStepSize
                Valid1Temp(:,:,Step)=Valid1(:,Step:TimeStepSize:(NumOfImges-TimeStepSize)+Step);
                Valid2Temp(:,:,Step)=Valid2(:,Step:TimeStepSize:(NumOfImges-TimeStepSize)+Step);
                if Time~=0
                    TimeImageTemp(:,:,Step)=TimeImage(Step:TimeStepSize:(NumOfImges-TimeStepSize+1)+Step,:);
                end
            end
            Valid1Mean=mean(Valid1Temp,3);
            Valid2Mean=mean(Valid2Temp,3);
            
            switch Direction
                case 'x' % x-direction
                    ValidXMean=Valid1Mean;
                    ValidYMean=Valid2Mean;
                case 'y' % y-direction
                    ValidXMean=Valid2Mean;
                    ValidYMean=Valid1Mean;
                otherwise % invalid
                    return
            end
            
            % Save data?
            SaveData=menu(sprintf('Save data?'),'Yes','No');
            if SaveData==1
                SaveVariableToASCIIFile('validxmean.dat',ValidXMean);
                SaveVariableToASCIIFile('validymean.dat',ValidYMean);
                if Time~=0
                    TimeTmageMean=mean(TimeImageTemp,TimeStepSize);
                    SaveVariableToASCIIFile('timeimagemean.txt',TimeTmageMean);
                end
            end
        otherwise
            return
    end
end

function SaveVariableToASCIIFile(SuggestedFileName,Variable)
    drawnow
    [FileNameBase,PathNameBase] = uiputfile(SuggestedFileName,'Save as');
    cd(PathNameBase)
    save(FileNameBase,'Variable','-ascii','-tabs');
end
            

