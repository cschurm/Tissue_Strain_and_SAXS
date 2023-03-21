function SaveCalibrationOutput(ValidXCorrected,ValidYCorrected)

    [FileName,PathName] = uiputfile('validx_cal.dat','Save validx');
    if FileName==0
        disp('You did not save your file!');
    else
        cd(PathName);      
        save(FileName,'ValidXCorrected','-ascii','-tabs');
    end  
        
    [FileName,PathName] = uiputfile('validy_cal.dat','Save validy');
    if FileName==0
        disp('You did not save your file!');
    else
        cd(PathName);
        save(FileName,'ValidYCorrected','-ascii','-tabs');
    end
end

