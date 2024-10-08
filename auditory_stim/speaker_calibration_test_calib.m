
params.pure_tones = 1;
params.gain_DB = 40;      % same as set on amplifier

% % 70 db volt
% params.freqs_to_test = [2, 3, 4.5, 6.75, 10.125, 15.188, 22.781, 34.172, 51.258, 76.887];
% params.modulation_amp = [8.98, 8.52, 8.06, 10, 2.74, 3.06, 4.7, 2.27, 2.93, 6.08];
% 
% % 66 db volt
% params.freqs_to_test = [2, 3, 4.5, 6.75, 10.125, 15.188, 22.781, 34.172, 51.258, 76.887];
% params.modulation_amp = [8.98, 8.52, 8.06, 5.2, 1.07, 1.1, 2.45, 0.98, 1.67, 6.08];
% 
% % 70 db volt
% params.freqs_to_test = [2 4 6 8 10 12 14 16 18 20 25 30 35 40 45 50 55 60 65 70 75 80];
% params.modulation_amp = [8.98, 8.1, 10, 6.42, 2.75, 3.75, 1.85, 5, 8.3, 7.94, 4.73, 4.28, 2.15, 3.47, .17, 2.74, 6.01, 8.03, 6.1, 8.99, 9, 5.93];

% 66 db volt
params.freqs_to_test = [2 4 6 8 10 12 14 16 18 20 25 30 35 40 45 50 55 60 65 70 75 80];
params.modulation_amp = [8.98, 8.1, 9.52, 3.14, 1.08, 1.87, 0.68, 2.03, 3.69, 3.69, 2.27, 1.95, 0.88, 2.06, 1.64, 1.64, 2.74, 9.91, 6.1, 6.32, 9, 5.93];

params.num_rep = 5;

params.stim_duration = 1;

params.base_freq = 0.001;
params.base_mod = 0.001;

%% initialize RZ6
pwd2 = fileparts(which('speaker_calibration_test_calib.m')); %mfilename
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
addpath([pwd2, '\functions'])

%%
if params.pure_tones
    [RP, fs] = f_RZ6_CP_initialize([circuit_path 'pure_tone_play_acquire_YS.rcx']);
else
    [RP, fs] = f_RZ6_CP_initialize([circuit_path 'sine_mod_play_acquire_YS.rcx']);
end
params.fs = fs;

params.buf_size = RP.GetTagVal('bufSize');

% RP.SetTagVal('ModulationAmp', 5);
% RP.SetTagVal('CarrierFreq', 10*1000);
% pause(.1);
RP.SetTagVal('ModulationAmp', params.base_mod);
RP.SetTagVal('CarrierFreq', params.base_freq);
RP.SetTagVal('ModulationAmp', params.base_mod);
RP.SetTagVal('CarrierFreq', params.base_freq);

%%
num_freqs = numel(params.freqs_to_test);

[freq_mesh,amp_mesh] = meshgrid(1:numel(params.freqs_to_test),1:numel(params.amps_to_test));

num_tr = numel(freq_mesh);

data_all = cell(num_freqs, num_amps, params.num_rep);

for n_rep = 1:params.num_rep
    rand_ind = randsample(num_freqs, num_freqs);
    for n_samp = 1:num_freqs
        amp1 = params.modulation_amp(rand_ind(n_samp));
        freq1 = params.freqs_to_test(rand_ind(n_samp));
        fprintf('rep%d/%d; n%d/%d; amp: %.1fV; freq %.2fkHz\n', n_rep, params.num_rep, n_samp, num_freqs, amp1, freq1);
        %disp(['n=' num2str(n_samp) '/' num2str(num_tr) ' amp: ' num2str(params.amps_to_test(n_amp)) ' freq: ' num2str(params.freqs_to_test(n_freq))]);
        RP.SetTagVal('ModulationAmp', amp1);
        RP.SetTagVal('CarrierFreq', freq1*1000);
        pause(0.5);
        %tic;
        data_all{n_freq, n_amp, n_rep} = f_RZ6_acquire_sound(RP, fs, params.stim_duration);
        %toc;
        RP.SetTagVal('ModulationAmp', params.base_mod);
        RP.SetTagVal('CarrierFreq', params.base_freq);
        pause(0.5);
        %pause(isi);
    end
end
      
RP.Halt;

%% save
save_path = [pwd2 '\..\..\stim_scripts_output\'];

temp_time = clock;
file_name = sprintf('speaker_test_40dbgain_nocov_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

data_st = struct;
data_st.data_all = data_all;
data_st.params = params;

fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'data_st', '-v7.3');
fprintf('Done\n');

