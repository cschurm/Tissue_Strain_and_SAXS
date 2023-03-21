% Get image data type
function DataFieldType=GetImageDataType(FileName)   

    ImageInfo=imfinfo(FileName);
    switch ImageInfo.BitDepth
        case 8
            DataFieldType=@uint8;
        case 16
            DataFieldType=@uint16;
        case 24
            DataFieldType=@uint32;
        case 32
            DataFieldType=@uint32;
        case 64
            DataFieldType=@uint64;
        otherwise
            DataFieldType=[];
    end
