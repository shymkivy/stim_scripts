% Create frequency stim for mapping
%
% last update 5/22/19
%

%%
clear;
close all;

pure_tone = 0;

tic;
if pure_tone
    circuit_file_name = 'pure_tone_play_YS.rcx';
else
    circuit_file_name = 'sine_mod_play_YS.rcx';
end

%% Stim info
trials = 800;
duration = 0.5; % in sec
isi = 2;
modulation_amp = 4; % Volume (0 - 10 Volts)
num_freqs = 20;
start_freq = 2000; %kHz
increase_factor = sqrt(1.5); % 

%% Script parameters
synch_pause_time = [10,1,10]; % [pause, synch_pulse, pause] in sec

use_LED_as_lighsource = 1; % 
% 0 LED will turn on for synch pulses only
% 1 LED is mostly on and will turn off for synch pulses

pretrial_LED_pulse = 0; % do you want to use LED pulse before every stim trial
pretrial_pulse_duration = 0.1; % length of LED pulse
pretrial_pulse_wait = 0.9; % how long to wait after LED


%%
disp('Run estimate (sec):');
disp(trials*(duration+isi+pretrial_LED_pulse*(pretrial_pulse_duration+pretrial_pulse_wait)) + 100);
%% save output path (saves stuff)
pwd2 = fileparts(which('audio_ACmapping.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];

temp_time = clock;
file_name = sprintf('AC_mapping_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

%%
% generate control frequencies
% each frequency is a multiple of the previous (logarithmic, for octaves factor = 2)

control_carrier_freq = zeros(1, num_freqs);
control_carrier_freq(1) = start_freq;
for ii = 2:num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * increase_factor;
end

carrier_freq = [control_carrier_freq(2), control_carrier_freq(6)]; % in Hz

%% RZ6 connect
base_freq = 0.001; % baseline frequency

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% loadCOF clears device memory buffers, while readCOF doesn't
load_e=RP.LoadCOF(strcat('C:\Users\rylab_901c\Desktop\Yuriy_scripts\stim_scripts\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3))
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end
RP.Halt;

%% DAQ connect
% for LED
if use_LED_as_lighsource == 1
    Ooff = 3;
    Oon = 0;
else
    Ooff=0; %volts
    Oon=3; %volts. with full power, this is about 1mW total power. so over 250um, it is 4mW/mm^2
end

session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,Ooff]);

%% Start run
disp('Start...');

% run circuit
RP.Run;
RP.SetTagVal('ModulationAmp', modulation_amp);
% for freq analysis
RP.SetTagVal('Start_freq', start_freq);
RP.SetTagVal('NumFreqs', num_freqs);
RP.SetTagVal('IncFactor', increase_factor);


stim_times = zeros(trials,1);
stim_types = zeros(trials,1);
synch_pulse_times = zeros(2,1);



%% Start paradigm
paradigm_start = now*86400;

%% sync pulse
pause(synch_pause_time(1))
session.outputSingleScan([1,Oon]);
synch_pulse_times(1) = now*86400 - paradigm_start;
pause(synch_pause_time(2));
session.outputSingleScan([0,Ooff]);
pause(synch_pause_time(3));

%% Control run
for tr=1:trials
    start1 = now*86400;
    
    freq_type = ceil(rand(1)*num_freqs);
    stim_types(tr) = freq_type;
    
    nows=now*86400;
    if pretrial_LED_pulse == 1
        session.outputSingleScan([0 Oon]);
        session.outputSingleScan([0 Oon]);
        while nows<start1+pretrial_pulse_duration      
            nows=now*86400;
        end
        session.outputSingleScan([0 Ooff]);
        session.outputSingleScan([0 Ooff]);
        while nows<start1+pretrial_pulse_duration+pretrial_pulse_wait      
            nows=now*86400;
        end
        start1 = now*86400;
        nows=now*86400;
    end
    
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', control_carrier_freq(freq_type));
    session.outputSingleScan([freq_type/num_freqs*4 Ooff]);
    session.outputSingleScan([freq_type/num_freqs*4 Ooff]);
    stim_times(tr) = now*86400 - paradigm_start;
    fprintf('trial %d; %.1fkHz\n', tr, control_carrier_freq(freq_type)/1000);
    while nows<start1+duration   
        nows=now*86400;
    end
    % stop audio circuit
    
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 Ooff]);
    session.outputSingleScan([0 Ooff]);
    % inter stimulus interval
    start2=now*86400;
    nows=now*86400;
    while nows<start2+isi
        nows=now*86400;
    end
end


%% sync pulse
pause(synch_pause_time(1))
session.outputSingleScan([1,Oon]);
synch_pulse_times(2) = now*86400 - paradigm_start;
pause(synch_pause_time(2));
session.outputSingleScan([0,Ooff]);
pause(synch_pause_time(3));

%% finish and close

RP.SetTagVal('CarrierFreq', base_freq);
RP.Halt; % stop RP circuit
session.outputSingleScan([0 0]);
toc;


%% saving stuff
save([save_path, file_name, '.mat'], 'trials','duration', 'isi', 'modulation_amp', 'num_freqs', 'start_freq', 'increase_factor', 'stim_times', 'stim_types', 'synch_pulse_times', 'synch_pause_time', 'use_LED_as_lighsource', 'pretrial_LED_pulse', 'pretrial_pulse_duration', 'pretrial_pulse_wait', 'pure_tone');

disp('Done');

