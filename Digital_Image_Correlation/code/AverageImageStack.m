% Average image stack: sum pixel values of images and divide by number of images
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function AverageImageStack()
    % Get file list
    if exist('FileNameList')==0
        [FileNameListName,FileNameListPath]=uigetfile('*.mat','Open filenamelist.mat');
        cd(FileNameListPath);
        load(FileNameListName,'FileNameList');
    end
    NumOfTotalImages=size(FileNameList,1);

    % Get number of images to combine
    NumOfSummedImages=10;
    Prompt={'Enter number of images to combine:'};
    DlgTitle='Number of combined images';
    DefValue={num2str(NumOfSummedImages)};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    NumOfSummedImages=str2num(cell2mat(Answer(1,1)));
    NumOfImageStacks=ceil(NumOfTotalImages/NumOfSummedImages);

    [Path,Name,Ext] = fileparts(FileNameList(1,:)); % file extension
    ImageInfo=imfinfo(FileNameList(1,:));           % file bit depth
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
    end

    % for each image stack
    for Stack=1:NumOfImageStacks
        FirstImageIndex=(Stack-1)*NumOfSummedImages+1;
        LastImageIndex=FirstImageIndex+NumOfSummedImages-1;
        if LastImageIndex > NumOfTotalImages
            LastImageIndex=NumOfTotalImages;
        end
        display(sprintf('stack %d, first: %d, last: %d', Stack, FirstImageIndex, LastImageIndex));
        %display(sprintf('current image %s', FileNameList(FirstImageIndex,:)));
        SummedImage = uint64(imread(FileNameList(FirstImageIndex,:)));
        for Image = 1:NumOfSummedImages-1
            %display(sprintf('current image %s', FileNameList(FirstImageIndex+Image,:)));
            NextImage = uint64(imread(FileNameList(FirstImageIndex+Image,:)));
            SummedImage = imadd(SummedImage,NextImage);
        end
        SummedImage = imdivide(SummedImage,NumOfSummedImages); 
        %imshow(DataFieldType(SummedImage));
        imwrite(DataFieldType(SummedImage),sprintf('avg%07d%s',Stack,Ext));
    end
end