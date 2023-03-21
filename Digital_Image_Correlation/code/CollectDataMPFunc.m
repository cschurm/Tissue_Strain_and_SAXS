% Collect data (multi processing)
function [ValidXCurrent,ValidYCurrent,StdXCurrent,StdYCurrent,CorrCoefCurrent] = CollectDataMPFunc(InputCorrelX,InputCorrelY,InputStdX,InputStdY,InputCorrCoef)
    
    % Collect data from all workers
    NumOfCorrelations=numel(InputCorrelX);
    LengthX=zeros(NumOfCorrelations,1);
    for CurrentCorr=1:NumOfCorrelations
        LengthX(CurrentCorr,:)=size(InputCorrelX{CurrentCorr},1);
    end
    End=0;
    for CurrentCorr=1:NumOfCorrelations
        Start=End+1;
        End=End+LengthX(CurrentCorr,1);
        ValidXCurrent(Start:End,:)=InputCorrelX{CurrentCorr};
        ValidYCurrent(Start:End,:)=InputCorrelY{CurrentCorr};
		CorrCoefCurrent(Start:End,:)=InputCorrCoef{CurrentCorr};
        StdXCurrent(Start:End,:)=InputStdX{CurrentCorr};
        StdYCurrent(Start:End,:)=InputStdY{CurrentCorr};
    end


