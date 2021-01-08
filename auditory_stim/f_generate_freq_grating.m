function grating_stim = f_generate_freq_grating(ops)

stim_duration = ops.stim_time;
sig_dt = ops.sig_dt;
start_freq = ops.start_freq;
end_freq = ops.end_freq;
resoluction_per_octave = ops.resoluction_per_octave;
grating_angles = ops.grating_angles;

%start_freq = 2000;
%end_freq = 90000;
%resoluction_per_octave = 1/24/8;
%grating_angles = [3, 2, 1, 0, -1, -2]*pi/6;
%grating_angles = [5, 4, 3, 2, 1, 0, -1, -2, -3, -4]*pi/10;


%%
% what type of stimulus envelope sinusoid vs pulse
pulse_envelope = 0; % make 1 to convertso 
threshold = 0.9;

on_off_ramp_length = 0.005;


%% select frequencies

freq_steps = 1 + resoluction_per_octave;
num_freqs = ceil(log(end_freq/start_freq)/log(freq_steps));

freqs = zeros(num_freqs,1);
for ii = 1:num_freqs
    freqs(ii) = start_freq * freq_steps^(ii-1);
end
freqs = flipud(freqs);


%% genetate matrix of sine waves
time_stim = sig_dt:sig_dt:stim_duration;

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


end