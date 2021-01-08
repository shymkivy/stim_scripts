clear;
close all;

%% some parameters 
% save_data_path

% to only play, "play_and_record = 0"
% play and record, "play_and_record = 1"
play_and_record = 0;


trials = 400;            % per stimulus
isi = 1.500;            % ms
synch_pause_time = [10,1,10];
widefield_LED = 1;


fprintf('Approximate run time: %d sec\n',round(2*trials*(18.7465 + isi + 1.2) + 100));

stim_amplitude = 10;    

%% save output path
save_path = 'C:\Users\YusteLab\Desktop\Yuriy\A1_freq_stim_output\';
acquisition_file_name = 'freq_sweeps';

%% file name generation
% add time info to saved file name
temp_time = clock;
save_note = '';
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];

acquisition_file_path = [save_path, acquisition_file_name,time_stamp];


%% 
sig_dt = 1/195312.5; % 100kHz sampling signal
ms_dt = 1/1000; % dt of template for generating signal

%% Create stimuli frequencies
start_freq = 1000;  % Hz
end_freq = 80000;   % Hz

% first create onset and offset pulses
on_off_pulse_length = 0.1;      % sec
on_off_ramp_length = 0.005;     % sec
on_off_pulse_time = sig_dt:sig_dt:on_off_pulse_length;
ramp_time = sig_dt:sig_dt:on_off_ramp_length;

on_pulse = sin(start_freq*on_off_pulse_time*2*pi);
off_pulse = sin(end_freq*on_off_pulse_time*2*pi);

% add 5ms on and off ramp ramp
on_pulse(1:length(ramp_time)) = on_pulse(1:length(ramp_time)).*(1-(cos(((ramp_time)*2*pi)*(0.5/on_off_ramp_length))))/2;
off_pulse(end-length(ramp_time)+1:end) = off_pulse(end-length(ramp_time)+1:end).*(1+(cos(((ramp_time)*2*pi)*(0.5/on_off_ramp_length))))/2;
clear ramp_time on_off_pulse_time on_off_pulse_length on_off_ramp_length;


% sweep_speed
min_speed = 1;      % octaves/sec
max_speed = 64;     % octaves/sec

% change in speed factor
speed_increase_factor = 1.5;

num_steps = ceil(log(max_speed/min_speed)/log(speed_increase_factor));

sweep_speeds = zeros(num_steps,1);
for ii = 1:num_steps
    sweep_speeds(ii) = min_speed * speed_increase_factor^(ii-1);
end

% for each sweep speed compute length of sweeps in sec
sweep_lengths = (log(end_freq/start_freq)/log(2))./sweep_speeds;

% create all stims
all_stims = cell(num_steps,1);
for ii = 1:num_steps
    temp_pulse_time = sig_dt:sig_dt:sweep_lengths(ii);
    temp_buffer_tone = sig_dt:sig_dt:0.1;
    all_stims{ii} = [on_pulse, chirp(temp_pulse_time,start_freq,sweep_lengths(ii),end_freq,'logarithmic'), off_pulse];
end
clear temp_pulse_time;

%% Create the isi

isi_pulse = zeros(1,round(isi/sig_dt));



%% randomize stims

trial_type = repmat([1:num_steps, -(1:num_steps)], [1, trials])';
trials_seq = randsample(trial_type, length(trial_type));



freq_sweep_stim = zeros(1,round(trials*(sum(sweep_lengths)+ 0.2 + isi + 1)/sig_dt));
stim_index = zeros(length(trials_seq),1);
% create concatenated stim
current_stim_time = 1;

for ii = 1:length(trial_type)
    temp_trial = trials_seq(ii);
    if temp_trial > 0
        temp_stim = [all_stims{temp_trial}, isi_pulse, zeros(1,round(rand(1)/sig_dt))];
    elseif temp_trial < 0
        temp_stim = [fliplr(all_stims{-temp_trial}), isi_pulse, zeros(1,round(rand(1)/sig_dt))];
    end

    freq_sweep_stim(current_stim_time:round(current_stim_time+length(temp_stim)-1)) = temp_stim;
    stim_index(ii) = current_stim_time;
    
    current_stim_time = length(temp_stim)+current_stim_time;
end
clear temp_stim;

%% adjust amplitude

freq_sweep_stim = freq_sweep_stim * stim_amplitude;


%% Play

if play_and_record == 1
    amp_fs = Continuous_Play_and_Acquire_YS(freq_sweep_stim, acquisition_file_path);
else
    amp_fs = Continuous_Play_YS(freq_sweep_stim, synch_pause_time, widefield_LED);
end

if amp_fs ~= 1/sig_dt
    warning('Sampling of script and circuit doesnt match');
end

    
%% downsample
freq_sweep_stim_dsp = zeros(floor(length(freq_sweep_stim)/(1e-3/sig_dt)),1);
for ii = 1:numel(freq_sweep_stim_dsp)
    freq_sweep_stim_dsp(ii) = freq_sweep_stim(round(ii*(1e-3/sig_dt)-1e-3/sig_dt/2));
end

%% Save info
save([acquisition_file_path, '_stim_data'], 'save_note','freq_sweep_stim','freq_sweep_stim_dsp', 'stim_index', 'sig_dt', 'stim_amplitude', 'synch_pause_time', 'widefield_LED', '-v7.3');



%% some plots

% t_stim = (1:length(full_stim))'*sig_dt;
% t_stim_dsp = (1:length(full_stim_dsp))';
% 
% figure;
% plot(t_stim, full_stim)
% 
% figure;
% plot(t_stim_dsp, full_stim_dsp)

% figure;
% spectrogram(freq_sweep_stim,200,10,200, 1/sig_dt, 'yaxis');

