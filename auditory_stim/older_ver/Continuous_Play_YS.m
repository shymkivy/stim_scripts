% One-channel continuous play example using a serial buffer
% This program writes to the buffer once it has cyled halfway through
% (double-buffering)

close all;
clear all;
clc;


circuit_file_name = 'Continuous_Play_YS.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3));
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end

% size of the entire serial buffer
npts = RP.GetTagSize('datain');  

% serial buffer will be divided into two buffers A & B
bufpts = npts/2; 

% get device sampling frequency
fs = RP.GetSFreq();

% create one 5-second chirp
duration = 5;
t = 0:1/fs:5;
s1 = chirp(t, 1000, 5, 10000);

% load up entire buffer with segments A and B
RP.WriteTagVEX('datain', 0, 'F32', s1(1:npts));
index = npts+1;

% start playing
RP.SoftTrg(1);
curindex = RP.GetTagVal('index');
disp(['Current buffer index: ' num2str(curindex)]);

% main looping section
sz = length(s1);
while index < sz

    % wait until done playing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index');
        pause(.05);
    end

    % load the next signal segment
    top = min(index+bufpts, sz);
    RP.WriteTagVEX('datain', 0, 'F32', s1(index:top));
    index = top;

    % checks to see if the data transfer rate is fast enough
    curindex = RP.GetTagVal('index');
    disp(['Current buffer index: ' num2str(curindex)]);
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end

    % wait until start playing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index');
        pause(.05);
    end

    % load segment B
    top = min(index+bufpts, sz);
    RP.WriteTagVEX('datain', bufpts, 'F32', s1(index:top));
    index = top;

    % make sure we're still playing A 
    curindex = RP.GetTagVal('index');
    disp(['Current index: ' num2str(curindex)]);
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end

end

% stop playing
RP.SoftTrg(2);
RP.Halt;