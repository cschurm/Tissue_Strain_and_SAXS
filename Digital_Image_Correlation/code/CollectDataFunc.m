% Collect data (not multi processing: single processing or GPU)
function [ValidXCurrent,ValidYCurrent,StdXCurrent,StdYCurrent,CorrCoefCurrent] = CollectDataFunc(InputCorrelX,InputCorrelY,InputStdX,InputStdY,InputCorrCoef)
    ValidXCurrent=InputCorrelX;
    ValidYCurrent=InputCorrelY;
	CorrCoefCurrent=InputCorrCoef;
    StdXCurrent=InputStdX;
    StdYCurrent=InputStdY;


