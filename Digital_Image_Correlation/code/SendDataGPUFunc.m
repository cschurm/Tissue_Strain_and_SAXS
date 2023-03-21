% GPU processing: send data to GPU
function Output = SendDataGPUFunc(Input,Options)
    Output=gpuArray(Input);
end

