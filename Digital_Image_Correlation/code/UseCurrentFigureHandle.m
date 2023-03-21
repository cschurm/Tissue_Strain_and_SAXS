 % Use current figure handle: new figure (first time), existing (next time)
 function CurrentFigureHandle=UseCurrentFigureHandle(CurrentFigureHandle)
    if CurrentFigureHandle==0   % First time
        CurrentFigureHandle=figure;
    else                        % Next time
        set(0,'CurrentFigure',CurrentFigureHandle);
    end

