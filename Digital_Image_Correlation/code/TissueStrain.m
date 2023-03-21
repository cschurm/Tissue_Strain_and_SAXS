close all

%Run this file for evaluating tissue strain from a series of images.
%This script calls a number of functions/scripts to streamline the
%workflow. Strain alaysis is limited to a semi-one dimensional method along
%X-dimension, ensure that image samples are aligned this way.
condition=0;
while condition ~= 1
    m=menu(sprintf('Select Option'),'Generate File List', 'Generate Grid', 'Generate Filter List', ...
    'Track Images', 'Clean Image Tracks', 'Analyze Image Strain','Plot Strain Over Time-Step','End');
if m == 1
    GenerateFileList;
elseif m == 2
    GenerateGrid;
elseif m == 3
    GenerateFilterList;
elseif m == 4
    clear
    condition=0;
    ProcessCorrelations; %function call
    uiwait(msgbox('Tracking Complete'))
elseif m == 5
   clear
   condition=0;
   
   if exist('validx')==0 || isempty(validx)
        validx='validx.dat';
        validy='validy.dat';
        if exist(validx,'file') 
            
            load(validx,'validx');
            load(validy,'validy');
        else
            uiwait(msgbox('Select Folder Containing Tracks'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            validx=strcat(PathNameBase,'validx.dat');
            validy=strcat(PathNameBase,'validy.dat');
            load validx.dat
            load validy.dat
        end
   end
    Clean_Tracks(validx,validy); %function call
elseif m == 6
    clear
    condition=0;
            uiwait(msgbox('Select Folder Containing Tracks'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            validx=strcat(PathNameBase,'/validx_clean.dat');
            validy=strcat(PathNameBase,'/validy_clean.dat');
            validx=load('validx_clean.dat');
            validy=load('validy_clean.dat');
 
            handleToMessageBox = msgbox('Calculating. Please wait, this may take some time.','Calculating Strain . . .','warn');
    strain_analys; %function call
    if exist('handleToMessageBox', 'var')
        delete(handleToMessageBox);
        clear('handleToMessageBox');
    end
    uiwait(msgbox('Calculations Complete!'))
    
elseif m == 7
    strain_plot; %function call
else
    condition = 1;
    uiwait(msgbox('Goodbye!'))
end
end
close all
clear