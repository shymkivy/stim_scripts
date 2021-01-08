clear;
close all;

%% initialize the frequencies from 1 to 100kHz with 1/12 octave 
% to only play, "play_and_record = 0"
% play and record, "play_and_record = 1"
play_and_record = 0;

synch_pause_time = [10,1,10];
widefield_LED = 1;

start_freq = 2;
end_freq = 90;
freq_steps = 1 + 1/12;
num_freqs = ceil(log(end_freq/start_freq)/log(freq_steps));

freqs = zeros(num_freqs,1);
for ii = 1:num_freqs
    freqs(ii) = start_freq * freq_steps^(ii-1);
end
% 10 min, 30,000 20ms chords (50 chords/s) one tone per octave (7/84 per chord)


%% save output path
save_path = 'C:\Users\rylab_901c\Desktop\Yuriy_scripts\A1_freq_stim_output\';
acquisition_file_name = 'asynch_tones';

%% file name generation
% add time info to saved file name
temp_time = clock;
save_note = '';
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];

acquisition_file_path = [save_path, acquisition_file_name,time_stamp];



%% crate random asynchronized stym positions
% parameters
disp('Synthetizing...');

sig_dt = 1/195312.5; % sampling signal
ms_dt = 1/1000; % dt of template for generating signal

stim_length = 1500; % sec
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

asynch_stim = zeros(size(time_sig));
stim_onset_times = zeros(num_freqs, num_stim);

for jj = 1:num_freqs
    
    
    % first get the onset times for all stimuli
    temp_time = round((length(time_sig_ms)-pulse_size*1000)*rand(1));
    stim_onset_times(jj,1) = temp_time;
    for ii = 2:num_stim
        while sum(abs(stim_onset_times(jj,1:ii-1) - temp_time) < (refractory_period+pulse_size)*1000)>0
            temp_time = round((length(time_sig_ms)-pulse_size*1000)*rand(1));
            stim_onset_times(jj,ii) = temp_time;
        end
    end
    
    % now for each stim generate a signal
    for ii = 1:num_stim
        temp_trace = kernel.*sin(1000*freqs(jj)*(time_pulse*2*pi+rand(1)));

        temp_index = round(stim_onset_times(jj,ii)*(0.001/sig_dt));
        
        asynch_stim(temp_index:round(temp_index+pulse_size/sig_dt-1)) = asynch_stim(temp_index:round(temp_index+pulse_size/sig_dt-1)) + temp_trace;
        
    end
    
end

%% adjust amplitude
% power calculate
% rms(asynch_stim_trace)^2

% here make it louder by adjusting the amplitudes
stim_amplitude_increase_factor = 10/(5*std(asynch_stim));
asynch_stim = asynch_stim*stim_amplitude_increase_factor;

% erase all data points outside of bounds
for ii = 1:length(asynch_stim)
    if asynch_stim(ii) > 10
        asynch_stim(ii) = 10;
    elseif asynch_stim(ii) < -10
        asynch_stim(ii) = -10;
    end
end

%% plot stuff
% figure;
% plot(time_sig, asynch_stim_trace)
% 
% figure;
% spectrogram( asynch_stim_trace,1000,100,1000, 1/sig_dt, 'yaxis');
% 
% figure;
% plot(abs(fft(asynch_stim_trace)));
% 
% figure;
% hist(asynch_stim_trace, 100);


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
for ii = 1:numel(asynch_stim_dsp)
    asynch_stim_dsp(ii) = asynch_stim(round(ii*(1e-3/sig_dt)-1e-3/sig_dt/2));
end

%% save data below
save([acquisition_file_path, '_stim_data'], 'save_note','asynch_stim','asynch_stim_dsp', 'sig_dt', 'stim_amplitude_increase_factor', '-v7.3');



%save 'Freqs', 