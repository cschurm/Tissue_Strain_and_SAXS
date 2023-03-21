% Code for stress-strain-match based on load file, time-image and results of displacement
% Programmed by Tobias and Benjamin, revised by Melanie
% Last revision: 04/28/16
function PropertyAnalysisDuctile

%% PART 1: preparation for stress-image-match
%  ------------------------------------------------------------------------
%% PART 1.1: Plot offset voltage

%clear all;
%close all;

% read in: load file
[Load_Import,PathImage] = uigetfile({'*.*','All Files (*.*)';...
                                     '*.csv','Character Separated Values (.csv)';...
                                     '*.txt','text-files (.txt)';...
                                     '*.dat','data-files (.dat)'},...
                                     'choose load file (if necessary: change directory)');
cd(PathImage);

load1=importdata(Load_Import,'\t');
load=load1.data;

%import header
fileID = fopen(Load_Import,'r');
head = textscan(fileID, '%s%s%s%[^\n\r]', 3, 'Delimiter', '\t', 'ReturnOnError', false);
fclose(fileID);

% plot sample number vs. voltage/AIM: choose offset
%timeconversion2;
stress=load(:,1);
stress(:,2)=load(:,2);
figure('Name','choose offset','NumberTitle','off');
plot(stress(:,1),stress(:,2),'.r');
title('plot sample number vs. voltage');
xlabel('sample num [1]');
ylabel('voltage [V]');

%% PART 1.2: Import dimensions

files1=dir('*.txt');

g=1;
S_find_dim(1,1)=0;

for i=1:size(files1,1)
        s=files1(i).name;
        S_find_help_dim=findstr(s,'dimensions');
        
        if S_find_help_dim==1
            S_find_dim(g,1)=S_find_help_dim;
            g=g+1;       
        end
end

[w q]=size(S_find_dim);

% Import: later 

%% PART 1.3: Calculate stress

% OFFSSET VOLTAGE: CALCULATE OR INPUT OF APPROX: VALUE

select_offset=menu(sprintf('Do you want to calculate the voltage offset?'),...
    'yes (calculate)','no (input of approximated values)');


%CASE 1: CHOOSE ARRAY FROM PLOT TO CALCULATE OFFSET
if select_offset==1                                                                 
    
    [xgrid,ygrid]=ginput(2);                                                        %sample-tool
            x(1,1) = xgrid(1);
            x(1,2) = xgrid(2);
            y(1,1) = ygrid(2);
            y(1,2) = ygrid(1);
       
    mean_points=find(stress(:,1)>min(x) & stress(:,1)<max(x)...                     %read-in: extract points
            & stress(:,2)<max(y) & stress(:,2)>min(y));
               
    mean_help=stress(mean_points(1):mean_points(end),1);
    mean_help(:,2)=stress(mean_points(1):mean_points(end),2);
    
    figure('Name','chosen offset-array','NumberTitle','off');                       %display: choosen points
    plot(mean_help(:,1),mean_help(:,2),'+g');
    xlabel('sample number [1]');
    ylabel('voltage [V]');
    
    % decide: are points ok?
    select_mean=menu(sprintf('Do you want to choose these points?'),'Yes','No');    %verification
    if      select_mean==1
                offset=mean(mean_help(1:end,2));
                clear x y xgrid ygrid;
                clear mean_help mean_points select_mean;
                close 'chosen offset-array';
    
            dlg_title ='please confirm or change offset';                           %input: probe-dimensions 
            prompt={'offset voltage [V]'};
            num_lines=[1,80];
            offset=num2str(offset);
            def={offset};
            options.Resize='on';
            answer=inputdlg(prompt,dlg_title,num_lines,def,options);
            offset=str2double(cell2mat(answer(1,1)));
        
            clear answer def dgl_title promt;
        
    elseif  select_mean==2
                close 'CHOSEN OFFSET-ARRAY';
                select_mean2 = menu(sprintf('Start again and \n choose another array'),'OK');
                clear all;
                close;% all;
                return;
               
    end
    
    
    if (S_find_dim(1,1)==1) && (w==1) && (q==1)                                         %input: probe-dimensions
        Dimension_Import=importdata('dimensions.txt','\t');                             %case: existing dimension file
        width=Dimension_Import.data(1,1);
        thickness=Dimension_Import.data(1,2);
        calib=19.98699;
    else                                                                                %case: non existing dimension file
        dlg_title =...
        'please specify the properties (in order to calculate stress)';                    
        prompt = {'calibration factor [N/V]','width [mm]','thickness [mm]', 'sample name'};
        num_lines=[1,80];
        calib = num2str(19.98699);
        width  = num2str(0.247);
        thickness =num2str(0.12);
        def={calib,width,thickness,''};
        options.Resize='on';
        answer = inputdlg(prompt,dlg_title,num_lines,def,options);
        calib= str2double(cell2mat(answer(1,1)));
        width = str2double(cell2mat(answer(2,1)));
        thickness = str2double(cell2mat(answer(3,1)));
        samplename = answer{4,1};
        clear dlg_title def num_lines prompt answer;
    end
    
%CASE 2: IMPUT OFFSET-VOLTAGE MANUALLY    
else                                                                       
    
    if (S_find_dim(1,1)==1) && (w==1) && (q==1)                                         %input: probe-dimensions
        Dimension_Import=importdata('dimensions.txt','\t');                             %case: existing dimension file
        width=Dimension_Import.data(1,1);
        thickness=Dimension_Import.data(1,2);
        dlg_title=...
        'please specify the voltage parameters (in order to calculate stress)';          %case: non existing dimension file AND offset-voltage        prompt = {'offset voltage [V]'};
        prompt = {'calibration factor [N/V]','offset voltage [V]',};
        num_lines = [1, 90];
        calib=num2str(19.98699);
        offset  = num2str(-2.17);
        def={calib,offset};
        options.Resize='on';
        answer = inputdlg(prompt,dlg_title,num_lines,def,options);
        calib = str2double(cell2mat(answer(1,1)));
        offset = str2double(cell2mat(answer(2,1)));
        clear answer;
        
    else
        dlg_title=...
        'please specify the properties (in order to calculate stress)';               %input: offset-voltage AND probe-dimensions
        prompt = {'calibration factor [N/V]','offset voltage [V]','width [mm]','thickness [mm]', 'sample name'};
        num_lines = [1, 80];
        calib = num2str(19.98699);
        offset  = num2str(-2.17);
        width  = num2str(0.247);
        thickness = num2str(0.12);
        def={calib,offset,width,thickness,''};
        options.Resize='on';
        answer = inputdlg(prompt,dlg_title,num_lines,def,options);
        calib= str2double(cell2mat(answer(1,1)));
        offset = str2double(cell2mat(answer(2,1)));
        width = str2double(cell2mat(answer(3,1)));
        thickness = str2double(cell2mat(answer(4,1)));
        samplename = answer{5,1};
        clear dlg_title def num_lines prompt answer;
    end
        
end

clear Load_Import PathImage select_offset;                                     %clear useless regarding this part
close 'choose offset';

clear S_find_dim w q S_find_help_dim;                                               %clear variables of dimension import

%% PART 1.4: Computation of stress/generate data-Matrix-> intersection to PART 2

stress(:,3)=stress(:,2)-offset;
stress(:,4)=stress(:,3)*calib;
stress(:,5)=stress(:,4)/(width*thickness);

data=stress(:,1);                                                                   %data is final matrix: column 1: sample number
data(:,2)=stress(:,5);                                                              %column 2: stress [MPa]

%clear offset calib width thickness stress;
clear stress;


%% PART 1.5: Startingtime load

header=head{1,1};
header2=head{1,2};
info=strsplit(header{1,1});
%info=cell2mat(info);
%info=textscan(info,'%s %s %s %s %s %s %s %s','delimiter', ' ');
%time1=cell2mat(info{1,3});
%time0=strtok(time1,'M');
[h,m,s]=strread(info{1,3},'%f %f %f','delimiter',':');
loadstart=h*3600+m*60+s;
clear h m s;
clear time1 time0;
clear load1;

%% PART 1.6 Read-out frequeny

freq1=strsplit(header2{1,1});
freq2=strrep(freq1(1,3), ',', '.');
freq=str2double(freq2);
clear freq1;
clear freq2;

daq=data;                                                                   %calculate timebase in s
daq(:,1)=(daq(:,1))/freq;

clear data;
clear info;

%% PART 1.7 Open time_image

g=1;
S_find(1,1)=0;
for i=1:size(files1,1)
        s=files1(i).name;
        S_find_help=findstr(s,'time_image');
        
        if S_find_help==1
            S_find(g,1)=S_find_help;
            g=g+1;       
        end
end

[w q]=size(S_find);

if (S_find(1,1)==1) && (w==1) && (q==1)
    Time_Import=importdata('time_image.txt','\t');
elseif (S_find(1,1)==1) && (S_find(2,1)==1)
    [Time_Import,PathImage] = uigetfile('*.txt','There are few time_image files. Please choose the correct one.');
    cd(PathImage);
    Time_Import=importdata(Time_Import,'\t');
else
    [Time_Import,PathImage] = uigetfile('*.txt','Please select the time_image file.');
    cd(PathImage);
    Time_Import=importdata(Time_Import,'\t');
end;

clear g w q;
clear files1 S_find S_find_help;

time_image=Time_Import;

%interpolate time if there are pictures having the same time
k=1;
i=0;
tis=size(time_image);
imt=time_image;
imt(:,2)=imt(:,2)-imt(1,2);
for i = 2:tis(1,1)
    if (imt(i,2)==imt(i-1,2))
        k=k+1;
    else
        for m=0:k-1
            time_cor(i-k+m,1)=imt(i-k+m,1);
            time_cor(i-k+m,2)=imt(i-k+m,2);
            time_cor(i-k+m,3)=imt(i-1,2)+m/k;            
        end                
            k=1;      
            time_cor(i,1)=imt(i,1);
            time_cor(i,2)=imt(i,2);
            time_cor(i,3)=imt(i,2);
    end
end
clear k i m tis imt;
%end of interpolation

Time_Image(:,1)=time_cor(2:end,1);
Time_Image(:,2)=time_cor(2:end,3);

clear Time_Import PathImage;


%% PART 1.8 Startingtime acquisition pics

strainstart=time_image(1,2);
timeshift=strainstart-loadstart; %Diesen Term mit Anzahl Stunden in vielfaches von 24 hinzufügen, wenn Messfile seit Tagen lief +(24*3600);


%% ------------------------------------------------------------------------
%% PART 2: Stress-image-match
%  ------------------------------------------------------------------------
%% PART 2.1: Match

exptime=1;                                                                  % column of exp. Time und Stress
expstress=2;


%% PART 2.2 Interpolate time if there are pictures having the same time

k=1;
i=0;
tis=size(time_image);
imt=time_image;
imt(:,2)=imt(:,2)-imt(1,2);
for i = 2:tis(1,1)
    if (imt(i,2)==imt(i-1,2))
        k=k+1;
    else
        for m=0:k-1
            time_cor(i-k+m,1)=imt(i-k+m,1);
            time_cor(i-k+m,2)=imt(i-k+m,2);
            time_cor(i-k+m,3)=imt(i-1,2)+m/k;            
        end                
            k=1;      
            time_cor(i,1)=imt(i,1);
            time_cor(i,2)=imt(i,2);
            time_cor(i,3)=imt(i,2);
    end
end
clear k i m tis imt;
%end of interpolation

Time_Image(:,1)=time_cor(2:end,1);
Time_Image(:,2)=time_cor(2:end,3);


%% PART 2.3 Generate image_stress/load_index 


[loopimage widthtime]=size(Time_Image);

time_stress(:,1)=daq(:,exptime);                                            %daq=data in s-base (Frequenz); data=column 1 and 2 of stress
time_stress(:,2)=daq(:,expstress);


load_index=zeros(loopimage,3);
for j=1:loopimage
    minpos=time_stress(:,1)-Time_Image(j,2)-timeshift;
    impos=find(abs(minpos)==min(abs(minpos)));
    image_stress(j,1)=j;
    image_stress(j,2)=mean(time_stress(impos,2));
    for k=1:size(impos,1)
        load_index(j,k)=impos(k,1);
    end
    
    %timelog(j,1)=mean(time_stress(impos,1)); %for debugging
    %image_stress(j,3)=mean(time_stress(impos,3));
end

clear k;


%% ------------------------------------------------------------------------
%% PART 3 stress-strain-match
%  ------------------------------------------------------------------------
%% PART 3.1 read in strain file
% read in: load file

[Strain_Import,PathImage] = uigetfile({'*.*','All Files (*.*)';...
                                     '*.csv','Character Separated Values (.csv)';...
                                     '*.txt','Text-files (.txt)';...
                                     '*.dat','Data-files (.dat)'},...
                                     'choose strain file (if necessary: change directory)');
cd(PathImage);

strain=importdata(Strain_Import,' ');

clear Strain_Import PathImage;


%% PART 3.2 stress-strain-match
% based on time_stress

D=['load cell offset: ',num2str(offset), ' [V]'];
E=['sample width: ',num2str(width), ' [mm]'];
F=['sample thickness: ',num2str(thickness), ' [mm]'];
G=['load cell calibration factor: ',num2str(calib), ' [N/V]'];
figtitle=strcat([D,', ', E,', ', F,', ', G, ', ']);


stress_length=size(image_stress,1);

  final_plot(:,1)=strain(1:stress_length,2);
final_plot(:,2)=image_stress(:,2);
handle_plot_unshift=figure('Name','unshifted stress-strain','NumberTitle','off','units','normalized','position',[0,0,1,1]);
plot(final_plot(:,1),final_plot(:,2),'.r');
xlabel('strain [ ]');
ylabel('stress [MPa]');
title(figtitle)


%% PART 3.3 generate directory for saving of analysis-files

old_directory=pwd;
    
    dlg_title = 'make new directory';                                                %input: directory
        prompt = {'create a new folder to save succesful plots (including matrices) in'};
        num_lines = [1,80];
        directory='analysis1';
        def={directory};
        options.Resize='on';
        answer=inputdlg(prompt,dlg_title,num_lines,def,options);
        directory=(cell2mat(answer(1,1)));
        
mkdir(directory);
cd(directory);
        
clear answer;
clear def dlg_title prompt;


%% PART 3.4 shift of stress-strain-points

% SHIFT: IMPOROVE FILE OR SAVE IT
select_shift=menu(sprintf('Do you want to shift the match'),...                 % interaction
    'yes (improve match)','no (save plot in file and leave program)');


% CASE 1: SHIFT!
if select_shift==1                                                             
    
    i=1;
           
    while (select_shift==1)                                                     %possibility: shift serveral times     
    
        dlg_title ='shift (consider sign because of shift-direction)';          %configure shift
            prompt = {'step of shift (regarding sample number)'};
            num_lines=[1,80];
            step=num2str(1);
            def={step};
            options.Resize='on';
            answer=inputdlg(prompt,dlg_title,num_lines,def,options);
            step_string=cell2mat(answer(1,1));
            step=str2double(step_string);
            
            clear answer;
            clear step_string;
            clear def dlg_title prompt;            
            
        
                         
        image_stress_shift(:,1)=image_stress(:,1);                              %execute shift
        image_stress_shift(:,2)=daq(load_index(:,1)+step,2);
            
        
        stress_length_shift=size(image_stress_shift,1);
        final_plot_shift(:,1)=strain(1:stress_length_shift,2);
        final_plot_shift(:,2)=image_stress_shift(:,2);
        
        
        %plot shifted Matrix
        handle_plot_shift=figure('Name','shifted stress-strain-plot','NumberTitle','off','units','normalized','position',[0,0,1,1]);
        
        if i==1                                                                 %case 1: first shift (first plot in figure is the unshifted one)
            
            subplot(211);
            plot(final_plot(:,1),final_plot(:,2),'.r');
            xlabel('strain [ ]');
            ylabel('stress [MPa]');
            f=load(load_index(1,1),1);
            title(strcat([figtitle, ' shift: 0', ', first sample number: ',num2str(f)]));
            %text(0.005,0,['shift: 0','   ','first sample number: ',num2str(f)]);
            subplot(212);
            plot(final_plot_shift(:,1),final_plot_shift(:,2),'.g');
            xlabel('strain [ ]');
            ylabel('stress [MPa]');
            g=load_index(1,1)+step;
            g1=load(g,1);
            title(strcat([figtitle, ' shift: ', num2str(step), ', first sample number: ',num2str(g1)]));
            %text(0.005,0,['shift: ',num2str(step),'   ','sample number of first load value: ',num2str(g1)]);
            
        elseif i>1                                                              %case 2: all further shifts (first plot in figure is last shifted plot)
            
            subplot(211);
            plot(final_plot_shift_old(:,1),final_plot_shift_old(:,2),'.r');
            xlabel('strain [ ]');
            ylabel('stress [MPa]');
            title(strcat([figtitle, ' shift: ', num2str(step_old), ', first sample number: ',num2str(g_old)]));
            %text(0.005,0,['shift: ',num2str(step_old),'   ','first sample number: ',num2str(g_old)]);
            subplot(212);
            plot(final_plot_shift(:,1),final_plot_shift(:,2),'.g');
            xlabel('strain [ ]');
            ylabel('stress [MPa]');
            g=load_index(1,1)+step;  
            g1=load(g,1);
            title(strcat([figtitle, ' shift: ', num2str(step), ', first sample number: ',num2str(g1)]));
            %text(0.005,0,['shift: ',num2str(step),'   ','sample number of first load value: ',num2str(g1)]);
            
        end    
            
            
        % QUERY (save) 
        
        select_save=menu(sprintf('Do you want to save this plot?'),...
                'Yes','No');
            
        if select_save==1
                       
            name_file=['final_stress_strain_file_shift',num2str(i)];            %flename
            
            a=load_index(1,1)+step;                                             %construction of header
            a1=load(a,1);
            A=['sample number of first load value: ',num2str(a1)];
            b=step;
            B=['timeshift: ',num2str(b), ' [sample numbers]'];
            C=['strain [ ]                  stress[MPa]'];
            
            
            dlmwrite(name_file,A,'delimiter','');                               %saving martix in file with header
            dlmwrite(name_file,B,'-append','delimiter','');
            dlmwrite(name_file,D,'-append','delimiter','');
            dlmwrite(name_file,E,'-append','delimiter','');
            dlmwrite(name_file,F,'-append','delimiter','');
            dlmwrite(name_file,G,'-append','delimiter','');
            
            dlmwrite(name_file,C,'-append','delimiter','','roffset',1);
            
            dlmwrite(name_file,final_plot_shift,'-append','delimiter','\t','precision','%+20.8d');
                                                                            
            
            
            name_figure=['final_stress_strain_plot_shift',num2str(i)];
            saveas(handle_plot_shift,name_figure,'fig');
            
            clear a a1 b;
            clear handle_plot_shift;                                  
            
            %Inkrementierung für Dateiname (->Abspeichern)
            i=i+1;
          
        end

        clear name_file name_figure;
        
        %query -> futher shift?
        select_shift=menu(sprintf('Do you want to shift the match AGAIN'),...
            'yes (improve match)','no (leave program)');
        
        if select_shift==1                                                      %if futher shift: transform variables -> to plot old/new graph in same plot
            close 'shifted stress-strain-plot';
            
            final_plot_shift_old=final_plot_shift;
            g_old=g1;
            step_old=step;
        end
        
    end 

    cd(old_directory);

clear directory old_directory;


% CASE 2: SHIFT is not necessary
elseif select_shift==2
    
    %save matrix!
    a=load_index(1,1);
    a1=load(a,1);
    A=['sample number of first load value: ',num2str(a1)];
    C=['strain [ ]                  stress[MPa]'];
    dlmwrite('final_stress_strain_file.txt',A,'delimiter','');
    dlmwrite('final_stress_strain_file.txt','timeshift: 0 [sample numbers]','-append','delimiter','');
    dlmwrite('final_stress_strain_file.txt',D,'-append','delimiter','');
    dlmwrite('final_stress_strain_file.txt',E,'-append','delimiter','');
    dlmwrite('final_stress_strain_file.txt',F,'-append','delimiter','');
    dlmwrite('final_stress_strain_file.txt',G,'-append','delimiter','');
    dlmwrite('final_stress_strain_file.txt',C,'-append','delimiter','','roffset',1);
    dlmwrite('final_stress_strain_file.txt',final_plot,'-append','delimiter','\t','precision','%+20.8d');
                                                                                              
    saveas(handle_plot_unshift,'final_stress_strain_figure','fig');
        
    cd(old_directory);
     
end

clear handle_plot_unshift;

clear A B C D E F G Time_Image a a1 ans calib daq directory expstress exptime figtitle fileID freq head header header2 image_stress impos j load load_index loadstart loopimage minpos num_lines offset old_directory;
clear options select_shift strain strainstart stress_length time_cor time_image time_stress timeshift widthtime;

StrainStressAnalysis(final_plot, width, thickness, samplename);

clear  final_plot samplename thickness width;
% close 'STRESS-STRAIN';
close;