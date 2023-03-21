% Get calibration input from user: validx, validy, calpath
function [ValidX,ValidY,CalPath] = GetCalibrationInput()

    Delimiter='\t';

    % Get validx and validy
    [ValidXName,ValidXPath] = uigetfile('*.dat','Open validx.dat');
    if ValidXName==0
        disp('You did not select a file!');
        return
    end
    cd(ValidXPath);
    ValidX=importdata(ValidXName,Delimiter);
    [ValidYName,ValidYPath] = uigetfile('*.dat','Open validy.dat');
    if ValidYName==0
        disp('You did not select a file!');
        return
    end
    cd(ValidYPath);
    ValidY=importdata(ValidYName,Delimiter);
    
    % Rigid body displacements
    [CalPathName,CalPathPath] = uigetfile('*.dat','Open calpath.dat');
    if CalPathName==0
        disp('You did not select a file!');
        return
    end
    cd(CalPathPath);
    CalPath=importdata(CalPathName);   