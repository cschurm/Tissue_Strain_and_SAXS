% Get meta data from file 
function MetaData = GetMetaData(FileName)

    MetaDataNames={'Sample_Name','Sample_Material_E','Sample_Material_v','Sample_Geometry','Instrument_Name','Instrument_Operator','Instrument_Status','Measurement_Time','PostProc_SelectedCorrCoef'};
    MetaData=struct(MetaDataNames{1},'',MetaDataNames{2},nan,MetaDataNames{3},nan,MetaDataNames{4},'',MetaDataNames{5},'',MetaDataNames{6},'',MetaDataNames{7},'',MetaDataNames{8},'',MetaDataNames{9},0);
    EOL=sprintf('\n'); % End line character
    
    % Read from meta data file
    if exist(FileName,'file')
        FileId=fopen(FileName,'rt');
        Input=fread(FileId,'*char')';
        
        % Assign values
        MetaData.Sample_Name=GetValue(Input,MetaDataNames{1},EOL);
        MetaData.Sample_Material_E=str2num(GetValue(Input,MetaDataNames{2},EOL));
        MetaData.Sample_Material_v=str2num(GetValue(Input,MetaDataNames{3},EOL));
        MetaData.Sample_Geometry=GetValue(Input,MetaDataNames{4},EOL);
        MetaData.Instrument_Name=GetValue(Input,MetaDataNames{5},EOL);
        MetaData.Instrument_Operator=GetValue(Input,MetaDataNames{6},EOL);
        MetaData.Instrument_Status=GetValue(Input,MetaDataNames{7},EOL);
        MetaData.Measurement_Time=GetValue(Input,MetaDataNames{8},EOL);
        MetaData.PostProc_SelectedCorrCoef=str2num(GetValue(Input,MetaDataNames{9},EOL));
    else
        FileId=fopen(FileName,'w');
    end
    fclose(FileId);
end

function Value = GetValue(Input,Name,EOL)
    CurrentStartPos=strfind(Input,Name)+length(Name)+2;
    if isempty(CurrentStartPos)
        Value='nan'; % Not found
    else
        CurrentEndPos=strfind(Input(1,CurrentStartPos:end),EOL);
        CurrentString=Input(1,CurrentStartPos:CurrentStartPos+CurrentEndPos(1,1)-2);
        Value=CurrentString;
    end
end
