% Get correlation by image processing function "cpcorr.m" (standard deviation and correlation coefficient not available) for multi porcessing
function [InputCorrX,InputCorrY,StdX,StdY,CorrCoef] = CpcorrMPFunc(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,AdditionFunc,CporrData,ProcFuncPtrs)
    spmd
        [InputCorrX,InputCorrY,StdX,StdY,CorrCoef]=CpcorrFunc(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,AdditionFunc,CporrData,ProcFuncPtrs);
    end             


