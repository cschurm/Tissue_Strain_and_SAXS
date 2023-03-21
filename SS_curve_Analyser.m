%% Compression Testing Analysis
% by Roche C. de Guzman, Ph.D.
% Hofstra University
% Edited for general use by Charles Schurman
% UCSF

%% Clear Previous
clear; clc; close('all');
%%load and re-plot data
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_fits.mat'))


%% Toe Region Removal
 m=menu(sprintf('Remove Toe Region?'),'Yes', 'No');
 if m == 1
    toe_ind = remove_toe(fitresult,false_strain,false_stress,0.02); % <- adjust tolerance if needed
    false_strain=false_strain(toe_ind:end);
    false_stress=false_stress(toe_ind:end);
 else
 end
 
 % need to create options for more than just fourier model
%% Computations

% adjust units
strain = false_strain; % strain [%]
stress = false_stress; % stress [MPa]

% locate the ultimate stress
dsigma = diff(stress); % derivative of stress
dsigma = round(dsigma*1000)/1000; % round off dsigma
Ndsig = numel(dsigma); % number of elements of dsigma
MSp = zeros(1,Ndsig); MSpi = MSp; UsigInd = Ndsig; % initial values
for c3 = 1:Ndsig
    [MSp(c3),MSpi(c3)] = max(stress(1:c3)); % maximum stress and its index vectors
    if c3 > 2
        % condition: max is established when the next two are decreasing
        % and the derivative must be negative
        if (MSp(c3) == MSp(c3-1)) && (MSp(c3) == MSp(c3-2)) && (dsigma(c3-1) < 0) && (dsigma(c3-2) < 0)
            UsigInd = c3-2; % index of maximum point
            break;
        end
    end
end

% trim data
cutoff = round(UsigInd*1.15); % maximum index
if cutoff <= Ndsig
    strain = strain(1:cutoff); % strain [%]
    stress = stress(1:cutoff); % stress [MPa]
end

% % readjust the zero
% Ustr = max(stress); % maximum stress [MPa]
% limStr = Ustr*0.01; % 1% of maximum stress [MPa]
% Lsig = stress >= limStr; % logical true
% LsigInd = find(Lsig); % index of true
% zInd = LsigInd(1); % new index
% strain = strain(zInd:end)-strain(zInd); % strain [%]
% stress = stress(zInd:end)-stress(zInd); % stress [MPa]

% true values
strainT = -log(1-strain/100)*100; % true strain [%]
stressT = stress.*(1-strain/100); % true stress [MPa]
[UCS,UCSi] = max(stressT); % ultimate strength [MPa]
UCstrain = strainT(UCSi); % ultimate strain [%]

% linear regression to determine the modulus
ND = numel(stressT); % number of elements
% initial values
RSQ = zeros(1,ND-2); x = NaN(1,ND); y = x; yf = y; m = RSQ; b = m; dy = b;
for c4 = 1:ND-2
    x = strainT(1:c4+2); % x observed [%]
    y = stressT(1:c4+2); % y observed [MPa]
    m(c4) = (((c4+2)*sum(x.*y))-(sum(x)*sum(y)))/(((c4+2)*sum(x.^2))-(sum(x)^2)) ; % slope of line fit [MPa/% = 100*MPa]
    b(c4) = ((sum(y))-(m(c4)*(sum(x))))/(c4+2); % y-intercept of line fit [MPa]
    yf = m(c4)*x + b(c4); % y fit [MPa]
    SSE = sum((y-yf).^2); % sum of squares error
    SST = sum((y-mean(y)).^2); % sum of squares total
    RSQ(c4) = 1 - (SSE/SST); % coefficient of determination vector
    %xi(c4) = -b/m(c4);
    dy(c4) = abs(y(c4+2) - (m(c4)*x(c4+2)+b(c4)))/UCS; % change in y over UCS 
end
[~,ECi] = max(dy >= 0.01); % index of the modulus, 10% cutoff
rsq = RSQ(ECi); % r^2 = coefficient of determination
EC = m(ECi)*100; % modulus [MPa]

% Elastic Limit Values
Elim_strain = strainT(ECi+2); % Elastic Limit strain [%]
Elim_stress = stressT(ECi+2); % Elastin Limit Stress [MPa]

mm=menu('How would you like to Calculate Yeild?','90% of Elastic ','0.2% Shift Yeild');
if mm == 1 % 90% Elastic Modulus
    nn=1; %for result display later
    plt_val=1; % for later visualizing options
      ec=(EC*0.9)/100; %div by 100 to adjust units
      drop_strain=Elim_strain:0.01:strain(end);
      drop_stress=ec.*drop_strain;
      plot_drop=0:0.01:strain(end); %only for plotting
      plot_drop_stress=ec.*plot_drop; % not used in calc...
      drop_yeild=[drop_strain; drop_stress];
      samp=[strain; stress];
      yeild_pt = InterX(samp,drop_yeild);
      if isempty(yeild_pt) == 1
            warning('90% E does not intersect, little yeild before failure. Setting yeild to ultimate...')
            ystrain=UCstrain;
            ystress=UCS;
      else    
            ystrain=yeild_pt(1);
            ystress=yeild_pt(2);
      end
      
else  % 0.2% Yeild Values
    plt_val=2; % for later visualizing options
    shift_stress=(EC.*strain./100); %div by 100 for conversion from strain % to #
deltx=(strain+0.2);
plastic=[deltx; shift_stress];
samp=[strain; stress];
yeild_pt = InterX(samp,plastic);

% if 0.2% shift results in no intersection, approximate the yeild point as halfway between Elastic Limit and Ultimate point
nn=1;

if isempty(yeild_pt) == 1
    warning('.2% yeild shift too large, approximating new shift...suggest using 90% E')
    nn=0;
    ystrain=(Elim_strain+UCstrain)/2;
    ii=1;
    while strain(ii) < ystrain
        ii=ii+1;
    end
    ystrain=strain(ii-1);
    ystress=stress(ii-1);
    % back-calculate the shift
    intcpt=ystress-(EC*(ystrain/100)); % div % by 100 to use #
    z=(-1)*intcpt/(EC)*100;
    deltx=(strain+z); %for plotting
else
    ystrain=yeild_pt(1);
    ystress=yeild_pt(2);
end
end


%% Display Results
viz=menu(sprintf('Visualize Analysis?'),'Yes', 'No');

if viz ==1 
    if plt_val==1
    % animation to fit the line
max_x=1.2*max(strain);
xlm=[0 max_x];
for c5 = 1:ND-2
    p1=plot(strain,stress,'-r'); % engineering
    hold('on');
    p2=plot(strainT,stressT,'-b','linewidth',2); % true
    title('SS Analysis');
    xlabel('Strain [%]');
    ylabel('Stress [MPa]');    
    plot([strainT(1) strainT(end)],[m(c5)*strainT(1)+b(c5) m(c5)*strainT(end)+b(c5)],'color',[0 1 0.25]);
    axis([0 strainT(ND-2) 0 max(stress)*1.05]);
    legend([p1 p2],'Engineering','True','location','northwest');
    xlim(xlm);
    drawnow;
    hold('off');
end
for c6 = ND-2:-1:1
    p1= plot(strain,stress,'-r'); % engineering
    hold('on');
    p2 =plot(strainT,stressT,'-b','linewidth',2); % true
    title('SS Analysis');
    xlabel('Strain [%]');
    ylabel('Stress [MPa]');  
    plot([strainT(1) strainT(end)],[m(c6)*strainT(1)+b(c6) m(c6)*strainT(end)+b(c6)],'color',[0 1 0.25]);
    axis([0 strainT(ND-2) 0 max(stress)*1.05]);
    legend([p1 p2],'Engineering','True','location','northwest');
    xlim(xlm);
    drawnow; 
    hold('off');
    if m(c6)*100 == EC
        p1 = plot(strain,stress,'-r'); % engineering
        hold('on');
        p2 = plot(strainT,stressT,'-b','linewidth',2); % true
        title('SS Analysis');
        xlabel('Strain [%]');
        ylabel('Stress [MPa]'); 
        % Elastic Limit
        p3 = plot(Elim_strain,Elim_stress,'ob','markerfacecolor',[0 1 0],'markersize',5);
        plot([Elim_strain Elim_strain],[0 Elim_stress],'--g');
        plot([0 Elim_strain],[Elim_stress Elim_stress],'--g');
        text(Elim_strain*0.8,Elim_stress+0.08*UCS,'Elastic Region','color',[0 1 0]);
        % Yeild
        p4 = plot(ystrain,ystress,'ob','markerfacecolor',[1 0 1],'markersize',5);
        p6 = plot(plot_drop,plot_drop_stress,'m');
        plot([ystrain ystrain],[0 ystress],'--m');
        plot([0 ystrain],[ystress ystress],'--m');
        text(ystrain*0.8,ystress+0.08*UCS,'Yeild','color',[1 0 1]);
        % Ultimate
        p5 = plot(UCstrain,UCS,'pb','markerfacecolor',[0 0 0],'markersize',8);
        plot([UCstrain UCstrain],[0 UCS],'--k');
        plot([0 UCstrain],[UCS UCS],'--k');
        text(UCstrain*0.8,UCS+0.08*UCS,'Ultimate');
        axis([0 strainT(ND-2) 0 max(stress)*1.05]);
        % Legend
        legend([p1 p2 p3 p4 p6 p5],'Engineering','True','Elastic Limit','Yeild Point','Strain Shift','Ultimate','location','northwest');
        xlim(xlm);
        hold('off');
        break;
    end
end
    elseif plt_val == 2
% animation to fit the line
max_x=1.2*max(strain);
xlm=[0 max_x];
for c5 = 1:ND-2
    p1=plot(strain,stress,'-r'); % engineering
    hold('on');
    p2=plot(strainT,stressT,'-b','linewidth',2); % true
    title('SS Analysis');
    xlabel('Strain [%]');
    ylabel('Stress [MPa]');    
    plot([strainT(1) strainT(end)],[m(c5)*strainT(1)+b(c5) m(c5)*strainT(end)+b(c5)],'color',[0 1 0.25]);
    axis([0 strainT(ND-2) 0 max(stress)*1.05]);
    legend([p1 p2],'Engineering','True','location','northwest');
    xlim(xlm);
    drawnow;
    hold('off');
end
for c6 = ND-2:-1:1
    p1= plot(strain,stress,'-r'); % engineering
    hold('on');
    p2 =plot(strainT,stressT,'-b','linewidth',2); % true
    title('SS Analysis');
    xlabel('Strain [%]');
    ylabel('Stress [MPa]');  
    plot([strainT(1) strainT(end)],[m(c6)*strainT(1)+b(c6) m(c6)*strainT(end)+b(c6)],'color',[0 1 0.25]);
    axis([0 strainT(ND-2) 0 max(stress)*1.05]);
    legend([p1 p2],'Engineering','True','location','northwest');
    xlim(xlm);
    drawnow; 
    hold('off');
    if m(c6)*100 == EC
        p1 = plot(strain,stress,'-r'); % engineering
        hold('on');
        p2 = plot(strainT,stressT,'-b','linewidth',2); % true
        title('SS Analysis');
        xlabel('Strain [%]');
        ylabel('Stress [MPa]'); 
        % Elastic Limit
        p3 = plot(Elim_strain,Elim_stress,'ob','markerfacecolor',[0 1 0],'markersize',5);
        plot([Elim_strain Elim_strain],[0 Elim_stress],'--g');
        plot([0 Elim_strain],[Elim_stress Elim_stress],'--g');
        text(Elim_strain*0.8,Elim_stress+0.08*UCS,'Elastic Region','color',[0 1 0]);
        % Yeild
        p4 = plot(ystrain,ystress,'ob','markerfacecolor',[1 0 1],'markersize',5);
        p6 = plot(deltx,shift_stress,'m');
        plot([ystrain ystrain],[0 ystress],'--m');
        plot([0 ystrain],[ystress ystress],'--m');
        text(ystrain*0.8,ystress+0.08*UCS,'Yeild','color',[1 0 1]);
        % Ultimate
        p5 = plot(UCstrain,UCS,'pb','markerfacecolor',[0 0 0],'markersize',8);
        plot([UCstrain UCstrain],[0 UCS],'--k');
        plot([0 UCstrain],[UCS UCS],'--k');
        text(UCstrain*0.8,UCS+0.08*UCS,'Ultimate');
        axis([0 strainT(ND-2) 0 max(stress)*1.05]);
        % Legend
        legend([p1 p2 p3 p4 p6 p5],'Engineering','True','Elastic Limit','Yeild Point','Strain Shift','Ultimate','location','northwest');
        xlim(xlm);
        hold('off');
        break;
    end
end
    end
end


%% Save


Modulus=EC/1000; %convert MPa to GPa
Ustrain=UCstrain;
Ustrength=UCS;
Toughness=trapz(false_strain,false_stress);

filename=strcat(deepestFolder,'_properties');
save (filename,'Modulus','ystress','ystrain','Elim_stress','Elim_strain','Ustrength','Ustrain','Toughness')
parameters=[Modulus, Elim_strain, Elim_stress, ystrain,ystress, Ustrain, Ustrength,Toughness];
% command window display
if nn==1
disp('========================================================================================');
disp(['   The sample was found to have an elastic modulus of ' num2str(Modulus) ' GPa or ' num2str(Modulus*1000) ' MPa.']);
disp(['   Its Elastic Limit Strain is ' num2str(Elim_strain) '%, while']);
disp(['   Its Elastic Limit Stress is ' num2str(Elim_stress) ' MPa or ' num2str(Elim_stress*1000) ' kPa.']);
disp(['   Its Yeild Strain is ' num2str(ystrain) '%, while']);
disp(['   Its Yeild Stress is ' num2str(ystress) ' MPa or ' num2str(ystress*1000) ' kPa.']);
disp(['   Its ultimate Strain is ' num2str(Ustrain) '%, while']);
disp(['   Its ultimate Stress is ' num2str(Ustrength) ' MPa or ' num2str(UCS*1000) ' kPa.']);
disp(['   Its toughness is ' num2str(Toughness) ' MPa']);
disp('========================================================================================');
else

disp('========================================================================================');
disp(['   The sample was found to have an elastic modulus of ' num2str(Modulus) ' GPa or ' num2str(Modulus*1000) ' MPa.']);
disp(['   Its Elastic Limit Strain is ' num2str(Elim_strain) '%, while']);
disp(['   Its Elastic Limit Stress is ' num2str(Elim_stress) ' MPa or ' num2str(Elim_stress*1000) ' kPa.']);
disp(['   Its Yeild Strain is ' num2str(ystrain) '%, while']);
disp(['   Its Yeild Stress is ' num2str(ystress) ' MPa or ' num2str(ystress*1000) ' kPa.']);
disp(['   Its ultimate Strain is ' num2str(Ustrain) '%, while']);
disp(['   Its ultimate Stress is ' num2str(Ustrength) ' MPa or ' num2str(UCS*1000) ' kPa.']);
disp(['   Its toughness is ' num2str(Toughness) ' MPa']);
disp('========================================================================================');
warning(['Arbitrary Strain Shift reduced to ' num2str(z) '% from 0.2%'])
end


