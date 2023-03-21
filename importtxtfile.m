function [] = importtxtfile()
%% Find File for Import
[filename,pathname] = uigetfile('*.txt;');
fileDspace=strcat(pathname,filename);
cd(pathname)
delimiter = '\t';
if nargin<=2
    startRow = 2;
    endRow = 101;
end

%% Format for each line of text:
%   column10: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%*s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%*s%*s%*s%*s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);
%% Create output variable
dats = table(dataArray{1:end-1}, 'VariableNames', {'P2','P2_err','Angle','Angle_err','Height','Height_err','Loc','Loc_err','Dspacing','Dspacing_err','FWHM','FWHM_err','Area','Area_err','Normarea','Normarea_err'});
p2=table2array(dats(:,1));
p2_err=table2array(dats(:,2));
angle=table2array(dats(:,3));
angle_err=table2array(dats(:,4));
dspace=table2array(dats(:,9));
dspace_err=table2array(dats(:,10));
fwhm=table2array(dats(:,11));
fwhm_err=table2array(dats(:,12));
normarea=table2array(dats(:,15));
normarea_err=table2array(dats(:,16));

%% Remove Zeros
for ii = 1:length(dspace)
    if isnan(dspace(ii)) == 0
        Dspacing(ii)=dspace(ii);
        Dspacing_err(ii)=dspace_err(ii);
        P2(ii)=p2(ii);
        P2_err(ii)=p2_err(ii);
        FWHM(ii)=fwhm(ii);
        FWHM_err(ii)=fwhm_err(ii);
        NormArea(ii)=normarea(ii);
        NormArea_err(ii)=normarea_err(ii);
        Angle(ii)= angle(ii);
        Angle_err(ii)=angle_err(ii);
    end
end
Dspacing=Dspacing';   
Dspacing_err=Dspacing_err';
P2=P2';
P2_err=P2_err';
FWHM=FWHM';
FWHM_err=FWHM_err';
NormArea=NormArea';
NormArea_err=NormArea_err';
Angle=Angle';
Angle_err=Angle_err';

%% Save extracted data

currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
save (strcat(deepestFolder,'_SAXSdata'),'Dspacing','Dspacing_err','P2','P2_err','Angle','Angle_err','FWHM','FWHM_err','NormArea','NormArea_err')

