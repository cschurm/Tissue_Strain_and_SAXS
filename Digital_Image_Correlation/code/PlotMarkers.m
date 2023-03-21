% Captures frames with your images and an overlay of the tracking markers
% Programmed by Chris, revised by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY,FileNameList]=PlotMarkers(ValidX,ValidY,FileNameList)
    load('filenamelist.mat');
    DataFileExtension='*.dat';
    VideoMarkerFolder='videomarkers';
    VideoFileExtension='jpg';
    if exist('ValidX')==0
        [ValidXName,ValidXPath]=uigetfile(DataFileExtension,'Open validx.dat');
        cd(ValidXPath);
        ValidX=importdata(ValidXName,'\t');
    end
    if exist('ValidY')==0
        [ValidYName,ValidYPath]=uigetfile(DataFileExtension,'Open validy.dat');
        cd(ValidYPath);
        ValidY=importdata(ValidYName,'\t');
    end
    if exist('FileNameList')==0
        [FileNameListName,FileNameListPath]=uigetfile('*.mat','Open filenamelist.mat');
        cd(FileNameListPath);
        load(FileNameListName,'FileNameList');
    end

    NumOfImages=size(ValidX,2);
    %Figure=figure;
%     VideoSelection=menu(sprintf('Do you want to create a video?'),'Yes','No');
%     if VideoSelection==1
%         mkdir(VideoMarkerFolder)
%         VideoStr='Vid';
%     end
    for CurrentImage=1:NumOfImages
        imshow(FileNameList(CurrentImage+1,:));
        hold on
        title(['Marker positions in x-y-direction',sprintf(' (Current image #: %1g)',CurrentImage)]);
        plot(ValidX(:,CurrentImage),ValidY(:,CurrentImage),'.g','MarkerSize',10)
        hold off
        drawnow
%         if VideoSelection==1
%             Number=CurrentImage+10000;
%             NumberStr=num2str(Number);
%             cd(VideoMarkerFolder);
%             VideoName=[VideoStr NumberStr '.' VideoFileExtension];
%             saveas(Figure,VideoName,VideoFileExtension);
%             cd('..')
%         end 
    end