% GPU processing: get data from GPU
function Output = ReceiveDataGPUFunc(Input,Options)
    Output=gather(Input);
end

