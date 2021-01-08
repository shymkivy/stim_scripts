function [fs] = Continuous_Play_YS(stim, synch_pause_time, widefield_LED)

% One-channel continuous play example using a serial buffer
% This program writes to the buffer once it has cyled halfway through
% (double-buffering)


%% Initialize Amplifier 
circuit_file_name = 'Continuous_Play2_YS.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% filePath - set this to wherever the examples are stored

RP.LoadCOF(strcat('C:\Users\rylab_901c\Desktop\Yuriy_scripts\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

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
session.addAnalogOutputChannel('Dev1','ao1','Voltage');


if widefield_LED == 1
    Oon = 0;
    Ooff = 3;
else
    Oon = 3;
    Ooff = 0;
end

session.outputSingleScan([0,Ooff]);
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

% load up entire buffer with segments A and B
RP.WriteTagVEX('data_play', 0, 'F32', stim(1:npts));
index_start = npts+1;


%% alignment pulse through NI DAQ
synch_pulse(synch_pause_time, session, Oon, Ooff);

%% start playing and recording
RP.SoftTrg(1);
curindex = RP.GetTagVal('index_A_play');
disp(['Current buffer index: ' num2str(curindex)]);


%% main looping section
h = waitbar(0,'Progress...');
while index_start < sig_size

    % wait until done playing and writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index_A_play');
        %pause(.05);
    end
    
    
    % load the next signal segment
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', 0, 'F32', stim(index_start:index_end));
    index_start = index_end+1;


    % checks to see if the data transfer rate is fast enough
    curindex = RP.GetTagVal('index_A_play');
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end


    % wait until start playing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index_A_play');
        %pause(.05);
    end
    


    % load segment B
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', bufpts, 'F32', stim(index_start:index_end));
    index_start = index_end+1;


    % make sure we're still playing A 
    curindex = RP.GetTagVal('index_A_play');
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end
    
    waitbar(index_start / sig_size,h);
%     pwelch(noise,200, 50, 200, fs);
%     drawnow
end
close(h);


% stop playing
RP.SoftTrg(2);
RP.Halt;

%% alignment pulse through NI DAQ
synch_pulse(synch_pause_time, session, Oon, Ooff);

%% Stop DAQ
session.outputSingleScan([0,0]);
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

%%
function synch_pulse(synch_pause_time, session, Oon, Ooff)
    
    disp('Synch pulse...');
    % wait 
    pause(synch_pause_time(1))

    % sync pulse
    session.outputSingleScan([1,Oon]);
    pause(synch_pause_time(2));
    session.outputSingleScan([0,Ooff]);

    % wait
    pause(synch_pause_time(3));
end



end
