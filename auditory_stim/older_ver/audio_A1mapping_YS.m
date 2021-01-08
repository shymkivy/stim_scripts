% under construction


clear;
close all;
clc;

% voltage output from Out-B: 1kHz = 0.01V
tic
circuit_file_name = 'audio_YS_sinusoidal_mod.rcx';


trials = 400;
duration = 0.1; % in sec
isi = 1.9;
modulation_amp = 10;
num_freqs = 10;
start_freq = 2000; %kHz
increase_factor = 1.5;

use_LED_as_lighsource = 1;

pretrial_LED_pulse = 1; % do you want to use LED pulse before every stim
pretrial_pulse_duration = 0.1; % length of LED pulse
pretrial_pulse_wait = 0.4; % how long to wait after LED

disp('Run estimate (sec):');
disp(trials*(duration+isi+pretrial_LED_pulse*(pretrial_pulse_duration+pretrial_pulse_wait)) + 100);


% generate control frequencies
% each frequency is a multiple of the previous (logarithmic, for octaves factor = 2)

control_carrier_freq = zeros(1, num_freqs);
control_carrier_freq(1) = start_freq;
for ii = 2:num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * increase_factor;
end

carrier_freq = [control_carrier_freq(2), control_carrier_freq(6)]; % in Hz
base_freq = 0.001; % baseline frequency

deviance_prob = 0.1;

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1)
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% loadCOF clears device memory buffers, while readCOF doesn't
load_e=RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3))
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end
RP.Halt;


% for LED
if use_LED_as_lighsource == 1
    Ooff = 3;
    Oon = 0;
else
    Ooff=0; %volts
    Oon=3; %volts. with full power, this is about 1mW total power. so over 250um, it is 4mW/mm^2
end
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev3','ao0','Voltage');
session.addAnalogOutputChannel('Dev3','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,Ooff]);



% run circuit
RP.Run;
RP.SetTagVal('ModulationAmp', modulation_amp);


% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end

session.outputSingleScan([0,Ooff]);
% sync pulse
start1 = GetSecs();
nows=GetSecs();
session.outputSingleScan([1,Oon]);
while nows<start1+1;        
    nows=GetSecs();
end
session.outputSingleScan([0,Ooff]);


% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end

% Control run
for tr=1:trials
    freq_type = round(rand*(size(control_carrier_freq,2)-1))+1;
    start1 = GetSecs();
    nows=GetSecs();
    if pretrial_LED_pulse == 1
        session.outputSingleScan([0 Oon]);
        session.outputSingleScan([0 Oon]);
        while nows<start1+pretrial_pulse_duration      
            nows=GetSecs();
        end
        session.outputSingleScan([0 Ooff]);
        session.outputSingleScan([0 Ooff]);
        while nows<start1+pretrial_pulse_duration+pretrial_pulse_wait      
            nows=GetSecs();
        end
        start1 = GetSecs();
        nows=GetSecs();
    end
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', control_carrier_freq(freq_type));
    session.outputSingleScan([freq_type/size(control_carrier_freq,2)*4 Ooff]);
    session.outputSingleScan([freq_type/size(control_carrier_freq,2)*4 Ooff]);
    while nows<start1+duration;        
        nows=GetSecs();
    end
    % stop audio circuit
    
    
    disp(tr);
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 Ooff]);
    session.outputSingleScan([0 Ooff]);
    % inter stimulus interval
    start2=GetSecs();
    nows=GetSecs();
    while nows<start2+isi;  
        nows=GetSecs();
    end
end

% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end

% sync pulse
start1 = GetSecs();
nows=GetSecs();
session.outputSingleScan([1,Oon]);

while nows<start1+1;        
    nows=GetSecs();
end
session.outputSingleScan([0,0]);


% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end


RP.Halt; % stop RP circuit
toc

