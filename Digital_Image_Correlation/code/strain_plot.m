%Plot Strain Graphs

%Load Strain
if exist('valid_strain')==0 || isempty(valid_strain)
        % file with the list of filenames to be processed
        valid_strain='valid_strain.dat';
        if exist(valid_strain,'file') 
            load(valid_strain,'valid_strain');
        else
            uiwait(msgbox('Select Folder Containing Tracks'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            valid_strain=strcat(PathNameBase,'valid_strain.dat');
            load valid_strain.dat
        end
end

% Create plot
time=1:length(valid_strain);
plot(time,valid_strain,'LineWidth',2,'Color',[0 0.447058826684952 0.74117648601532]);
xlabel('Time / Step','FontSize',14);
title({'Tissue Strain'},'FontSize',16);
ylabel(['Strain (', char(949), ')'],'FontSize',14);

