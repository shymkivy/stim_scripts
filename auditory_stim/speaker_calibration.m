
params.pure_tones = 1;
params.gain_DB = 0;

params.freqs_to_test = [0 2 4 6 10 16 20 40 60 80];
params.amps_to_test = [0 1 2 4 6 10];

[freq_mesh,amp_mesh] = meshgrid(1:numel(params.freqs_to_test),1:numel(params.amps_to_test));
rand_ind = randsample(numel(freq_mesh), numel(freq_mesh));


params.stim_duration = .5;

params.base_freq = 0.001;
params.base_mod = 0.001;

%% initialize RZ6
num_freqs = numel(params.freqs_to_test);
num_amps = numel(params.amps_to_test);

circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
if params.pure_tones
    [RP, fs] = f_RZ6_CP_initialize([circuit_path 'pure_tone_play_acquire_YS.rcx']);
else
    [RP, fs] = f_RZ6_CP_initialize([circuit_path 'sine_mod_play_acquire_YS.rcx']);
end
params.fs = fs;

RP.SetTagVal('ModulationAmp', 5);
RP.SetTagVal('CarrierFreq', 10*1000);
pause(.1);
RP.SetTagVal('ModulationAmp', params.base_mod);
RP.SetTagVal('CarrierFreq', params.base_freq);

data_all = cell(num_freqs, num_amps);

for n_samp = 1:numel(freq_mesh)
    n_amp = amp_mesh(rand_ind(n_samp));
    n_freq = freq_mesh(rand_ind(n_samp));
    disp(['n=' num2str(n_samp) '/' num2str(numel(freq_mesh)) ' amp: ' num2str(params.amps_to_test(n_amp)) ' freq: ' num2str(params.freqs_to_test(n_freq))]);
    RP.SetTagVal('ModulationAmp', params.amps_to_test(n_amp));
    RP.SetTagVal('CarrierFreq', params.freqs_to_test(n_freq)*1000);
    pause(.1);
    %tic;
    data_all{n_freq, n_amp} = f_RZ6_acquire_sound(RP, fs, params.stim_duration);
    %toc;
    RP.SetTagVal('ModulationAmp', params.base_mod);
    RP.SetTagVal('CarrierFreq', params.base_freq);
    pause(.1);
    %pause(isi);
end

%%      
RP.Halt;

%% save

pwd2 = fileparts(which('speaker_calibration.m')); %mfilename
save_path = [pwd2 '\..\..\stim_scripts_output\'];

temp_time = clock;
file_name = sprintf('speaker_cal_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

data_st = struct;
data_st.data_all = data_all;
data_st.params = params;

fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'data_st');
fprintf('Done\n');

%% analyze

data_load = load([save_path, 'speaker_cal_9_5_24_stim_data_10h_39m'], 'data_st');
data_st = data_load.data_st;
data_all = data_st.data_all;
params = data_st.params;
fs = params.fs;

%%
num_freqs = numel(params.freqs_to_test);
num_amps = numel(params.amps_to_test);

if params.pure_tones
    title1 = 'pure tones';
else
    title1 = 'SAM tones';
end

Pref = 2e-5;        % p reference
S = 2.2*10e-3; %mV/Pa

mbFilt = designfilt('highpassiir','FilterOrder',5, ...
         'PassbandFrequency', 500,'PassbandRipple',0.2, ...
         'SampleRate',fs);

buff = 0;
data_all2 = data_all;
freq_amp_vol = zeros(num_freqs, num_amps);
for n_freq = 1:num_freqs
    for n_amp = 1:num_amps
        data_out = filter(mbFilt, data_all2{n_freq, n_amp});
        data_all2{n_freq, n_amp} = data_out(1+buff:end - buff);
        Vrms = rms(data_all2{n_freq, n_amp});
        freq_amp_vol(n_freq, n_amp) = 20*log10(Vrms/(S*Pref))-params.gain_DB;
    end
end

amp_c = jet(num_amps);
figure; hold on;
amp_leg = cell(num_amps,1);
for n_amp = 1:num_amps
    plot(params.freqs_to_test, freq_amp_vol(:,n_amp), 'color', amp_c(n_amp,:))
    amp_leg{n_amp} = num2str(params.amps_to_test(n_amp));
end
legend(amp_leg)
title(title1);

for n_amp = 1:num_amps
    for n_freq = 1:num_freqs
        figure; plot(data_all2{n_freq, n_amp})
        title(sprintf('%dkHz; %damp', params.freqs_to_test(n_freq), params.amps_to_test(n_amp)))
    end
end
% 
% %figure; imagesc(reshape(amp_c, [],1,3))
% 
n_freq = 10;
n_amp = 5;
figure; hold on;
pwelch(data_all2{n_freq, n_amp},500, 100, 500, fs);



% pwelch(data_all2{n_freq, 2},500, 100, 500, fs);
% pwelch(data_all2{n_freq, 3},500, 100, 500, fs);