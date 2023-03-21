% Get cpcorr data: corrsize and version (original cpcorr.m=default or modified diccpcorr.m=local)
function CpCorrData=GetCpCorrData()

    CpcorrFileName='cpcorr'; % default
    CorrSize=0;
    LocalCpcorrFileName='diccpcorr';
    LocalCpcorr=0;
    if exist(LocalCpcorrFileName,'file')==2
        CpcorrFileName=LocalCpcorrFileName;
        LocalCpcorr=1;

        % Get corrsize
        CorrSize=15;
        Prompt={'Enter corrsize (size of image part selected for correlation):'};
        DlgTitle='Corrsize';
        DefValue={num2str(CorrSize)};
        Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
        CorrSize=str2double(cell2mat(Answer(1,1)));
   
    end
    CpCorrData=struct('CorrSize',CorrSize,'FunctionFileName',CpcorrFileName,'Local',LocalCpcorr,'ImageStackSize',1);

end

