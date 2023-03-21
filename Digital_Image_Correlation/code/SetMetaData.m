% Write meta data to file 
function SetMetaData(FileName,MetaData)

    FileId=fopen(FileName,'wt');
    
    MetaDataNames=fieldnames(MetaData);
    for Field = 1:size(MetaDataNames,1);
        CurrentFieldValue=getfield(MetaData,MetaDataNames{Field});
        WriteLine(FileId,MetaDataNames{Field},CurrentFieldValue);
    end

    fclose(FileId);
end

function WriteLine(FileId,ParameterName,ParameterValue)
    fprintf(FileId,'%s: %s\n',ParameterName,ParameterValue);
end
