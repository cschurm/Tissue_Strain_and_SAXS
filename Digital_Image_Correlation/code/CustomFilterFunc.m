% Apply each filter from filter list to input image
function [Output]=CustomFilterFunc(Input,FilterList,ProcFuncPtrs)
    NumOfFilters=size(FilterList,1);
    Input=ProcFuncPtrs.SendData(Input); % GPU processing
    for Filter=1:NumOfFilters
        TempOutput=eval(FilterList{Filter,1}); 
        Input=TempOutput;
    end
    Output=Input;
    Output=ProcFuncPtrs.ReceiveData(Output); % GPU processing
