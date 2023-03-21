% Construct a list of 9999 or less filenames
% Programmed by Rob, changed by Chris. Automatic filelist generation and image time aquisition added by Chris, revised by Melanie
% Last revision: 04/28/16
function [FileNameList]=GenerateFileList

    % Possible image extensions
    ImageExtensions = {'tif','tiff','bmp','jpg','jpeg','png'};

    FileNameListMode = menu(sprintf('How do you want to create the filenamelist?'),'Manually','Automatically','Cancel');
    switch FileNameListMode
        case 1 
            [FileNameBase,PathNameBase,FileNameList]=GenerateFileListManually(ImageExtensions);
        case 2
            [FileNameBase,PathNameBase,FileNameList]=GenerateFileListAutomatically(ImageExtensions);
        otherwise
            return
    end	
    [FileNameBase,PathNameBase,FileNameList]=ExtractImageTime(FileNameBase,PathNameBase,FileNameList);

% Generate file list automatically (string and number part)
function [FirstImageName,ImageFolder,FileNameList]=GenerateFileListAutomatically(ImageExtensions)

    % Build image string from possible image extensions
    ImageString = [];
    NumOfExtensions = size(ImageExtensions,2);
    for Extension=1:NumOfExtensions
        ImageString = sprintf('%s*.%s;',ImageString,ImageExtensions{Extension});
    end

    drawnow
    [FirstImageName,ImageFolder]=uigetfile(ImageString,'Open First Image');
    if ~isempty(FirstImageName)
        cd(ImageFolder);
    end

    if ~isempty(FirstImageName)

        % Get the number of image name
        Letters=isletter(FirstImageName);
        PointPosition=strfind(FirstImageName,'.');
        FirstImageNameSize=size(FirstImageName);
        Counter=PointPosition-1;
        CounterPos=1;
        LettersTest=0;
        while LettersTest==0
            LettersTest=Letters(Counter);
            if LettersTest==1
                break
            end
            NumberPos(CounterPos)=Counter;
            Counter=Counter-1;
            CounterPos=CounterPos+1;
            if Counter==0
                break
            end
        end

        % Get the string (prefix) of image name
        MinNumberPos=min(NumberPos);
        MaxNumberPos=max(NumberPos);
        ImageFileName=FirstImageName(1:MinNumberPos-1);
        ImageFileNumber=FirstImageName(MinNumberPos:MaxNumberPos);
        ImageExtensionName = FirstImageName(MaxNumberPos+1:FirstImageNameSize(1,2));
        FileNameList(1,:)=FirstImageName;
 
        NumOfDigits = MaxNumberPos-MinNumberPos+1;
        FormatString = sprintf('%%0%dd',NumOfDigits);

        % Get image list
        ExistingFileList=dir;
        ExistingFileList=arrayfun(@(x) getfield(x, 'name'),ExistingFileList,'UniformOutput',false);
        ImageFileNumber=str2num(ImageFileNumber);
        Number=ImageFileNumber+1;
        NumberString=sprintf(FormatString,Number);  
        Counter=1;
        NextFileName=[ImageFileName NumberString ImageExtensionName];
        while find(strcmp(ExistingFileList,NextFileName))
            FileNameList(Counter+1,:)=NextFileName;
            Counter=Counter+1;
            Number=Number+1;
            NumberString=sprintf(FormatString,Number);     
            NextFileName=[ImageFileName NumberString ImageExtensionName];
        end
    end
    [FileNameBase,PathNameBase] = uiputfile('filenamelist.mat','Save as "filenamelist" in image directory (recommended)');
    cd(PathNameBase)
    save(FileNameBase,'FileNameList');

% Generate file list manually (string and number part separately)
function [FileNameBase,PathNameBase,FileNameList]=GenerateFileListManually(ImageExtensions)

    % Prompt user for images to be used for analysis  
    Prompt = {'Enter number of first image (i.e. "3" for PIC00003):','Enter number of last image (i.e. "100" for PIC00100):'};
    DlgTitle = 'Input images to be used for the analysis';
    DefValues = {'1','100'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValues);
    StartFileNumber = str2num(cell2mat(Answer(1,1)));
    EndFileNumber = str2num(cell2mat(Answer(2,1)));

    MaxFileNumber=10000;
    if  EndFileNumber >= MaxFileNumber
        menu('!!! ERROR - Code will only work properly for 9999 or less picture files !!!','Restart');
        return
    end

    % Choose prefix (string name) of images
    DefValue = 'PIC1';
    Prompt = {'Enter image name (fix leading letters + numbers):'};
    DlgTitle = 'Input images to be used for the analysis';
    Answer = inputdlg(Prompt,DlgTitle,1,{DefValue});
    Prefix = cell2mat(Answer(1,1));

    % Choose image extension
    ImageExtensionNumber = menu(sprintf('Choose image extension'),ImageExtensions);
    ImageExtension=ImageExtensions{ImageExtensionNumber};
    ImageExtension=sprintf('.%s',ImageExtension);
    ImageExtensionLength=size(ImageExtension,2);
    
    % Choose number of digits in number
    DefValue = '4';
    Prompt = {'Enter number of digits for image number:'};
    DlgTitle = 'Input images to be used for the analysis';
    Answer = inputdlg(Prompt,DlgTitle,1,{DefValue});
    NumOfDigits = str2num(cell2mat(Answer(1,1)));
    FormatString = sprintf('%%0%dd',NumOfDigits);

    % Create the list (name + number + image file extension)
    NumOfFiles = EndFileNumber-StartFileNumber+1;
    Numbers=(StartFileNumber:EndFileNumber)';
    for FileCount=1:NumOfFiles
        NumbersString(FileCount,:)=sprintf(FormatString,Numbers(FileCount));     
    end
    NumbersStringLength=size(NumbersString,2);
    PrefixLength = size(Prefix,2);
    FileNameList = zeros(NumOfFiles,PrefixLength+NumbersStringLength+ImageExtensionLength);
    NumbersStringStart = PrefixLength+1;
    NumbersStringEnd = NumbersStringStart+NumbersStringLength-1;
    ImageExtensionStart = NumbersStringEnd+1; 
    ImageExtensionEnd = ImageExtensionStart+ImageExtensionLength-1;
    for FileCount=1:NumOfFiles
        FileNameList(FileCount,1:PrefixLength)=Prefix;
        FileNameList(FileCount,NumbersStringStart:NumbersStringEnd)=NumbersString(FileCount,:);
        FileNameList(FileCount,ImageExtensionStart:ImageExtensionEnd)=ImageExtension;
    end
    FileNameList = char(FileNameList);

    % Save results
    [FileNameBase,PathNameBase] = uiputfile('filenamelist.mat','Save as "filenamelist" in image directory (recommended)');
    cd(PathNameBase)
    save(FileNameBase,'FileNameList');

% Extract the time from images?
function [FileNameBase,PathNameBase,FileNameList]=ExtractImageTime(FileNameBase,PathNameBase,FileNameList)

    ResultFileName='timeimage.txt';

    ExtractTime = menu(sprintf('Do you also want to extract the time from images to match stress and strain?'),'Yes (from file properties)','Yes (from file "time.txt")','No');
    switch ExtractTime
        case 1 % File properties
            % Loop through all images to get all image capture times
            [NumOfFiles,~]=size(FileNameList);
            WaitBar=waitbar(0,'Extracting the image capture times...');
            Seconds = zeros(1,NumOfFiles);
            for File=1:NumOfFiles
                waitbar(File/NumOfFiles);
                Info=imfinfo(FileNameList(File,:));
                Time=datevec(Info.FileModDate,13);
                Seconds(File)=Time(1,4)*3600+Time(1,5)*60+Time(1,6);
            end
            close(WaitBar)

            % Configure and then save image number vs. image capture time text file
            CaptureTimes=[(1:NumOfFiles)' Seconds'];
            save(ResultFileName,'CaptureTimes','-ascii','-tabs');
        case 2 % File "time.txt"
           ConvertTime(ResultFileName); 
    end
    
function ConvertTime(ResultFileName)
    files1=dir('*.txt');
    g=1;
    for i=1:size(files1,1)
            s=files1(i).name;
            S_find_help=findstr(s,'time');

            if S_find_help==1
                S_find(g,1)=S_find_help;
                g=g+1;       
            end
    end

    if size(files1,1)==0
        S_find(1,1)=0;
    end

    [w q]=size(S_find);

    if (S_find(1,1)==1) && (w==1) && (q==1)
        Time_Import=importdata('time.txt','\t');
    elseif (S_find(1,1)==1) && (S_find(2,1)==1)
        [Time_Import,PathImage] = uigetfile('*.txt','There are few time.txt files. Please choose the correct one.');
        cd(PathImage);
        Time_Import=importdata(Time_Import,'\t');
    else
        [Time_Import,PathImage] = uigetfile('*.txt','Please select the time.txt file.');
        cd(PathImage);
        Time_Import=importdata(Time_Import,'\t');
    end;

    FileContent=Time_Import;

    % Result file (write)
    ResultFile = fopen(ResultFileName, 'w');

    % Start offset (in seconds) can be specified here
    StartOffset = 0.0;    

    % Replace time stamps in file (row by row)
    NumOfTimeStamps = size(FileContent, 1);
    
    % Get numbers in first and last file name
    FirstFileName=strsplit(FileContent{1,1},'\t');
    FirstFileName=FirstFileName{1,3};
    LastFileName=strsplit(FileContent{NumOfTimeStamps,1},'\t');
    LastFileName=LastFileName{1,3};
    F2Letters=isletter(FirstFileName);
    F2Letters=FirstFileName(~F2Letters);
    F2=str2num(F2Letters);
    FLetters=isletter(LastFileName);
    FLetters=LastFileName(~FLetters);
    F=str2num(FLetters);
    
    for TimeStep = (F2):(F)
        RowCount=(TimeStep-F2+1);
        CurrentRow = FileContent(RowCount, 1);
        CurrentRow = textscan(CurrentRow{1, 1}, '%s %s', 'delimiter', '\t');
        CurrentTimeStamp = textscan(CurrentRow{1, 1}{1, 1}, '%s %s', 'delimiter', ',');
        CurrentTimeStamp = textscan(CurrentTimeStamp{1, 1}{1, 1}, '%f %f %f', 'delimiter', ':');
        CurrentTimeStampInSeconds = CurrentTimeStamp{1, 1} * 3600 + CurrentTimeStamp{1, 2} * 60 + CurrentTimeStamp{1, 3};   % Convert time
        %if TimeStep == 1
        %    StartOffset = CurrentTimeStampInSeconds - StartOffset;  % Calculate reference value
        %end
        CurrentTimeStampInSeconds = CurrentTimeStampInSeconds - StartOffset;    % Calculate relative value (with repect to reference value) 
        %fprintf(ResultFile, '%1.7f\t%s\n', CurrentTimeStampInSeconds, CurrentRow{1, 2}{1, 1});    % Write results
        fprintf(ResultFile, '%1.7e\t%1.7e\r\n', RowCount, CurrentTimeStampInSeconds);    % Write results
    end

    fclose(ResultFile);
