%% analyze
pwd2 = fileparts(which('speaker_calibration.m')); %mfilename
save_path = [pwd2 '\..\..\stim_scripts_output\'];

data_load = load([save_path, 'speaker_cal_40dbgain_10_2_24_stim_data_13h_25m'], 'data_st'); % speaker_cal_9_12_24_stim_data_15h_5m
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
%fvtool(mbFilt)

buff = 0;
data_all2 = data_all;
freq_amp_vol = zeros(num_freqs, num_amps, params.num_rep);
for n_rep = 1:params.num_rep
    for n_freq = 1:num_freqs
        for n_amp = 1:num_amps
            %data_out = filter(mbFilt, data_all2{n_freq, n_amp, n_rep});
            data_out = data_all2{n_freq, n_amp, n_rep} - mean(data_all2{n_freq, n_amp, n_rep});
            data_all2{n_freq, n_amp, n_rep} = data_out(20000+buff:end - buff);
            Vrms = rms(data_all2{n_freq, n_amp, n_rep});
            freq_amp_vol(n_freq, n_amp, n_rep) = 20*log10(Vrms/(S*Pref))-params.gain_DB;
        end
    end
end

amp_c = jet(num_amps);
figure; hold on;
amp_leg = cell(num_amps,1);

for n_amp = 1:num_amps
    mean_tr = mean(freq_amp_vol(:,n_amp, :),3);
    plot(params.freqs_to_test, mean_tr, 'color', amp_c(n_amp,:))
    amp_leg{n_amp} = num2str(params.amps_to_test(n_amp));
end

legend(amp_leg)
title(title1);

for n_amp = 1:num_amps
    for n_freq = 1:num_freqs
        figure; plot(data_all2{n_freq, n_amp, 1})
        title(sprintf('%dkHz; %damp', params.freqs_to_test(n_freq), params.amps_to_test(n_amp)))
    end
end
% 
% %figure; imagesc(reshape(amp_c, [],1,3))
% 


n_freq = 5;
n_amp = 6;
n_rep = 1;
figure; hold on;
[pxx,f] = pwelch(data_all2{n_freq, 1, n_rep},500, 100, 500, fs);
plot(f, 10*log10(pxx))
[pxx,f] = pwelch(data_all2{n_freq, n_amp, n_rep},500, 100, 500, fs);
plot(f, 10*log10(pxx))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')

figure; 
plot(data_all2{n_freq, n_amp, n_rep})
title(sprintf('%dkHz; %damp', params.freqs_to_test(n_freq), params.amps_to_test(n_amp)))


n_amp = 5;
f_col = jet(num_freqs);
f1 = figure; hold on;
[pxx,f] = pwelch(data_all2{n_freq, 1, 1},500, 100, 500, fs);
plot(f/1000, 10*log10(pxx), color='k')
for n_freq = 1:num_freqs
    [pxx,f] = pwelch(data_all2{n_freq, n_amp, 2},500, 100, 500, fs);
    plot(f/1000, 10*log10(pxx), color=f_col(n_freq,:))
end
xlabel('Frequency (kHz)')
ylabel('Magnitude (dB)')
legend(freq_leg)
%f1.CurrentAxes.XScale = 'log';


n_freq = 10;
n_rep = 2;
a_col = jet(num_amps);
f1 = figure; hold on;
for n_amp = 1:num_amps
    [pxx,f] = pwelch(data_all2{n_freq, n_amp, n_rep},500, 100, 500, fs);
    plot(f/1000, 10*log10(pxx), color=a_col(n_amp,:))
end
xlabel('Frequency (kHz)')
ylabel('Magnitude (dB)')
legend(amp_leg)

% pwelch(data_all2{n_freq, 2},500, 100, 500, fs);
% pwelch(data_all2{n_freq, 3},500, 100, 500, fs);