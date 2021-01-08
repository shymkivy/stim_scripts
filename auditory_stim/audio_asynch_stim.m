clear;
close all;

%% initialize the frequencies from 1 to 100kHz with 1/12 octave 
% to only play, "play_and_record = 0"
% play and record, "play_and_record = 1"
play_and_record = 0;

synch_pause_time = [5,1,5];
widefield_LED = 0;

start_freq = 2;
end_freq = 90;
freq_steps = 1 + 1/12;
num_freqs = ceil(log(end_freq/start_freq)/log(freq_steps));

rel_volumes_dB = [0 5 10];
modulation_amp_volt = 10.^(rel_volumes_dB./20);
total_speaker_volt = 10;

freqs = zeros(num_freqs,1);
for n_stim = 1:num_freqs
    freqs(n_stim) = start_freq * freq_steps^(n_stim-1);
end
% 10 min, 30,000 20ms chords (50 chords/s) one tone per octave (7/84 per chord)


%% save output path
pwd2 = fileparts(which('audio_asynch_stim.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];

temp_time = clock;
file_name = sprintf('asynch_tones_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

%% crate random asynchronized stym positions
% parameters
disp('Synthetizing...');

sig_dt = 1/195312.5; % sampling signal
ms_dt = 1/1000; % dt of template for generating signal

stim_length = 600; % sec
pulse_size = 0.1; % sec
on_off_ramp_length = 0.005; %sec

tone_density = 1/12; % on average one tone in 12 times the tone length period

time_sig = sig_dt:sig_dt:stim_length;
time_sig_ms = ms_dt:ms_dt:stim_length;
time_pulse = sig_dt:sig_dt:pulse_size;

num_stim = round(stim_length/(pulse_size/tone_density));


%% create a kernel to shape the pulse
kernel = ones(size(time_pulse));

% create on and off 5ms cosine ramps
ramp_time = sig_dt:sig_dt:on_off_ramp_length;
kernel(1:length(ramp_time)) = (1-(cos(((ramp_time)*2*pi)*(0.5/on_off_ramp_length))))/2;
kernel((length(kernel)-length(ramp_time)+1):end) = (1+(cos(((ramp_time)*2*pi)*(0.5/on_off_ramp_length))))/2;


% figure;
% plot(sig_dt:sig_dt:pulse_size,kernel);
% xlabel('Time, ms');


%% Asynchronous tone trains
% generate the random stim times

refractory_period = 0.1; %ms

stim_onset_times = zeros(num_freqs, num_stim);
stim_volumes = zeros(num_freqs, num_stim);
vol_pool = repmat(modulation_amp_volt',ceil(num_stim/numel(modulation_amp_volt)),1);
for n_freq = 1:num_freqs
    % first get the onset times for all stimuli
    temp_time = round((length(time_sig_ms)-pulse_size*1000)*rand(1));
    stim_onset_times(n_freq,1) = temp_time;
    for n_stim = 2:num_stim
        while sum(abs(stim_onset_times(n_freq,1:n_stim-1) - temp_time) < (refractory_period+pulse_size)*1000)>0
            temp_time = round((length(time_sig_ms)-pulse_size*1000)*rand(1));
            stim_onset_times(n_freq,n_stim) = temp_time;
        end
    end
    stim_onset_times(n_freq,:) = sort(stim_onset_times(n_freq,:));
    stim_volumes(n_freq,:) = vol_pool(randperm(num_stim));
end

asynch_stim = zeros(size(time_sig));
for n_freq = 1:num_freqs    
    % now for each stim generate a signal
    for n_stim = 1:num_stim
        temp_trace = kernel.*sin(1000*freqs(n_freq)*(time_pulse*2*pi+rand(1)))*stim_volumes(n_freq,n_stim);
        temp_index = round(stim_onset_times(n_freq,n_stim)*(0.001/sig_dt));        
        asynch_stim(temp_index:round(temp_index+pulse_size/sig_dt-1)) = asynch_stim(temp_index:round(temp_index+pulse_size/sig_dt-1)) + temp_trace;        
    end    
end

%% adjust amplitude
% power calculate
%rms(asynch_stim*4)


% here make it louder by adjusting the amplitudes
asynch_stim = asynch_stim/(5*std(asynch_stim));

% erase all data points outside of bounds
asynch_stim(asynch_stim>1) = 1;
asynch_stim(asynch_stim<-1) = -1;

asynch_stim = asynch_stim*total_speaker_volt;

%% plot stuff
% figure;
% plot(time_sig(1:10000000), asynch_stim(1:10000000))
% 
% figure;
% spectrogram( asynch_stim(1:10000000),1000,100,1000, 1/sig_dt, 'yaxis');
% 
% figure;
% plot(abs(fft(asynch_stim)));
% 
% figure;
% histogram(asynch_stim, 100);


%% Play
disp('Playing...');

if play_and_record == 1
    amp_fs = Continuous_Play_and_Acquire_YS(asynch_stim, acquisition_file_path);
else
    amp_fs = Continuous_Play_YS(asynch_stim, synch_pause_time, widefield_LED);
end

if amp_fs ~= 1/sig_dt
    warning('Sampling of script and circuit doesnt match');
end
    
%% downsample
asynch_stim_dsp = zeros(floor(length(asynch_stim)/(1e-3/sig_dt)),1);
for n_stim = 1:numel(asynch_stim_dsp)
    asynch_stim_dsp(n_stim) = asynch_stim(round(n_stim*(1e-3/sig_dt)-1e-3/sig_dt/2));
end

%% save data below
save([save_path, file_name, '.mat'],'asynch_stim','asynch_stim_dsp', 'sig_dt', 'stim_onset_times', 'stim_volumes', 'freqs', 'synch_pause_time', 'start_freq', 'end_freq', 'freq_steps', 'total_speaker_volt','-v7.3');

%save 'Freqs', 