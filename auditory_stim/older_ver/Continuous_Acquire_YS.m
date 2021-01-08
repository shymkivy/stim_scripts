% One-channel continuous acquire example using a serial buffer
% This program writes to the buffer once it has cyled halfway through
% (double-buffering)

close all;
clear all;
clc;

circuit_file_name = 'Continuous_Acquire_YS.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% filePath - set this to wherever the examples are stored
filePath = 'C:\Users\YusteLab\Desktop\Yuriy\RZ6_data\';
RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3));
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end



% size of the entire serial buffer
npts = RP.GetTagSize('dataout');  

% serial buffer will be divided into two buffers A & B
fs = RP.GetSFreq();
bufpts = npts/2; 
t=(1:bufpts)/fs;

filePath = strcat(filePath, 'fnoise.F32');
fnoise = fopen(filePath,'w');
    
% begin acquiring
RP.SoftTrg(1);
curindex = RP.GetTagVal('index');
disp(['Current buffer index 45: ' num2str(curindex)]);

% main looping section
for i = 1:10  

    % wait until done writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index');
        pause(.05);
    end

    % read segment A
    noise = RP.ReadTagVEX('dataout', 0, bufpts, 'F32', 'F32', 1);
    disp(['Wrote ' num2str(fwrite(fnoise,noise,'float32')) ' points to file']);

    % checks to see if the data transfer rate is fast enough
    curindex = RP.GetTagVal('index');
    disp(['Current buffer index 62: ' num2str(curindex)]);
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end

    % wait until start writing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index');
        pause(.05);
    end

    % read segment B
    noise = RP.ReadTagVEX('dataout', bufpts, bufpts, 'F32', 'F32', 1);
    disp(['Wrote ' num2str(fwrite(fnoise,noise,'float32')) ' points to file']);

    % make sure we're still playing A 
    curindex = RP.GetTagVal('index');
    disp(['Current index 79: ' num2str(curindex)]);
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end

end

fclose(fnoise);

% stop acquiring
RP.SoftTrg(2);
RP.Halt;

% plots the last npts data points
plot(t,noise);
axis tight;