% Strain Analysis
% Programmed by Chris
% Revised by Melanie
% Last revision: 04/28/16
function [XI,YI,ZI,Eps]=StrainAnalysis(ValidX,ValidY,StdX,StdY,Direction,Mode,Type)

    switch Direction
        case 'x' % x-direction
            Displ=GetMeanDisplacement(ValidX);
            Valid=ValidX;
        case 'y' % y-direction
            Displ=GetMeanDisplacement(ValidY);
            Valid=ValidY;
        otherwise % invalid
            return
    end
    
    % Get displacement depending on direction
    XI=[];
    YI=[];
    ZI=[];
    Eps=[];
    
    % mode is either gui (with visualization) or silent (without visualization)
    switch Mode
        case 'silent'
            switch Type
                case 'FullStrain2D'
                    [XI,YI,ZI,Eps]=GetFullStrain2D(ValidX,ValidY,Displ);
                case 'AverageStrain1D'
                    Eps=Calculate1DStrain(Valid,Displ,Direction);
                otherwise % Cancel
            end        
            return
    end

    Selection = menu(sprintf('How do you want to visualize your data?'),...
                             'Average strain 1D','Average strain 1D (direction-independent)','Local strain 1D','Full strain 2D',...
                             'Strain between 2 points 1D','Principal strains','Go Back');
    switch Selection
        case 1 % Average strain 1D
            AverageStrain1D(ValidX,ValidY,Displ,Direction);
        case 2 % Average strain 1D
            AverageStrain1DPrincipal(ValidX,ValidY);
        case 3 % Local strain 1D
            LocalStrain1D(ValidX,ValidY,Direction);
        case 4 % Full strain 2D
            FullStrain2D(ValidX,ValidY,Displ,Direction);
        case 5 % Strain between 2 points 1D
            Strain2Points1D(ValidX,ValidY,Displ,Direction);
        case 6 % Principal strains
            PrincipalStrains(ValidX,ValidY,StdX,StdY);
        otherwise % Cancel
            return
    end
    
 % Create grid based on ValidX,ValidY
 function [XI,YI]=CreateGrid(ValidX,ValidY)
 
    GridSizeX=10*round(min(min(ValidX))/10):10:10*round(max(max(ValidX))/10);
    GridSizeY=10*round(min(min(ValidY))/10):10:10*round(max(max(ValidY))/10);
    [XI,YI]=meshgrid(GridSizeX,GridSizeY);
    
% Calculate and plot averaged strain (in x- or y-direction) by curve fitting for each image 
function AverageStrain1D(ValidX,ValidY,Displ,Direction)
    
    switch Direction
        case 'x' % x-direction
            Valid1=ValidX;
            Valid2=ValidY;
        case 'y' % y-direction
            Valid1=ValidY;
            Valid2=ValidX;
        otherwise % invalid
            return
    end
    
    VideoSelection = menu(sprintf('Do you want to create a video?'),'Yes','No');
    if VideoSelection==1
        DirName='videostrain';
        mkdir(DirName);
        cd(DirName);
    end
    
    % True strain or engineering strain
    NumOfMarkers=size(Valid1,1);
    NumOfImages=size(Valid1,2);
    StrainTypeSelection = menu(sprintf('Which strain type do you want to analyze?'),'True (current marker positions)','Engineering (initial marker positions)','Cancel');
    switch StrainTypeSelection
        case 1 % True
            % no modification
            StrainType='true';
        case 2 % Engineering
            Valid1=repmat(Valid1(:,1),1,NumOfImages);
            StrainType='engineering';
        otherwise % Cancel
            return       
    end
    
    % Strain gage
    GageSelection = menu(sprintf('Do you want to use a strain gage for measurement?'),'Yes','No');
    switch GageSelection
        case 1 % Yes
            GageFigure=figure;   
            Continue=2;
            while Continue==2
                plot(Valid1(:,1),Valid2(:,1),'.g')
                minminvalid1=min(min(Valid1(:,1)));
                maxmaxvalid1=max(max(Valid1(:,1)));
                prompt = {'Gage starts [pixel]:','Gage length [pixels]:','Area around limits [pixels]'};
                dlg_title = 'Define the length of the gage section for strain measurement';
                num_lines = 2;
                def = {num2str(minminvalid1+107.5),'1100','215'};
                answer = inputdlg(prompt,dlg_title,num_lines,def);
                minx= str2num(cell2mat(answer(1,1)));
                maxx= str2num(cell2mat(answer(1,1)))+str2num(cell2mat(answer(2,1)));
                halfwidth=str2num(cell2mat(answer(3,1)))/2;
                selectedmarkersengmin=find(Valid1(:,1)>minx-halfwidth  & Valid1(:,1)<minx+halfwidth);
                selectedmarkersengmax=find(Valid1(:,1)>maxx-halfwidth  & Valid1(:,1)<maxx+halfwidth);
                hold on
                plot(Valid1(selectedmarkersengmin,1),Valid2(selectedmarkersengmin,1),'.r')
                plot(Valid1(selectedmarkersengmax,1),Valid2(selectedmarkersengmax,1),'.b')
                hold off
                drawnow
                Continue = menu(sprintf('Do you want to use the selected markers for strain measurement?'),'Yes','No');
            end
            close(GageFigure);
            Valid1Gage=Valid1([selectedmarkersengmin; selectedmarkersengmax],:);
            DisplGage=Displ([selectedmarkersengmin; selectedmarkersengmax],:);
        otherwise % No    
            Valid1Gage=zeros(NumOfMarkers,NumOfImages);
            DisplGage=zeros(NumOfMarkers,NumOfImages);
    end
    
    % Calculate strain and plot displacement
    [Eps,EpsGage]=GetAverageStrain1D(Valid1,Valid1Gage,Displ,DisplGage,GageSelection,VideoSelection,Direction,StrainType);
 
    % Plot strain
    figure;   
    plot(Eps(:,1),Eps(:,2),'b');
    hold on
    plot(Eps(:,1),Eps(:,2),'b.');
    if GageSelection==1
        plot(EpsGage(:,1),EpsGage(:,2),'r');
    end
    xlabel('image');
    YLabel=sprintf('Mean %s strain in %s-direction',StrainType,Direction);
    ylabel(YLabel);
    Title=sprintf('Mean %s strain in %s-direction vs. image #',StrainType,Direction);
    title(Title);

    % Save fit data
    if VideoSelection==1
        cd('..');
    end
    FileName=sprintf('eulerianstrain%s%s.dat',StrainType,Direction);
    [FileName,PathName] = uiputfile(FileName,'Save file with image# vs. strain');
    cd(PathName);
    FileType='-ASCII';
    Delimiter='-tabs';
    save(FileName,'Eps',FileType,Delimiter);
    
    if GageSelection==1
        FileName=sprintf('gagestrain%s%s.dat',StrainType,Direction);
        [FileName,PathName] = uiputfile(FileName,'Save file with image# vs. strain for gage');
        cd(PathName);
        save(FileName,'EpsGage',FileType,Delimiter);

        % Save gage parameters
        FileName=sprintf('%sstrain%sgageparam.dat',StrainType,Direction);
        [FileName,PathName] = uiputfile(FileName,'Save file with gage parameters of strain measurement');
        cd(PathName);     
        fid = fopen(FileName,'w+');
        fprintf(fid,'%s\t%s\n%s\t%s\n%s\t%s\n', 'gage start [pixel]', num2str(minx), 'gage length [pixel]', num2str(maxx-minx), 'gage stripe width [pixel]', num2str(2*halfwidth));
        fclose(fid);  
    end
   
% Calculate and plot averaged strain (in principal direction) by curve fitting for each image 
function AverageStrain1DPrincipal(ValidX,ValidY)
       
    Direction='xy';
    DisplX=GetMeanDisplacement(ValidX);
    DisplY=GetMeanDisplacement(ValidY);
    Valid=(ValidX.^2+ValidY.^2).^(1/2);
    Displ=(DisplX.^2+DisplY.^2).^(1/2);
    
    VideoSelection = menu(sprintf('Do you want to create a video?'),'Yes','No');
    if VideoSelection==1
        DirName='videostrain';
        mkdir(DirName);
        cd(DirName);
    end
    
    % True strain or engineering strain
    NumOfMarkers=size(Valid,1);
    NumOfImages=size(Valid,2);
    StrainTypeSelection = menu(sprintf('Which strain type do you want to analyze?'),'True (current marker positions)','Engineering (initial marker positions)','Cancel');
    switch StrainTypeSelection
        case 1 % True
            % no modification
            StrainType='true';
        case 2 % Engineering
            Valid=repmat(Valid(:,1),1,NumOfImages);
            StrainType='engineering';
        otherwise % Cancel
            return       
    end
   
    ValidGage=zeros(NumOfMarkers,NumOfImages);
    DisplGage=zeros(NumOfMarkers,NumOfImages);
    
    % Calculate strain and plot displacement
    GageSelection=1;
    [Eps,EpsGage]=GetAverageStrain1D(Valid,ValidGage,Displ,DisplGage,GageSelection,VideoSelection,Direction,StrainType);
 
    % Plot strain
    figure;   
    plot(Eps(:,1),Eps(:,2),'b');
    hold on
    plot(Eps(:,1),Eps(:,2),'b.');
    xlabel('image');
    YLabel=sprintf('Mean %s strain in %s-direction',StrainType,Direction);
    ylabel(YLabel);
    Title=sprintf('Mean %s strain in %s-direction vs. image #',StrainType,Direction);
    title(Title);

    % Save fit data
    if VideoSelection==1
        cd('..');
    end
    FileName=sprintf('eulerianstrain%s%s.dat',StrainType,Direction);
    [FileName,PathName] = uiputfile(FileName,'Save file with image# vs. strain');
    cd(PathName);
    FileType='-ASCII';
    Delimiter='-tabs';
    save(FileName,'Eps',FileType,Delimiter);
    
 % Get 1D average strain by linear regression for one image
 function Beta=Get1DStrain(XData,YData,Beta)
    Beta=lsqcurvefit(@Line,[Beta(1) Beta(2)],XData,YData);
    
 % Get 1D average strain by linear regression for all images   
 function Eps=Calculate1DStrain(Valid,Displ,Direction)   
        
    NumOfImages=size(Valid,2);
    Eps=zeros(NumOfImages,3);
    Beta(1)=0;
    Beta(2)=0;
    
    for CurrentImage=1:NumOfImages;            
        XData=Valid(:,CurrentImage);
        YData=Displ(:,CurrentImage);        
        Beta=Get1DStrain(XData,YData,Beta);
        Eps(CurrentImage,:)=[CurrentImage Beta];
    end
    
    FileName=sprintf('strain%s.dat',Direction);
    save(FileName,'Eps','-ASCII','-tabs');
    
% Calculate averaged strain (in x- or y-direction) by curve fitting for each image 
function [Eps,EpsGage]=GetAverageStrain1D(Valid,ValidGage,Displ,DisplGage,GageSelection,VideoSelection,Direction,StrainType)   
    
    DisplFigure=figure;
    VideoStr='Vid';
    NumOfImages=size(Valid,2);
    Eps=zeros(NumOfImages,3);
    EpsGage=zeros(NumOfImages,3);
    
    for CurrentImage=1:NumOfImages;
        if CurrentImage==1
            Beta(1)=0;
            Beta(2)=0;
            BetaGage(1)=0;
            BetaGage(2)=0;
        end
        
        XData=Valid(:,CurrentImage);
        YData=Displ(:,CurrentImage);        
        Beta=Get1DStrain(XData,YData,Beta);
        Eps(CurrentImage,:)=[CurrentImage Beta];
        
        % Plot displacement over position
        plot(XData,YData,'ob');
        hold on
       
        Beta=Eps(CurrentImage,2:3);
        YDataPredicted=Line(Beta,XData);
        plot(XData,YDataPredicted,'b');
        
        if GageSelection==1
            XDataGage=ValidGage(:,CurrentImage);
            YDataGage=DisplGage(:,CurrentImage);
            plot(XDataGage,YDataGage,'.r');
            BetaGage=Get1DStrain(XDataGage,YDataGage,BetaGage);
            EpsGage(CurrentImage,:)=[CurrentImage BetaGage];
            BetaGage=EpsGage(CurrentImage,2:3);
            YDataPredictedGage=Line(BetaGage,XDataGage);
            plot(XDataGage,YDataPredictedGage,'r');
        end            

        hold off
        axis([min(min(Valid)) max(max(Valid)) min(min(Displ)) max(max(Displ))]);
        XLabel=sprintf('%s-position [pixel] for %s strain (blue), gage (red)',Direction,StrainType);
        xlabel(XLabel);
        YLabel=sprintf('%s-displacement [pixel]',Direction);
        ylabel(YLabel);

        Title=sprintf('Displacement in %s-direction versus %s-position',Direction,Direction);
        title([Title,sprintf(' (current image #: %1g, ',CurrentImage),sprintf('strain: %1g)',Beta(1))]);
        drawnow
        if VideoSelection==1
            Number=CurrentImage+10000;
            NumberStr=num2str(Number);
			VideoFileExtension='jpg';
            VideoName=[VideoStr NumberStr '.' VideoFileExtension];
            saveas(DisplFigure,VideoName,VideoFileExtension);
        end   
    end
    
% Calculate and plot the local resolved strain (for defined regions, e.g. 20) (in x- or y-direction) by the gradient for each image
function LocalStrain1D(ValidX,ValidY,Direction)

    SelectionFigure=figure;
    SizeValidX=size(ValidX);
    NumOfImages=SizeValidX(1,2);
    SelectedImage=SelectImage(NumOfImages);
    
    % Plot markers in the selected region
    plot(ValidX(:,SelectedImage),ValidY(:,SelectedImage),'+b');
    title(sprintf('Define the region of interest.\n Pick (single click) a point in the LOWER LEFT region of the gage section.\n  Do the same for a point in the UPPER RIGHT portion of the gage section.'));
    Labels={'x-position [pixel]','y-position [pixel]'};
    switch Direction
        case 'x' % x-direction
            xlabel(Labels{1,1});
            ylabel(Labels{1,2});
        case 'y' % y-direction
            xlabel(Labels{1,2});
            ylabel(Labels{1,1});
    end
    hold on
    [X(1,1),Y(1,1)]=ginput(1);
    plot(X(1,1),Y(1,1),'+b');
    plot([min(ValidX(:,SelectedImage)); max(ValidX(:,SelectedImage))], [Y(1,1); Y(1,1)],'-r');
    plot([X(1,1),X(1,1)], [min(ValidY(:,SelectedImage)),max(ValidY(:,SelectedImage))],'-r');

    [X(2,1),Y(2,1)]=ginput(1);
    hold on
    plot(X(2,1),Y(2,1),'+b');
    plot([min(ValidX(:,SelectedImage)); max(ValidX(:,SelectedImage))], [Y(2,1); Y(2,1)],'-r');
    plot([X(2,1),X(2,1)], [min(ValidY(:,SelectedImage)),max(ValidY(:,SelectedImage))],'-r');

    XMin = min(X);
    XMax = max(X);
    YMin = min(Y);
    YMax = max(Y);

    LowerLine=[XMin YMin; XMax YMin];
    UpperLine=[XMin YMax; XMax YMax];
    LeftLine=[XMin YMin; XMin YMax];
    RightLine=[XMax YMin; XMax YMax];

    plot(LowerLine(:,1),LowerLine(:,2),'-g');
    plot(UpperLine(:,1),UpperLine(:,2),'-g');
    plot(LeftLine(:,1),LeftLine(:,2),'-g');
    plot(RightLine(:,1),RightLine(:,2),'-g');

    SelectedPoints=find(ValidX(:,SelectedImage)>XMin & ValidX(:,SelectedImage)<XMax & ValidY(:,SelectedImage)<YMax & ValidY(:,SelectedImage)>YMin);

    ValidXNew=ValidX(SelectedPoints,:);
    ValidYNew=ValidY(SelectedPoints,:);

    hold on
    plot(ValidXNew(:,SelectedImage),ValidYNew(:,SelectedImage),'+g');
    title('Red dots represent your new raster.');
    hold off
    drawnow

    % Apply grid?
    GridSelection = menu(sprintf('Do you want to use the green highlighted markers?'),'Yes','No');

    if GridSelection==2
        return
    end

    % Choose number of area parts
    Prompt={'Into how many area parts do you want to split the markers?'};
    DlgTitle='Divide markers';
    DefaultSplitValue=10;
    DefValue={num2str(DefaultSplitValue)};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    SelectedSplitValue=str2num(cell2mat(Answer(1,1)));

    if SelectedSplitValue<1
        SelectedSplitValue=DefaultSplitValue;
    end

    hold on
    
    % Plot area parts
    PosX=zeros(1,SelectedSplitValue);
    MarkerDisplacementX=zeros(NumOfImages,SelectedSplitValue);
    MarkerDisplacementY=zeros(NumOfImages,SelectedSplitValue);
    for CurrentValue=1:SelectedSplitValue
        PosX(CurrentValue)=XMin+((XMax-XMin)/SelectedSplitValue)*CurrentValue;
        plot([PosX(CurrentValue);PosX(CurrentValue)],[YMin; YMax],'-m');
        SelectedMarkers=find(ValidXNew(:,SelectedImage)>(XMin+((XMax-XMin)/SelectedSplitValue)*(CurrentValue-1)) & ValidXNew(:,SelectedImage)<(XMin+((XMax-XMin)/SelectedSplitValue)*(CurrentValue)));
        ValidXPlot=ValidXNew(SelectedMarkers,:);
        ValidYPlot=ValidYNew(SelectedMarkers,:);
        plot(ValidXPlot(:,SelectedImage),ValidYPlot(:,SelectedImage),'+r');
        drawnow
        ValidYLocal=ValidYPlot;
        MarkerDisplacementY(:,CurrentValue)=mean(ValidYLocal)';
        ValidXLocal=ValidXPlot;
        MarkerDisplacementX(:,CurrentValue)=mean(ValidXLocal)';
        plot(ValidXLocal(:,SelectedImage),ValidYLocal(:,SelectedImage),'xg');
        drawnow
    end

    hold off

   	% Save marker displacement
    save('markerdisplacementx.txt','MarkerDisplacementX','-ASCII','-tabs');
    save('markerdisplacementy.txt','MarkerDisplacementY','-ASCII','-tabs');

    % Get gradient in x and y direction   
    SizeMDX=size(MarkerDisplacementX);
    MValidXFirst=ones(SizeMDX(1,1),1)*MarkerDisplacementX(1,:);
    MDX=MarkerDisplacementX-MValidXFirst;
    MValidYFirst=ones(SizeMDX(1,1),1)*MarkerDisplacementY(1,:);
    MDY=MarkerDisplacementY-MValidYFirst;
    
    GradMDX=gradient(MDX);
    GradMDY=gradient(MDY);
    GradMarkerDisplacementX=gradient(MarkerDisplacementX);
    GradMarkerDisplacementY=gradient(MarkerDisplacementY);
    GradientX=GradMDX./GradMarkerDisplacementX;
    GradientY=GradMDY./GradMarkerDisplacementY;

    % Save gradient
    save('gradientx.txt','GradientX','-ASCII','-tabs');
    save('gradienty.txt','GradientY','-ASCII','-tabs');

    % Check displacement?
    Title=sprintf('Do you want to check the displacement in %s-direction?',Direction);
    CheckDisplacement = menu(sprintf(Title),'Yes','No');
    if CheckDisplacement==1
        DisplacementFigure=figure;
        for CurrentImage=1:NumOfImages
            switch(Direction)
                case 'x'
                    plot(MarkerDisplacementX(CurrentImage,:),MDX(CurrentImage,:),'.r');
                    axis([min(min(MarkerDisplacementX)) max(max(MarkerDisplacementX)) min(min(MDX)) max(max(MDX))]);
                case 'y'
                    plot(MarkerDisplacementY(CurrentImage,:),MDY(CurrentImage,:),'.r');
                    axis([min(min(MarkerDisplacementY)) max(max(MarkerDisplacementY)) min(min(MDY)) max(max(MDY))]);
            end
            Title=sprintf('Displacement in %s-direction',Direction);
            title([Title,sprintf(' (current image #: %1g)',CurrentImage)]);
            XLabel=sprintf('%s-position [pixel]',Direction);
            xlabel(XLabel);
            YLabel=sprintf('local %s-displacement',Direction);
            ylabel(YLabel);
            drawnow
        end
    end

    % Check strain?
    Title=sprintf('Do you want to check the local strain in %s-direction?',Direction);
    CheckStrain = menu(sprintf(Title),'Yes','No');
    VideoSelection = menu(sprintf('Do you want to create a video?'),'Yes','No');
    if VideoSelection==1
        DirName='videolocalstrain';
        mkdir(DirName);
        cd(DirName);
        VideoStr='Vid';
    end
    if CheckStrain==1
        StrainFigure=figure;
        for CurrentImage=1:NumOfImages
            switch(Direction)
                case 'x'
                    plot(MarkerDisplacementX(CurrentImage,:),GradientX(CurrentImage,:),'.-b');
                    axis([min(min(MarkerDisplacementX)) max(max(MarkerDisplacementX)) min(min(GradientX)) max(max(GradientX))]);
                case 'y'
                    plot(MarkerDisplacementY(CurrentImage,:),GradientY(CurrentImage,:),'.-b');
                    axis([min(min(MarkerDisplacementY)) max(max(MarkerDisplacementY)) min(min(GradientY)) max(max(GradientY))]);
            end
            Title=sprintf('Gradient of displacement in %s-direction',Direction);
            title([Title,sprintf(' (current image #: %1g)',CurrentImage)]);
            XLabel=sprintf('%s-position [pixel]',Direction);
            xlabel(XLabel);
            YLabel=sprintf('local %s-displacement gradient',Direction);
            ylabel(YLabel);
            drawnow

            if VideoSelection==1
                Number=CurrentImage+10000;
                NumberStr=num2str(Number);
                VideoName=[VideoStr NumberStr '.jpg'];
                saveas(StrainFigure,VideoName,'jpg');
            end
        end
        if VideoSelection==1
            cd('..');
        end
    end
    
% Calculate and plot the strain (in x- or y-direction) by the gradient for each image
function FullStrain2D(ValidX,ValidY,Displ,Direction)

    StrainFigure=figure;
    SizeValidX=size(ValidX);
    NumOfImages=SizeValidX(1,2);    
    DisplColor=[-7 1];
    StrainColor=[-0.005 0.03];
    [XI,YI,ZI,EpsXX]=GetFullStrain2D(ValidX,ValidY,Displ);
    
    Labels={'x-position [pixel]','y-position [pixel]'};
    switch Direction
        case 'x' % x-direction
            XLabel=(Labels{1,1});
            YLabel=(Labels{1,2});
            FileName='strain2Dx.dat';
        case 'y' % y-direction
            XLabel=(Labels{1,2});
            YLabel=(Labels{1,1});
            FileName='strain2Dy.dat';
    end

    for CurrentImage=1:NumOfImages         
        subplot(2,1,1);
        CurrentZI=ZI(CurrentImage,:,:);
        CurrentZI=reshape(CurrentZI,size(XI,1),size(XI,2));
        pcolor(XI,YI,CurrentZI);
        axis('equal');
        shading('interp');
        caxis(DisplColor);
        ColorBar=colorbar;
        set(ColorBar,'PlotBoxAspectRatio',[2.0 10 8.0]);
        set(ColorBar,'FontSize', 12);
        Title=sprintf('Raw displacement in %s-direction',Direction);
        title([Title,sprintf(' (current image #: %1g)',CurrentImage)]);
        xlabel(XLabel);
        ylabel(YLabel);
        ZLabel=sprintf('%s-displacement [pixel]',Direction);
        zlabel(ZLabel);

        subplot(2,1,2);
        CurrentEpsXX=EpsXX(CurrentImage,:,:);
        CurrentEpsXX=reshape(CurrentEpsXX,size(XI,1),size(XI,2));
        pcolor(XI,YI,CurrentEpsXX);
        axis('equal');
        shading('interp');
        caxis(StrainColor);
        ColorBar = colorbar;
        set(ColorBar,'PlotBoxAspectRatio',[2.0 10 8.0]);
        set(ColorBar,'FontSize',12);
        Title=sprintf('Raw strain in %s-direction',Direction);
        title([Title,sprintf(' (current image #: %1g)',CurrentImage)]);
        xlabel(XLabel);
        ylabel(YLabel);
        ZLabel=sprintf('%s-strain',Direction);
        zlabel(ZLabel);
        drawnow
    end
    
    % Calculate strain filed by gradient
    DiffValidX=(max(max(ValidX))-min(min(ValidX)));
    DiffValidY=(max(max(ValidY))-min(min(ValidY)));
    Strain=gradient(Displ,DiffValidX/NumOfImages,DiffValidY/NumOfImages);
    save(FileName,'Strain','-ASCII','-tabs');

% Calculate the strain by the gradient for each image
function [XI,YI,ZI,EpsXX]=GetFullStrain2D(ValidX,ValidY,Displ)

    SizeValidX=size(ValidX);
    NumOfImages=SizeValidX(1,2);
    [XI,YI]=CreateGrid(ValidX,ValidY);
    DiffValidX=(max(max(ValidX))-min(min(ValidX)));
    DiffValidY=(max(max(ValidY))-min(min(ValidY)));
    ZI=[];
    EpsXX=[];

    for CurrentImage=1:NumOfImages
        %CurrentZI=griddata(ValidX(:,CurrentImage),ValidY(:,CurrentImage),Displ(:,CurrentImage),XI,YI,'cubic');'nearest'
        CurrentZI=griddata(ValidX(:,CurrentImage),ValidY(:,CurrentImage),Displ(:,CurrentImage),XI,YI,'v4');
        ZISize=size(CurrentZI);
        %CurrentEpsXX=gradient(CurrentZI,(DiffValidX/ZISize(1,1)),(DiffValidY/ZISize(1,2)));
        CurrentEpsXX=gradient(CurrentZI,(DiffValidX/(ZISize(1,2))),(DiffValidY/(ZISize(1,1))));
        ZI(CurrentImage,:,:)=CurrentZI;
        EpsXX(CurrentImage,:,:)=CurrentEpsXX;
    end    
    
% Calculate and plot strain (in x- or y-direction) between 2 points for each image 
function Strain2Points1D(ValidX,ValidY,Displ,Direction)

    DisplacementFigure=figure;
    SizeValidX=size(ValidX);
    NumOfImages=SizeValidX(1,2);
    SelectedImage=SelectImage(NumOfImages);
    
    [XI,YI]=CreateGrid(ValidX,ValidY);
    ZI=griddata(ValidX(:,SelectedImage),ValidY(:,SelectedImage),Displ(:,SelectedImage),XI,YI,'cubic');
    pcolor(XI,YI,ZI);
    axis('equal');
    caxis([min(min(ZI)) max(max(ZI))]);
    colorbar;
    shading('interp');
    hold on
    plot3(ValidX(:,SelectedImage),ValidY(:,SelectedImage),abs(Displ(:,SelectedImage)),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    axis([min(min(XI))-10 max(max(XI))+10 min(min(YI))-10 max(max(YI))+10]);
    drawnow

    % Get 2 points
    title('Click on the two points for strain measurement');
    Labels={'x-position [pixel]','y-position [pixel]'};
    switch Direction
        case 'x' % x-direction
            xlabel(Labels{1,1});
            ylabel(Labels{1,2});
        case 'y' % y-direction
            xlabel(Labels{1,2});
            ylabel(Labels{1,1});
    end
  
    ZLabel=sprintf('%s-displacement [pixel]',Direction);
    zlabel(ZLabel);
    [Points]=ginput(2);

    % Find points at given positions (smallest distance)
    RelativePos1=abs(ValidX(:,SelectedImage)-Points(1,1))+abs(ValidY(:,SelectedImage)-Points(1,2));
    SelectedPoint1=find(RelativePos1==min(RelativePos1));
    RelativePos2=abs(ValidX(:,SelectedImage)-Points(2,1))+abs(ValidY(:,SelectedImage)-Points(2,2));
    SelectedPoint2=find(RelativePos2==min(RelativePos2));

    % Update figure
    plot3(ValidX(SelectedPoint1,SelectedImage),ValidY(SelectedPoint1,SelectedImage),abs(Displ(SelectedPoint1,SelectedImage)),'+','MarkerEdgeColor','k','MarkerFaceColor','r');
    plot3(ValidX(SelectedPoint2,SelectedImage),ValidY(SelectedPoint2,SelectedImage),abs(Displ(SelectedPoint2,SelectedImage)),'+','MarkerEdgeColor','k','MarkerFaceColor','r');
    hold off
    axis([min(min(XI))-10 max(max(XI))+10 min(min(YI))-10 max(max(YI))+10]);
    drawnow

    % Calculate and plot strain
    StrainFigure=figure;
    Epsilon1D=(Displ(SelectedPoint1,:)-Displ(SelectedPoint2,:))/(ValidX(SelectedPoint1,1)-ValidX(SelectedPoint2,1));
    EpsilonSize=size(Epsilon1D);
    plot(1:EpsilonSize(1,2),Epsilon1D,'.');
    title('True strain versus image #');
    xlabel('image');
    YLabel = sprintf('true strain in %s-direction',Direction);
    ylabel(YLabel);
    drawnow

    % Save epsilon data
    EpsilonData = [(1:NumOfImages)' Epsilon1D'];
    FileName=sprintf('strain%s2p.dat',Direction);
    save(FileName,'EpsilonData','-ASCII','-tabs');
 
% Calculate, show and save principal strains and stresses (optional)   
function PrincipalStrains(ValidX,ValidY,StdX,StdY)
    
    DisplX=GetMeanDisplacement(ValidX);
    DisplY=GetMeanDisplacement(ValidY);
    DisplXY=(DisplX+DisplY)/sqrt(2);
    ValidXY=(ValidX+ValidY)/sqrt(2);
    StdXY=sqrt((2*StdX.^2.*StdY.^2)./(StdX.^2+StdY.^2));
    
    % Abort if no valid standard deviation given
    if isempty(find(StdX)) || isempty(find(StdY))
        msgbox('Please open standard deviation first');
        return
    end
    
    NumOfMarkers=size(ValidX,1);
    NumOfImages=size(ValidX,2);
    ex=zeros(NumOfImages,1);
    ey=zeros(NumOfImages,1);
    exy=zeros(NumOfImages,1);
    stdex=zeros(NumOfImages,1);
    stdey=zeros(NumOfImages,1);
    stdexy=zeros(NumOfImages,1);
    for Image=1:NumOfImages
        CurrentValidX=ValidX(:,Image);
        CurrentValidY=ValidY(:,Image);
        CurrentValidXY=ValidXY(:,Image);
        CurrentDisplX=DisplX(:,Image);
        CurrentDisplY=DisplY(:,Image);
        CurrentDisplXY=DisplXY(:,Image);
        CurrentStdX=StdX(:,Image);
        CurrentStdY=StdY(:,Image);
        CurrentStdXY=StdXY(:,Image);
        
        % Linear fit for strain with error bars in both directions
        [~, ex(Image), ~, stdex(Image)] = york_fit(CurrentValidX',CurrentDisplX',CurrentStdX',CurrentStdX',(CurrentStdX').^2);
        [~, ey(Image), ~, stdey(Image)] = york_fit(CurrentValidY',CurrentDisplY',CurrentStdY',CurrentStdY',(CurrentStdY').^2);
        [~, exy(Image), ~, stdexy(Image)] = york_fit(CurrentValidXY',CurrentDisplXY',CurrentStdXY',CurrentStdXY',(CurrentStdXY').^2);
    end
    
    % Fit curves to strain plots
    [einfx, stdeinfx, ex, stdex] = DICstrainfit(ex,stdex);
    [einfy, stdeinfy, ey, stdey] = DICstrainfit(ey,stdey);
    [einfxy, stdeinfxy, exy, stdexy] = DICstrainfit(exy,stdexy);
    
    % Calculate principle strain relief values and orientation
    Strain1=(einfx+einfy)*0.5+sqrt(1/2)*sqrt((einfx-einfxy)^2+(einfxy-einfy)^2);
    Strain2=(einfx+einfy)*0.5-sqrt(1/2)*sqrt((einfx-einfxy)^2+(einfxy-einfy)^2);
    theta=0.5*atan((einfx-2*einfxy+einfy)/(einfx-einfy));

    SigmaStrain=0.5*sqrt(stdeinfx^2+stdeinfy^2+((einfx-einfxy)^2*(stdeinfx^2+stdeinfxy^2)+(einfxy-einfy)^2*(stdeinfxy^2+stdeinfy^2))/((einfx-einfxy)^2+(einfxy-einfy)^2));
    Sigmatheta=sqrt(1/2)*sqrt((stdeinfx^2*(einfxy-einfy)^2+stdeinfxy^2*(einfx-einfy)^2+stdeinfy^2*(einfx-einfxy)^2)/((einfx-einfxy)^2+(einfxy-einfy)^2));
    
    Selection = menu(sprintf('Do you want to calculate the principal stresses?'),'Yes','No');
    
    % Show and save strain data only
    if Selection==2
        F=figure;
        DataValues=[Strain1,SigmaStrain;Strain2,SigmaStrain;theta,Sigmatheta;einfx,stdeinfx;einfy,stdeinfy;einfxy,stdeinfxy];
        Data=num2cell(DataValues);
        Names={'strain 1';'strain 2';'theta [rad]';'strain x';'strain y';'strain xy'};
        Titles={'Variable','Value','Std dev'};
        t=uitable('Parent',F);
        set(t,'ColumnName',Titles);
        set(t,'RowName',[]);
        set(t,'Data',[Names,Data]);   
        
        StrainFileName='strainoutput';
        save(StrainFileName,'DataValues','ex','ey','exy','stdex','stdey','stdexy');
    
    % Calculate, show and save stress data additionally
    else
        Inputs={'E [GPa]','Poissons ratio','Std dev E [GPa]','Std dev Poissons ratio'};
        Answer=inputdlg(Inputs,'Please enter mechanical properties');
        E=str2num(Answer{1})*10^9;
        nu=str2num(Answer{2});
        SigmaE=str2num(Answer{3})*10^9;
        Sigmanu=str2num(Answer{4});
        
        % Calculate principal stresses according to (Korsunsky,2009) "Focused ion beam ring drilling for residual stress evaluation"
        Stress1=-E*(Strain1+nu*Strain2)/(1-nu^2);
        Stress2=-E*(Strain2+nu*Strain1)/(1-nu^2);

        SigmaStress1=E*sqrt(((SigmaE/E)^2+2*(nu*Sigmanu/(1-nu^2))^2)*(Strain1+nu*Strain2)^2+SigmaStrain^2+(nu*SigmaStrain)^2+(Strain2*Sigmanu)^2)/(1-nu^2);
        SigmaStress2=E*sqrt(((SigmaE/E)^2+2*(nu*Sigmanu/(1-nu^2))^2)*(Strain2+nu*Strain1)^2+SigmaStrain^2+(nu*SigmaStrain)^2+(Strain1*Sigmanu)^2)/(1-nu^2);
        
        F=figure;
        DataValues=[Strain1,SigmaStrain;Strain2,SigmaStrain;theta,Sigmatheta;einfx,stdeinfx;einfy,stdeinfy;einfxy,stdeinfxy;Stress1*10^-6,SigmaStress1*10^-6;Stress2*10^-6,SigmaStress2*10^-6];
        Data=num2cell(DataValues);
        Names={'strain 1';'strain 2';'theta [rad]';'strain x';'strain y';'strain xy';'stress 1 [MPa]';'stress 2 [MPa]'};
        Titles={'Variable','Value','Std dev'};
        t=uitable('Parent',F);
        set(t,'ColumnName',Titles);
        set(t,'RowName',[]);
        set(t,'Data',[Names,Data]);   
        
        StrainFileName='stressoutput';
        save(StrainFileName,'DataValues','ex','ey','exy','stdex','stdey','stdexy');
    end