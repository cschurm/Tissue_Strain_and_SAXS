%Load Images to Collect
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load filenamelist.mat
NumOfImages=size(FileNameList,1);

%generate new collected file
ImageName=strcat(deepestFolder,'_full.tif');
A=imread(FileNameList(1,:));
imwrite(A,ImageName);

for ii=1:NumOfImages
imshow(FileNameList(ii,:)) 
    if ii >= 2
    A=imread(FileNameList(ii,:));
    imwrite(A, ImageName, 'WriteMode', 'append');
    end 
end
