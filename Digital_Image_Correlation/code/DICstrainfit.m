function [delstr, SDS, str, stddev] = DICstrainfit(str,stddev)

choice=1;    

h=1:1:length(str);

h0=h;
str0=str;
stddev0=stddev;

Figure=figure;
while choice==1
    
    errorbar(h,str,stddev*1.96)
    
    %If the strain is positive
    meanstr=mean(str);
    
    x0(3)=0; %Offset in horizontal direction
    
    if meanstr>0
        %Find the maximum position
        [strmax,strpos]=max(str);
        
        %Use to predict starting values
        x0(2)=strmax/1.12;
        x0(1)=1/h(strpos);
        
        x0(3)=20*x0(1);
        
        %Fit the data
        [yfit,x,convergence,~,~,covp,~,~]=leasqr(h',str',x0,'curvepos',0.0001,20,1./stddev');
    else
        %Find the maximum position
        [strmin,strpos]=min(str);
        
        %Use to predict starting values for delta e and scaling in x
        x0(2)=strmin/1.12;
        x0(1)=1/h(strpos);
        
        %Fit the data
        [yfit,x,convergence,~,~,covp,~,~]=leasqr(h',str',x0,'curveneg',0.0001,20,1./stddev');
    end
    
    SDS=sqrt(covp(2,2));
    
    %Output relevant parameter
    delstr=x(2);
    
    if convergence==1
        hold on
        title(['Strain relief =',num2str(delstr),', Standard deviation =',num2str(SDS)])
        plot(h,yfit,'go')
    else
        title('Fitting did not converge')
    end
    
    
    choice = menu('Remove outliers?','Yes','No','Reset');
    %choice=2;
    
    if choice==1
        [x,y]=ginput(2);
        xmin=min(x);
        xmax=max(x);
        ymin=min(y);
        ymax=max(y);
        
        alpha=0;
        
        for j=1:1:length(str)
            
            % Update index
            alpha=alpha+1;
            
            % If d is above threshold
            if (h(alpha)>xmin)&&(h(alpha)<xmax)&&(str(alpha)>ymin)&&(str(alpha)<ymax)
                
                % Remove all of these terms from the plot
                h(alpha)=[];
                str(alpha)=[];
                stddev(alpha)=[];
                
                %Update index
                alpha=alpha-1;
            end
        end
    end
    
    if choice==3
    
        h=h0;
        str=str0;
        stddev=stddev0;
        
        choice=1;
        
    end 
end

close(Figure);