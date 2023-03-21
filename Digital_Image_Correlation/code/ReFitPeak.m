% Refit peak with existing parameters and show results
function [Beta,ResNorm,ExitFlag]=ReFitPeak(Beta,CropX,CropY,CroppedImage,FileName,DirectionSum,Options,ShowFit,TotalTimeHours,EstimatedTotalTimeHours,TotalProgress)
    
    PositionGuess=Beta(1,2);   
    XData=[(round(PositionGuess)-round(CropX)):1:(round(PositionGuess)+round(CropX))];
    if DirectionSum==2
        CroppedImage=CroppedImage'; % Transpose for second direction
    end   
    YData=sum(CroppedImage)/(2*(CropY));
    XGuess=[(round(PositionGuess)-round(CropX)):0.1:(round(PositionGuess)+round(CropX))];
    YGuess=GaussOnePeak(Beta,XGuess);
    [Beta,ResNorm,~,ExitFlag]=lsqcurvefit(@GaussOnePeak,Beta,XData,YData,[],[],Options);
   
    % Show fitting results
    if ShowFit
        XTest=[(round(PositionGuess)-round(CropX)):0.1:(round(PositionGuess)+round(CropX))];
        YTest=GaussOnePeak(Beta,XTest);
        plot(XData,YData,'o');
        hold on
        plot(XTest,YTest,'r');
        plot(XGuess,YGuess,'b');
        title(['Filename: ',FileName, '; Progress [%]: ',num2str((round(TotalProgress*10))/10),'; Tot. t [h] ',num2str((round(TotalTimeHours*10)/10)),'; Est. t [h] ',num2str((round(EstimatedTotalTimeHours*10)/10))]);
        drawnow
        hold off
    end