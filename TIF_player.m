
%TIF Player
close all
uiwait(msgbox('Select Folder Containing Tracks'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
load('filenamelist.mat')
NumOfImages=size(FileNameList,1);
for CurrentImage=1:NumOfImages
        imshow(FileNameList(CurrentImage,:));%prior edit CurrentImage+1 8/17/17
        hold on
        title(['Marker positions in x-y-direction',sprintf(' (Current image #: %1g)',CurrentImage)]);
        hold off
        drawnow
end