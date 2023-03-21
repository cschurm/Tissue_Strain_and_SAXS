%Calculate semi-one dimensional strain given a set of X-Y coordinates over
%time/step.

mm=menu(sprintf('Calculate Unidirectional Strain?'),'X-Direction','Y-Direction','No, Calculate Total Strain');
%Calculate the displacements between steps for each point
[m,n]=size(validx);
d=zeros(m,n-1);
for jj =2:n %step across columns
    for ii = 1:m %step down rows
pair=[validx(ii,jj),validy(ii,jj); validx(ii,jj-1),validy(ii,jj-1)];
d(ii,jj)=pdist(pair,'euclidean');
    end
end
step_mean=mean(d); % gives average by step for all points at time jj

%Calculate distances btw all points. This step may take considerable time.
dist=zeros(m,m,n);
WaitBar=waitbar(0,'Calculating Distances...');
for jj = 1:n 
    for I=1:m
        for ii=I:m
            pair=[validx(ii,jj),validy(ii,jj); validx(I,jj),validy(I,jj)];
            dist(I,ii,jj)=pdist(pair,'euclidean');
        end
    end
    set(0,'CurrentFigure',WaitBar); 
        waitbar(jj/n,WaitBar);
end
    close(WaitBar)


% Find relevant strain points and calculate strain
strain_array=zeros(m,n); %initialize strain array

%Calc X or Y Strain
if mm == 1 %X-type Strain    
WaitBar=waitbar(0,'Calculating Strain...');
for jj = 1:n %step across columns (time)
    c=1;
    pre_strain=zeros(1,n);
   for ii = 1:m %step down rows (space) ii at time jj
       for xx = ii:m %step down rows (space) xx at same time jj
            if abs(validx(ii,jj)-validx(xx,jj)) > abs(validy(ii,jj)-validy(xx,jj)) % excludes pairs with a more dominant Y component
               pre_strain(c)=(dist(ii,xx,jj)-dist(ii,xx,1))/dist(ii,xx,1);
               c=c+1;
            end
       end
       
       %Replace NaN with 0 for prestrain values...
       for kk=1:length(pre_strain)
           if isnan(pre_strain(kk)) 
            pre_strain(kk)=0;
           end
       end
       
       strain_array(ii,jj)=sum(pre_strain)/nnz(pre_strain);
   end
   set(0,'CurrentFigure',WaitBar); 
        waitbar(jj/n,WaitBar);
end
   close(WaitBar)

% Replace NaN by 0
for ii = 1:m
    for jj =1:n
        if isnan(strain_array(ii,jj)) 
            strain_array(ii,jj)=0;
        end
    end
end

valid_strain=mean(strain_array);

elseif mm == 2 %Y-type Strain
    WaitBar=waitbar(0,'Calculating Strain...');
for jj = 1:n %step across columns (time)
    c=1;
    pre_strain=zeros(1,n);
   for ii = 1:m %step down rows (space) ii at time jj
       for xx = ii:m %step down rows (space) xx at same time jj
            if abs(validx(ii,jj)-validx(xx,jj)) < abs(validy(ii,jj)-validy(xx,jj)) % excludes pairs with a more dominant Y component
               pre_strain(c)=(dist(ii,xx,jj)-dist(ii,xx,1))/dist(ii,xx,1);
               c=c+1;
            end
       end
       
       %Replace NaN with 0 for prestrain values...
       for kk=1:length(pre_strain)
           if isnan(pre_strain(kk)) 
            pre_strain(kk)=0;
           end
       end
       
       strain_array(ii,jj)=sum(pre_strain)/nnz(pre_strain);
   end
   set(0,'CurrentFigure',WaitBar); 
        waitbar(jj/n,WaitBar);
end
   close(WaitBar)

% Replace NaN by 0
for ii = 1:m
    for jj =1:n
        if isnan(strain_array(ii,jj)) 
            strain_array(ii,jj)=0;
        end
    end
end

valid_strain=mean(strain_array);

elseif mm == 3 %Y-type Strain
    WaitBar=waitbar(0,'Calculating Strain...');
for jj = 1:n %step across columns (time)
    c=1;
    pre_strain=zeros(1,n);
   for ii = 1:m %step down rows (space) ii at time jj
       for xx = ii:m %step down rows (space) xx at same time jj
           pre_strain(c)=(dist(ii,xx,jj)-dist(ii,xx,1))/dist(ii,xx,1);
           c=c+1;
       end
       
       %Replace NaN with 0 for prestrain values...
       for kk=1:length(pre_strain)
           if isnan(pre_strain(kk)) 
            pre_strain(kk)=0;
           end
       end
       
       strain_array(ii,jj)=sum(pre_strain)/nnz(pre_strain);
   end
   set(0,'CurrentFigure',WaitBar); 
        waitbar(jj/n,WaitBar);
end
   close(WaitBar)

% Replace NaN by 0
for ii = 1:m
    for jj =1:n
        if isnan(strain_array(ii,jj)) 
            strain_array(ii,jj)=0;
        end
    end
end

valid_strain=mean(strain_array);
end


% Save
save valid_strain_array.dat strain_array -ascii ;
save valid_strain.dat valid_strain -ascii ;


                   
                   
                   
               
       
        
