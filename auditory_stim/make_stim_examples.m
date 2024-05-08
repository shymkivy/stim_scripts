ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;


ops.num_freqs = 10;
ops.freq_scale = 'log'; % 'log' or 'linear'
ops.increase_factor = 1.5;


ops.start_freq = 2000;
ops.end_freq = 90000;
ops.resoluction_per_octave = 1/24/8;
ops.grating_angles = [5, 4, 3, 2, 1, 0, -1, -2, -3, -4]*pi/10;
ops.stim_amplitude = 1; % 8 is good, seems similar to 4 with sam tones

%%
control_carrier_freq = zeros(1, ops.num_freqs);
control_carrier_freq(1) = ops.start_freq;
for ii = 2:ops.num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * ops.increase_factor;
end

%%
Fs = 32768; %HZ
tone_x = 1/Fs:1/Fs:ops.stim_time;
all_tones = zeros(ops.num_freqs, numel(tone_x));
am1 = (sin(tone_x*40*2*pi)+1)/2;
for n_fr = 1:ops.num_freqs
    all_tones(n_fr,:) = sin(tone_x*control_carrier_freq(n_fr)*2*pi).*am1;
end
ops.Fs = Fs;

stim_data.all_tones = all_tones;

isi = zeros(1, numel(tone_x));

figure; plot(tone_x,  all_tones(1,:))

%%
sam_pat1 = [1 1 1 1 1 3];

sound_all_sam = cell(numel(sam_pat1),1);
for n_pt = 1:numel(sam_pat1)

    sound_all_sam{n_pt} = [stim_data.all_tones(sam_pat1(n_pt),:), isi];
end

sound_all_sam2 = cat(2, sound_all_sam{:});

%%


ops.sig_dt = 1/ops.Fs;
disp('Generating gratings...');
grating_stim = f_generate_freq_grating(ops);

% adjust amplitude
grating_stim_norm = zeros(size(grating_stim));
for ii = 1:size(grating_stim,1)
%     grating_stim_norm(ii,:) = grating_stim(ii,:)./max(abs(grating_stim(ii,:)))*stim_amplitude;
    %grating_stim_norm(ii,:) = grating_stim(ii,:)*10/(5*std(grating_stim(ii,:)));
    grating_stim_norm(ii,:) = grating_stim(ii,:)*ops.stim_amplitude/(5*std(grating_stim(ii,:)));
end

%%
fg_pat1 = [3 3 3 3 3 8];

sound_all_fg = cell(numel(fg_pat1),1);
for n_pt = 1:numel(fg_pat1)

    sound_all_fg{n_pt} = [grating_stim_norm(fg_pat1(n_pt),:), isi];
end

sound_all_fg2 = cat(2, sound_all_fg{:});

%%
sound(sound_all_sam2, ops.Fs);

sound(sound_all_fg2, ops.Fs);

%%
audiowrite('sam_oddball.wav', sound_all_sam2,ops.Fs)


audiowrite('fg_oddball.wav', sound_all_fg2,ops.Fs)

