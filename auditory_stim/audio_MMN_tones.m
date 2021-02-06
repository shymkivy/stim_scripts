clear;
close all;
clc;

tic
% voltage output from Out-B: 1kHz = 0.01V
% 40 trials takes ~175sec
% 100 trials takes ~380sec
% 
% trisl_times = zeros(200,1);
% 
% paradigm_start_time = now*86400;
% trisl_times(tr) = now*86400- paradigm_start_time;


%% some parameters

trials = 400;
duration = 0.5; % in sec
isi = 0.5;
modulation_amp = 10;
num_freqs = 10;
start_freq = 2000; %kHz
increase_factor = 1.5;
initial_stim_adaptation = 30;
% this meand that redundant is 4 in MMN and 7 in flipMMN
MMN_freq = [5, 7];
intertrial_pause =  25; % sec
synch_pause_time = [2,1,2];

%%
disp('Run estimate');
disp(2*trials*(duration+isi+0.05) + 2*intertrial_pause + 4*5 + 60);

%% save output path
pwd2 = fileparts(which('audio_MMN_tones.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';

temp_time = clock;
file_name = sprintf('aMMN_tones_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

%% file name generation
% add time info to saved file name
temp_time = clock;
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];

acquisition_file_path = [save_path, acquisition_file_name,time_stamp];

%%
% generate control frequencies
control_carrier_freq = zeros(1, num_freqs);
control_carrier_freq(1) = start_freq;
for ii = 2:num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * increase_factor;
end

carrier_freq = [control_carrier_freq(MMN_freq(1)), control_carrier_freq(MMN_freq(2))]; % in Hz

% initiate amplifier
base_freq = 0.001; % baseline frequency
deviance_prob = [.01 .01 .01 .01 .01 .01 .1 .1 .3 .5 1];

%%
RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
RP.Halt;

%%
% for LED
Ooff=0; %volts
Oon=3; %volts. with full power, this is about 1mW total power. so over 250um, it is 4mW/mm^2
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
%session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,Ooff]); %run this line to turn it off

%%
stim_times = zeros(trials + 2*floor(trials/2),1);
stim_types = zeros(trials + 2*floor(trials/2),1);
synch_pulse_times = zeros(4,1);

%% run audio circuit

RP.Run;
paradigm_start=now*86400;

synch_pulse_times(1) = IF_synch_pulse(synch_pause_time, session, Oon, Ooff)-paradigm_start;

% Control run
disp('Control trials...');
for tr=1:trials
    freq_type = round(rand*(num_freqs-1))+1;
    start1 = now*86400;
    
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', control_carrier_freq(freq_type));
    session.outputSingleScan([freq_type/num_freqs*4 0]);
    
    fprintf('Trial %i, %0.1fkHz\n', tr, control_carrier_freq(freq_type)/1000);
    stim_times(tr) = start1-paradigm_start;
    stim_types(tr) = freq_type;
    
    % pause
    nows=now*86400;
    while nows<start1+duration
        nows=now*86400;
    end
    
    % stop audio circuit
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0, 0]);
    
    % inter stimulus interval
    start2=now*86400;
    nows=now*86400;
    while nows<start2 + isi + rand(1)/10
        nows=now*86400;
    end
end

% pause between trials
pause(intertrial_pause)
synch_pulse_times(2) = IF_synch_pulse(synch_pause_time, session, Oon, Ooff)-paradigm_start;

% MMN
disp('MMN trials...');
redundant_count = 0;
for tr=1:floor(trials/2)
    if tr < initial_stim_adaptation
        freq_type = 1;
    else
        freq_type = single(rand(1)<=deviance_prob(redundant_count+1)) + 1;
        if freq_type == 1
            redundant_count = redundant_count + 1;
        elseif freq_type == 2
            redundant_count = 0;
        end
    end
    
    start1 = now*86400;
    
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', carrier_freq(freq_type));
    session.outputSingleScan([freq_type/num_freqs*4 0]);
    fprintf('Trial %i, %0.1fkHz\n', tr, carrier_freq(freq_type)/1000);
    stim_times(tr + trials) = start1-paradigm_start;
    stim_types(tr + trials) = freq_type;
    
    % pause
    nows=now*86400;
    while nows<start1+duration
        nows=now*86400;
    end
    
    % stop audio circuit
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 0]);
    % inter stimulus interval
    start2=now*86400;
    nows=now*86400;
    while nows<start2 + isi + rand(1)/10
        nows=now*86400;
    end
end

% pause between trials
pause(intertrial_pause)
synch_pulse_times(3) = IF_synch_pulse(synch_pause_time, session, Oon, Ooff)-paradigm_start;

% inverted MMN
disp('flipMMN trials...');
redundant_count = 0;
for tr=1:floor(trials/2)
    if tr < initial_stim_adaptation
        freq_type = 2;
    else
        freq_type = single(rand(1)<=(1-deviance_prob(redundant_count+1))) + 1;
        if freq_type == 2
            redundant_count = redundant_count + 1;
        elseif freq_type == 1
            redundant_count = 0;
        end
    end
    
    start1 = now*86400;
    
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', carrier_freq(freq_type));
    session.outputSingleScan([freq_type/num_freqs*4 0]);
    fprintf('Trial %i, %0.1fkHz\n', tr, carrier_freq(freq_type)/1000);
    stim_times(tr + trials + floor(trials/2)) = start1-paradigm_start;
    stim_types(tr + trials + floor(trials/2)) = freq_type;
    
    % pause
    nows=now*86400;
    while nows<start1+duration
        nows=now*86400;
    end
    
    % stop audio circuit
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 0]);

    % inter stimulus interval
    start2=now*86400;
    nows=now*86400;
    while nows<start2 + isi + rand(1)/10
        nows=now*86400;
    end
end

synch_pulse_times(4) = IF_synch_pulse(synch_pause_time, session, Oon, Ooff)-paradigm_start;

RP.Halt;
toc

%% saving stuff
save([save_path, file_name, '.mat'],'trials','duration', 'isi', 'modulation_amp', 'num_freqs', 'start_freq', 'increase_factor', 'initial_stim_adaptation', 'MMN_freq', 'intertrial_pause', 'synch_pause_time', 'stim_times', 'stim_types', 'synch_pulse_times');

disp('Done');

%%
function pulse_time = IF_synch_pulse(synch_pause_time, session, Oon, Ooff)
    
    disp('Synch pulse...');
    % wait 
    pause(synch_pause_time(1))

    % sync pulse
    session.outputSingleScan([1,Oon]);
    pulse_time = now*86400;
    pause(synch_pause_time(2));
    session.outputSingleScan([0,Ooff]);

    % wait
    pause(synch_pause_time(3));
end

