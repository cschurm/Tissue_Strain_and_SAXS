% Get correlation by modified image processing function "diccpcorr.m"
% not multi processing: single processing or GPU
function [InputCorrX,InputCorrY,StdX,StdY,CorrCoef] = CpcorrLocalFunc(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,AdditionFunc,CporrData,ProcFuncPtrs)
    
    % Process all markers and images by cpcorr.m (provided by matlab image processing toolbox)
    InputPoints=[AdditionFunc(InputPointsX,DisplX(:,CurrentImage)) AdditionFunc(InputPointsY,DisplY(:,CurrentImage))];
    BasePoints=[BasePointsX,BasePointsY];
    [InputCorr,StdX,StdY,CorrCoef]=feval(CporrData.FunctionFileName,CporrData.CorrSize,ProcFuncPtrs,round(InputPoints),round(BasePoints),Input,Base); 
    InputCorrX=InputCorr(:,1); % results from cpcorr for the x-direction
    InputCorrY=InputCorr(:,2); % results from cpcorr for the y-direction                 


