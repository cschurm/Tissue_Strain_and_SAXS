% Get correlation by modified image processing function "diccpcorr.m" for multi processing
function [InputCorrX,InputCorrY,StdX,StdY,CorrCoef] = CpcorrLocalMPFunc(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,AdditionFunc,CporrData,ProcFuncPtrs)
    spmd
        [InputCorrX,InputCorrY,StdX,StdY,CorrCoef]=CpcorrLocalFunc(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,AdditionFunc,CporrData,ProcFuncPtrs);
    end             


