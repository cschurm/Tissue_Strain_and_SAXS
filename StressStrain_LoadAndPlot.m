
% Load Stress and Strain Data From Same File
clear
close all

% %% Find Folder
% uiwait(msgbox('Select Folder'));
%             [PathNameBase] = uigetdir;
%             cd(PathNameBase);
%             currentDirectory = pwd;
% [upperPath, deepestFolder, ~] = fileparts(currentDirectory);
% 
% %% Import Load (N).
% %% Initialize variables.
% filename = strcat(PathNameBase,'/',deepestFolder,'.txt');
% delimiter = '\t';

%% Find File
[pathname]=uigetdir('Select File');
p=split(pathname,'/');
foldername=cell2mat(p(end));
%s=split(foldername,'_');
filename=strcat(foldername,'.txt'); 
%filename=strcat(cell2mat(s(2)),'.txt');
%% Format for each line of text:
%   column3: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%*s%*s%f%*s%*s%*s%*s%*s%[^\n\r]';
%% Open the text file.
fullpath=strcat(pathname,'/',filename);

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.

opts = delimitedTextImportOptions("NumVariables", 8);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["VarName1", "VarName2", "VarName3", "VarName4", "r_1", "VarName6", "VarName7", "VarName8"];
opts.VariableTypes = ["double", "double", "double", "double", "string", "double", "double", "double"];
opts = setvaropts(opts, 5, "WhitespaceRule", "preserve");
opts = setvaropts(opts, 5, "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
r = readtable(fullpath, opts);
clear opts

%% Allocate imported array to column variable names
load_N = r{:, 3};
%% Import Strain
cd(pathname)
load valid_strain.dat
%% Modify Data Files for Graphing
strain=valid_strain';
strain=strain.*100;
num=input('Cross Section? (mm2) ');
stress=load_N./num;

%% Plot Stress vs Strain
plot(strain,stress,'LineWidth',2,'Color',[0 0 0]);
xlabel('Strain Percent (%)','FontWeight','bold','FontSize',12);
title(strcat(foldername,': Stress vs Tissue Strain'),'FontSize',20);
ylabel('Stress (mPa)','FontWeight','bold','FontSize',12);
figname=(strcat(foldername,'_Stress_Strain_Curve'));
savefig(figname) 
save(foldername,'stress','strain')
