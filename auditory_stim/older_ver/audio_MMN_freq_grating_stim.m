%% old version 9/21/19

clear;
close all;

%% some parameters 

% % to only play, "play_and_record = 0"
% % play and record, "play_and_record = 1"
play_and_record = 0;

trials = 400;                   % 
stim_duration =0.5;            % sec
isi = 0.5;                      % sec
stim_amplitude = 6;            % Volt
pause_between_runs = 30;        % sec
MMN_pattern = 2;
synch_pause_time = [10,1,10];
widefield_LED = 0;
resoluction_per_octave = 1/24;

fprintf('Approximate run time: %d sec\n',round(2*trials*(stim_duration + isi + .1) + 2*pause_between_runs + 10));

% what type of stimulus envelope sinusoid vs pulse
pulse_envelope = 0; % make 1 to convertso 
threshold = 0.9;

on_off_ramp_length = 0.005;

%grating_angles = [3, 2, 1, 0, -1, -2]*pi/6;
grating_angles = [5, 4, 3, 2, 1, 0, -1, -2, -3, -4]*pi/10;

MMN_pattern_pairs = [1,6; 2,7; 3,8];
initial_stim_adaptation = 30;
deviance_prob = [.01 .01 .01 .01 .01 .01 .1 .1 .3 .5 1];

%% save output path
save_path = 'C:\Users\YusteLab\Desktop\Yuriy\A1_freq_stim_output\';
acquisition_file_name = 'freq_grating_6V';

% file name generation
% add time info to saved file name
temp_time = clock;
save_note = '';
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];

acquisition_file_path = [save_path, acquisition_file_name,time_stamp];
clear time_stamp;

%% 
sig_dt = 1/195312.5; % 100kHz sampling signal

time_stim = sig_dt:sig_dt:stim_duration;

%% select frequencies
disp('Generating gratings...');
start_freq = 2000;
end_freq = 90000;
freq_steps = 1 + resoluction_per_octave;
num_freqs = ceil(log(end_freq/start_freq)/log(freq_steps));

freqs = zeros(num_freqs,1);
for ii = 1:num_freqs
    freqs(ii) = start_freq * freq_steps^(ii-1);
end
freqs = flipud(freqs);


%% genetate matrix of sine waves

freq_basis = zeros(num_freqs, numel(time_stim));
for ii = 1:num_freqs
    freq_basis(ii,:) = sin(2*pi*(freqs(ii).*time_stim + rand(1)));
end


%% Create grating envelope

comp_t = cos(grating_angles);
comp_freq = sin(grating_angles);

freq_spec = (1:num_freqs)/num_freqs;

[t_coord, freq_coord] = meshgrid(time_stim,freq_spec);

grating_envelope = zeros(numel(grating_angles), num_freqs, numel(time_stim));

for ii = 1:length(grating_angles)
    grating_envelope(ii,:,:) = (sin((10*comp_t(ii)*t_coord-5*comp_freq(ii)*freq_coord)*2*pi)+1)/2;
    if pulse_envelope == 1
        grating_envelope(grating_envelope>threshold) = 1;
        grating_envelope(grating_envelope<=threshold) = 0;
    end
end


%% create stim

grating_stim = zeros(length(grating_angles) , numel(time_stim));
% now create actual stimuli
for ii = 1:length(grating_angles) 
    grating_stim(ii,:) = sum(squeeze(grating_envelope(ii,:,:)) .* freq_basis,1);
end



%% make onset offset ramps

% make onset offset ramps
time_ramp = sig_dt:sig_dt:on_off_ramp_length;

ramp_onset = (1-(cos(((time_ramp)*2*pi)*(0.5/on_off_ramp_length))))/2;
ramp_offset = (1+(cos(((time_ramp)*2*pi)*(0.5/on_off_ramp_length))))/2;
% add to stimuli
for ii = 1:length(grating_angles)
    grating_stim(ii,1:numel(time_ramp)) = grating_stim(ii,1:numel(time_ramp)) .* ramp_onset;
    grating_stim(ii,(numel(grating_stim(ii,:))-numel(time_ramp)+1):end) = grating_stim(ii,(numel(grating_stim(ii,:))-numel(time_ramp)+1):end) .* ramp_offset;
end


%% adjust amplitude

grating_stim_norm = zeros(size(grating_stim));
for ii = 1:size(grating_stim,1)
%     grating_stim_norm(ii,:) = grating_stim(ii,:)./max(abs(grating_stim(ii,:)))*stim_amplitude;
    %grating_stim_norm(ii,:) = grating_stim(ii,:)*10/(5*std(grating_stim(ii,:)));
    grating_stim_norm(ii,:) = grating_stim(ii,:)*stim_amplitude/(5*std(grating_stim(ii,:)));
end

figure; plot(grating_stim(2,:));
figure; pwelch(grating_stim(2,:),[],[],[],1/sig_dt);

%% add isi
grating_stim_isi = zeros(size(grating_stim,1), round(size(grating_stim,2) + isi/sig_dt));
for ii = 1:size(grating_stim,1)
    grating_stim_isi(ii,1:size(grating_stim,2)) = grating_stim_norm(ii,:);
end


%% make train, control first
disp('Generating stimulus sequence...');

% generate trial indexes and randomize the order
cont_trials_seq = ceil(numel(grating_angles)*rand(trials,1));

%% Make MMN and flip trains

MMN_trials_seq = zeros(trials/2,2);

% 1 is redundant, 2 is deviant
for flip = 1:2
    redundant_count = 0;
    for tr = 1:trials/2
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
        MMN_trials_seq(tr, flip) = freq_type;  
    end
end
clear redundant_count freq_type;

%% generate the actual stimulus trace
disp('Generating stimulus waveform...');


freq_grating_stim = zeros(1,round((2*trials*(stim_duration + isi + 0.1)+2*pause_between_runs)/sig_dt));
stim_index = zeros(2*trials,1);

% fits control stim
current_stim_index = int32(1);
for tr = 1:trials
    temp_trial = cont_trials_seq(tr);
    % add random interval 0-100ms after isi
    temp_stim = [grating_stim_isi(temp_trial,:), zeros(1,round(0.1*rand(1)/sig_dt))];
    
    freq_grating_stim(current_stim_index:round(current_stim_index+length(temp_stim)-1)) = temp_stim;
    stim_index(tr) = current_stim_index;
    
    current_stim_index = length(temp_stim)+current_stim_index;
end

% now MMN
MMN_orientations = MMN_pattern_pairs(MMN_pattern,:);
for flip = 1:2
    current_stim_index = current_stim_index + pause_between_runs/sig_dt;
    if flip == 1
        temp_pattern = MMN_orientations;
    elseif flip ==2
        temp_pattern = fliplr(MMN_orientations);
    end
    for tr = 1:trials/2
        % pull out grating and add random interval 0-100ms after isi
        temp_stim = [grating_stim_isi(temp_pattern(MMN_trials_seq(tr,flip)),:), zeros(1,round(0.1*rand(1)/sig_dt))];

        % fill in the stims
        freq_grating_stim(current_stim_index:round(current_stim_index+length(temp_stim)-1)) = temp_stim;
        stim_index(tr + (flip-1)*trials/2 + trials) = current_stim_index;

        % update current index
        current_stim_index = length(temp_stim)+current_stim_index;
    end
end
clear temp_trial temp_stim temp_pattern tr;

freq_grating_stim(current_stim_index+1:end) = [];
clear current_stim_index;


%% Play
disp('Playing...');

if play_and_record == 1
    amp_fs = Continuous_Play_and_Acquire_YS(freq_grating_stim, acquisition_file_path);
else
    amp_fs = Continuous_Play_YS(freq_grating_stim, synch_pause_time, widefield_LED);
end

if amp_fs ~= 1/sig_dt
    warning('Sampling of script and circuit doesnt match');
end
    
%% downsample
freq_grating_stim_dsp = zeros(floor(length(freq_grating_stim)/(1e-3/sig_dt)),1);
for ii = 1:numel(freq_grating_stim_dsp)
    freq_grating_stim_dsp(ii) = freq_grating_stim(round(ii*(1e-3/sig_dt)-1e-3/sig_dt/2));
end

%% Save info
disp('Saving output...');
save([acquisition_file_path, '_stim_data'], 'save_note','freq_grating_stim','freq_grating_stim_dsp', 'stim_index', 'cont_trials_seq', 'MMN_trials_seq', 'grating_angles', 'MMN_orientations', 'sig_dt', 'stim_amplitude', 'synch_pause_time', 'widefield_LED');

disp('Done');
%% some plots

% plot grating envelope
figure;
for ii = 1:length(grating_angles)
    subplot(2,5,ii);
    imagesc(time_stim, freqs/1000, squeeze(grating_envelope(ii,:,:))); % 
    set(gca,'YDir','normal')
    ylabel('kHz');
    xlabel('sec');
    title(sprintf('%i: %i deg', ii, round(180*grating_angles(ii)/pi)));
end


%% plotting new
figure; plot(grating_stim(1,:))
figure; pwelch(grating_stim(1,:),[],[],[],1/sig_dt)

figure;
specgram(grating_stim(1,:))

figure;
%spectrogram(grating_stim(5,:))
spectrogram((grating_stim(1,:)),128,120,128,1e3, 'yaxis')
ax = gca;
ax.YScale = 'log';


%% old 
% figure;
% for ii = 1:size(grating_stim,1)
%     subplot(2,5,ii);
%     spectrogram(grating_stim(ii,:), 1000, 100, 1000, 1/sig_dt, 'yaxis');
%     ax = gca;
%     ax.YScale = 'log';
%     ylim([2, 90]);
%     ax.YTick = [2.5, 5, 10, 20, 40, 80];
% end
% 
% 
% figure;
% for ii = 1:size(grating_stim,1)
%     subplot(2,5,ii);
%     [S, F, T] = spectrogram(grating_stim_norm(ii,:), 1000, 100, 1000, 1/sig_dt, 'yaxis');
%     sh = surf(T,F,10*log10(abs(S)));
%     view(0, 90);
%     axis tight;
%     set(gca, 'YScale', 'log');
%     set(sh, 'LineStyle','none');
%     ylim([2e3, 9e4]);
%     xlim([0 1]);
% end
% clear S F T;
% 
% 
% figure;
% plot(freq_grating_stim_dsp);


% %% saave output as wave
% downsample(grating_stim_norm(1,:),4);
% 
% for ii = 1:size(grating_stim,1)
% 
%     audiowrite(sprintf('test_stim%i.wav', ii),grating_stim_norm(ii,:),48000);
% 
% end

