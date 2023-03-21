function [newX,newY] = BoxROI(Xdata,Ydata)
close all
hold on;
% Calculation for the amount by which the label should be displaced in the 'y' direction
lbl_dwn = .02*max(Ydata);
% plot and label the individual points
for i = 1:length(Xdata)
     plot(Xdata(i),Ydata(i),'r+');
     % Label the points with the index
     text(Xdata(i),Ydata(i)+lbl_dwn,num2str(i));
end
hold off
m=menu(sprintf('Trim?'),'Yes','No');
if m == 1
    num=input('How many Points? : ');
    Xdata=Xdata(1:end-num);
    Ydata=Ydata(1:end-num);
end

%Reselect Area for Re-Plot
figure
hax = axes;
plot(Xdata,Ydata,'Marker','hexagram','LineStyle','none');
title('Box Region for RoI...','FontWeight','bold','FontSize',16)
set(hax,'ButtonDownFcn',@OnClickAxes);
waitforbuttonpress;

%Find and extract values from inside the new ROI
[new_ind] = find(Xdata > hax.XLim(1) & Xdata < hax.XLim(2) & Ydata > hax.YLim(1) & Ydata < hax.YLim(2));
newX=Xdata(new_ind);
newY=Ydata(new_ind);


end

    function [newArray] = OnClickAxes( hax, ~ )

point1 = get(hax,'CurrentPoint'); % corner where rectangle starts ( initial mouse down point )
rbbox
point2 = get(hax,'CurrentPoint'); % corner where rectangle stops ( when user lets go of mouse )

% Iterate through all lines in the axes and extract the data that lies within the selected region
allLines = findall(hax,'type','line');
for n = 1:length(allLines)

   [newArray,~] = getDataInRect( point1(1,1:2), point2(1,1:2), allLines(n) ); % not interested in z-coord
   
end

end

function [dataInRect,dataInd] = getDataInRect( p1, p2, hline )

% Define low and high x and y values, rbbox will reverse them if you draw rectangle from bottom up
if ( p1(1) < p2(1) )
   lowX = p1(1); highX = p2(1);
else
   lowX = p2(1); highX = p1(1);
end

if ( p1(2) < p2(2) )
   lowY = p1(2); highY = p2(2);
else
   lowY = p2(2); highY = p1(2);
end

xdata = get(hline,'XData');
ydata = get(hline,'YData');

xind = (xdata >= lowX & xdata <= highX);
yind = (ydata >= lowY & ydata <= highY);

dataInd = xind & yind; % these are the indices in xdata and ydata where the points lie within the rectangle
dataInRect = [xdata(dataInd);ydata(dataInd)]'; % this returns all of the data inside the rect in one 2xN matrix

newX=dataInRect(:,1);
newY=dataInRect(:,2);


plot(newX,newY,'Marker','hexagram','LineStyle','none');
%savefig(strcat(deepestFolder,'_',filename))

end