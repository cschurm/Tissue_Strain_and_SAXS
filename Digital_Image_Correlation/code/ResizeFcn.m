function [Output] = ResizeImageFunc(Input,Options)
    Output = imresize(Input,1/Options);


