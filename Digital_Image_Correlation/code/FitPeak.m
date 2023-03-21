% Fit peak with initial guess and show results
function [Beta,ResNorm,ExitFlag]=FitPeak(CroppedImage,DirectionPoints,CroppedLabelsXY,CurrentLabel,DirectionSum,Options,ShowFit)
        
    XData=[(round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))-round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2)))):1: ...
          (round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))+round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2))))];
    if DirectionSum==2
        CroppedImage=CroppedImage'; % Transpose for second direction
    end   
    YData=sum(CroppedImage)/(2*CroppedLabelsXY(CurrentLabel,DirectionPoints(1,3)));

    % Initial guess
    BackgroundGuess=(YData(1)+YData(round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2)))*2))/2;   % guess for the background level - average over the first and last grey value
    WidthGuess=(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2)))/5;                                 % guess for the peak width - take a fifth of the cropping width
    AmplitudeGuess=YData(round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2))));                   % guess for the amplitude - take the grey value at the peak position
    PositionGuess=CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1));                                  % guess for the position of the peak - take the position from bwlabel

    % Fitting
    [Beta,ResNorm,~,ExitFlag]=lsqcurvefit(@GaussOnePeak,[AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],XData,YData,[],[],Options);

    % Show fitting results
    if ShowFit
        XTest=[(round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))-round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2)))):0.1: ...
               (round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))+round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2))))]; 
        YTest=GaussOnePeak(Beta,XTest);
        YGuess=GaussOnePeak([AmplitudeGuess PositionGuess WidthGuess BackgroundGuess],XTest);
        plot(XData,YData,'o');
        hold on
        plot(XTest,YTest,'r');
        plot(XTest,YGuess,'b');   
        drawnow
        hold off
    end
