function [fs] = Continuous_Play_and_Acquire_YS(stim, acquisition_file_path)

% One-channel continuous play example using a serial buffer
% This program writes to the buffer once it has cyled halfway through
% (double-buffering)



save_path = [acquisition_file_path, '_mic.F32'];

%% Initialize Amplifier 
circuit_file_name = 'Continuous_Play_and_Acquire_YS.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% filePath - set this to wherever the examples are stored

RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3))
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end

%% Initiate DAQ
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.outputSingleScan(0); %run this line to turn it off

%% Create signal

% size of the entire serial buffer
npts = RP.GetTagSize('data_play');
% should be same size
% npts = RP.GetTagSize('data_rec');  

% serial buffer will be divided into two buffers A & B
bufpts = npts/2; 

% get device sampling frequency
fs = RP.GetSFreq();


sig_size = length(stim);
if rem(ceil(sig_size / bufpts),2) == 1
    % add another buffer of zeros, to prevent error
    stim = [stim, zeros(1, 50000)];
    sig_size = length(stim);
end


%%
% Create file to save data
fnoise = fopen(save_path,'w');

% load up entire buffer with segments A and B
RP.WriteTagVEX('data_play', 0, 'F32', stim(1:npts));
index_start = npts+1;

%% alignment pulse through NI DAQ
session.outputSingleScan(0);
pause(2);
session.outputSingleScan(3);
pause(1);
session.outputSingleScan(0);
pause(2);

%% start playing and recording
RP.SoftTrg(1);
curindex = RP.GetTagVal('index_A_play');
disp(['Current buffer index: ' num2str(curindex)]);


%% main looping section
h = waitbar(0,'Progress...');

figure;
while index_start < sig_size

    % wait until done playing and writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index_A_play');
        %pause(.05);
    end
    
    % wait until done writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index_A_rec');
    end
    
    % load the next signal segment
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', 0, 'F32', stim(index_start:index_end));
    index_start = index_end+1;

    % read segment A and save
    noise = RP.ReadTagVEX('data_rec', 0, bufpts, 'F32', 'F32', 1);
    fwrite(fnoise,noise,'float32');
    
    % checks to see if the data transfer rate is fast enough
    curindex = RP.GetTagVal('index_A_play');
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end


    % wait until start playing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index_A_play');
        pause(.05);
    end
    
     % wait until start writing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index_A_rec');
    end
    
    

    % load segment B
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', bufpts, 'F32', stim(index_start:index_end));
    index_start = index_end+1;
    
    % read segment B
    noise = RP.ReadTagVEX('data_rec', bufpts, bufpts, 'F32', 'F32', 1);
    fwrite(fnoise,noise,'float32');
    

    % make sure we're still playing A 
    curindex = RP.GetTagVal('index_A_play');
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end
    
    waitbar(index_start / sig_size,h);
    pwelch(noise,200, 50, 200, fs);
    drawnow;
end
close(h);
fclose(fnoise);

% stop playing
RP.SoftTrg(2);
RP.Halt;

%% alignment pulse through NI DAQ
session.outputSingleScan(0);
pause(2);
session.outputSingleScan(3);
pause(1);
session.outputSingleScan(0);
pause(2);

%% Stop DAQ
session.stop
session.removeChannel(1);

disp('Done...');



%%
% plots the last npts data points
% 
% fid = fopen('chirp.f32');
% 
% data = fread(fid, 'float32');
% 
% fclose(fid);

% figure;
% plot(data);


% figure;
% spectrogram(data, 200, 50, 200, fs, 'yaxis');

% figure;
% pwelch(data,200, 50, 200, fs);

end
