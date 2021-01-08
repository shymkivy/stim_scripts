clear;
close all;
clc;

tic
% voltage output from Out-B: 1kHz = 0.01V
% 40 trials takes ~175sec
% 100 trials takes ~380sec

circuit_file_name = 'audio_YS_sinusoidal_mod.rcx';


trials = 400;
duration = 0.1; % in sec
isi = 0.9;
modulation_amp = 10;
num_freqs = 10;
start_freq = 2000; %kHz
increase_factor = 1.5;
initial_stim_adaptation = 20;
carrier_feqs_index = [4, 8];


disp('Run estimate');
disp(2*trials*(duration+isi) + 150);


% generate control frequencies
control_carrier_freq = zeros(1, num_freqs);
control_carrier_freq(1) = start_freq;
for ii = 2:num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * increase_factor;
end

carrier_freq = [control_carrier_freq(carrier_feqs_index(1)), control_carrier_freq(carrier_feqs_index(2))]; % in Hz

% initiate amplifier
base_freq = 0.001; % baseline frequency
deviance_prob = [.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1)
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% loadCOF clears device memory buffers, while readCOF doesn't
load_e=RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3));
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end
RP.Halt;


% for LED
Ooff=0; %volts
Oon=3; %volts. with full power, this is about 1mW total power. so over 250um, it is 4mW/mm^2
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev3','ao0','Voltage');
session.addAnalogOutputChannel('Dev3','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,Ooff]); %run this line to turn it off


% NumParTags = RP.GetNumOf('ParTag');
% for z = 1:NumParTags
%     PName = RP.GetNameOf('ParTag',z);
%     % Returns the Parameter name
%     PType = char(RP.GetTagType(PName));
%     % Returns the Tag Type: Single, Integer, Data, Logical
%     PSize = RP.GetTagSize(PName);
%     % Returns TagSize (size of Data Buffer or 1)
%     disp([' ' PName ' type ' PType ' size ' num2str(PSize)]);
% end

RP.Run;

% sync pulse
start1 = GetSecs();
nows=GetSecs();
session.outputSingleScan([1,Oon]);
RP.SetTagVal('CarrierFreq', control_carrier_freq(5));
while nows<start1+1;        
    nows=GetSecs();
end
session.outputSingleScan([0,Ooff]);
RP.SetTagVal('CarrierFreq', base_freq);

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
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', control_carrier_freq(freq_type));
    session.outputSingleScan([freq_type/size(control_carrier_freq,2)*4 0]);
    while nows<start1+duration;        
        nows=GetSecs();
    end
    % stop audio circuit
    
    
    disp(tr);
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0, 0]);
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
RP.SetTagVal('CarrierFreq', control_carrier_freq(5));
while nows<start1+1;        
    nows=GetSecs();
end
session.outputSingleScan([0,Ooff]);
RP.SetTagVal('CarrierFreq', base_freq);


% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end

% MMN
redundant_count = 0;
for tr=1:trials/2
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
    start1 = GetSecs();
    nows=GetSecs();
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', carrier_freq(freq_type));
    session.outputSingleScan([freq_type/size(control_carrier_freq,2)*4 0]);
    while nows<start1+duration;        
        nows=GetSecs();
    end
    % stop audio circuit
   
    disp(tr);
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 0]);
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
RP.SetTagVal('CarrierFreq', control_carrier_freq(5));
while nows<start1+1;        
    nows=GetSecs();
end
session.outputSingleScan([0,Ooff]);
RP.SetTagVal('CarrierFreq', base_freq);


% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10;        
    nows=GetSecs();
end

% inverted MMN
redundant_count = 0;
for tr=1:trials/2
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
    start1 = GetSecs();
    nows=GetSecs();
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', carrier_freq(freq_type));
    session.outputSingleScan([freq_type/size(control_carrier_freq,2)*4 0]);
    while nows<start1+duration;        
        nows=GetSecs();
    end
    % stop audio circuit
    
    disp(tr);
    RP.SetTagVal('CarrierFreq', base_freq);
    session.outputSingleScan([0 0]);
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
RP.SetTagVal('CarrierFreq', control_carrier_freq(5));
while nows<start1+0.5;        
    nows=GetSecs();
end
session.outputSingleScan([0,Ooff]);
RP.SetTagVal('CarrierFreq', base_freq);

% wait 10 sec
start1 = GetSecs();
nows=GetSecs();
% Run audio circuit
while nows<start1+10
    nows=GetSecs();
end

RP.Halt;
toc

