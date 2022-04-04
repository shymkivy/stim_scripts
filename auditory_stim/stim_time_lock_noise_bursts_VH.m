%% time-lock stimuli triger for praire 
% updated: Victor Hugo Cornejo, 08-09-21
clear;
close all
clc;
%% param

initialDelay=3;   % min 1
interStim=363;   % min 2//    58/100hz  112/200hz  30/60hz
trials=100;
pulseDur=0.1; % in seconds

frame_period=5.5;       %%4.5ms64x64z32   8.6ms128x128z20  17ms256x246z10

%% Setup
session = daq.createSession ('ni');
addAnalogOutputChannel(session,'Dev1','ao3','Voltage');
outputSingleScan(session,0);
c=addCounterInputChannel(session,'Dev1', 'ctr1', 'EdgeCount');
resetCounters(session);
d=inputSingleScan(session);

%%
total_pre=(initialDelay+interStim-1);
total_frames=total_pre+(trials*interStim); total_time=total_frames*frame_period;
disp(['Set imaging and recording at ' num2str(total_frames)...
    ' frames or ' num2str(total_time) ' ms' ]); disp('Ready to image...');

%% audio settings

pwd2 = fileparts(which('audio_ACmapping.m')); %mfilename
addpath([pwd2 '\functions']);
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'Band_Limited_Noise_VH.rcx';
RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
RP.Halt;
RP.SetTagVal('Amp2',0);
RP.Run;

%%

while inputSingleScan(session)==initialDelay
end
outputSingleScan(session,0);
pauses(pulseDur)
outputSingleScan(session,0)
resetCounters(session);

while inputSingleScan(session)~=initialDelay
end
outputSingleScan(session,0);
pauses(pulseDur)
outputSingleScan(session,0)
resetCounters(session);

for i=1:trials
%     interStim=randi([100 500],1);   % for random stim time
    while inputSingleScan(session)~=interStim
    end
    outputSingleScan(session,5);
    RP.SetTagVal('Amp2',10);
    pauses(pulseDur)
    outputSingleScan(session,0)
    RP.SetTagVal('Amp2',0);
    resetCounters(session);
end
outputSingleScan(session,0);
RP.Halt;

disp('Done');