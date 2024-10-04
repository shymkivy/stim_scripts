clear;
close all;

%% analyze
pwd2 = fileparts(which('speaker_calibration_analyze.m')); %mfilename
save_path = [pwd2 '\..\..\stim_scripts_output\'];

fname = 'speaker_cal_40dbgain_10_3_24_stim_data_14h_58m';
%fname = 'speaker_cal_40dbgain_nocov_10_3_24_stim_data_14h_16m';

data_load = load([save_path, fname], 'data_st'); % speaker_cal_9_12_24_stim_data_15h_5m
data_st = data_load.data_st;
data_all = data_st.data_all;
params = data_st.params;
fs = params.fs;

target_db = 70;

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

amp_leg = cell(num_amps,1);
for n_amp = 1:num_amps
    amp_leg{n_amp} = sprintf('%.1fV', params.amps_to_test(n_amp));
end
freq_leg = cell(num_freqs,1);
for n_freq = 1:num_freqs
    freq_leg{n_freq} = sprintf('%.1fkHz', params.freqs_to_test(n_freq));
end
amp_col = jet(num_amps);
freq_col = jet(num_freqs);

mbFilt = designfilt('highpassiir','FilterOrder',5, ...
         'PassbandFrequency', 100,'PassbandRipple',0.2, ...
         'SampleRate',fs);
%fvtool(mbFilt)

buff = 0;
num_skip = 0; %2e5;
data_allf = data_all;
freq_amp_vol = zeros(num_freqs, num_amps, params.num_rep);
for n_rep = 1:params.num_rep
    for n_freq = 1:num_freqs
        for n_amp = 1:num_amps
            data_out = filter(mbFilt, data_all{n_freq, n_amp, n_rep});
            %data_out = data_all2{n_freq, n_amp, n_rep} - mean(data_all2{n_freq, n_amp, n_rep});
            data_allf{n_freq, n_amp, n_rep} = data_out;
            Vrms = rms(data_out(1+num_skip+buff:end - buff));
            freq_amp_vol(n_freq, n_amp, n_rep) = 20*log10(Vrms/(S*Pref))-params.gain_DB;
        end
    end
end

%%
figure; hold on;
pl_all = cell(num_amps,1);
for n_amp = 1:num_amps
    mean_tr = mean(freq_amp_vol(:,n_amp, :),3);
    sem = std(freq_amp_vol(:,n_amp, :), [],3)/sqrt(params.num_rep-1);
    pl_all{n_amp} = plot(params.freqs_to_test, mean_tr, 'color', amp_col(n_amp,:));
    errorbar(params.freqs_to_test, mean_tr, sem, color=amp_col(n_amp,:));
end
legend([pl_all{:}], amp_leg)
title(title1);

% for n_amp = 1:num_amps
%     for n_freq = 1:num_freqs
%         figure; plot(data_all2{n_freq, n_amp, 1})
%         title(sprintf('%dkHz; %damp', params.freqs_to_test(n_freq), params.amps_to_test(n_amp)))
%     end
% end
% 
% %figure; imagesc(reshape(amp_c, [],1,3))
% 

n_freq = 2;
n_amp = 10;
n_rep = 2;
figure; hold on;
[pxx,f] = pwelch(data_allf{n_freq, 1, n_rep},500, 100, 500, fs);
plot(f, 10*log10(pxx))
[pxx,f] = pwelch(data_allf{n_freq, n_amp, n_rep},500, 100, 500, fs);
plot(f, 10*log10(pxx))
xlabel('Frequency (Hz)')
ylabel('Power/frequency (dB/Hz)')

figure; 
plot(data_allf{n_freq, n_amp, n_rep})
title(sprintf('%dkHz; %damp', params.freqs_to_test(n_freq), params.amps_to_test(n_amp)))


n_rep = 2;
n_amp = 10;
f1 = figure; hold on;
for n_freq = 1:num_freqs
    [pxx,f] = pwelch(data_allf{n_freq, n_amp, n_rep},500, 100, 500, fs);
    plot(f/1000, 10*log10(pxx), color=freq_col(n_freq,:))
end
xlabel('Frequency (kHz)')
ylabel('Power/frequency (dB/Hz)')
legend(freq_leg)
%f1.CurrentAxes.XScale = 'log';
title(sprintf('var freq; amp=%.1fV; rep=%d', params.amps_to_test(n_amp), n_rep))


n_freq = 1;
n_rep = 2;
f1 = figure; hold on;
for n_amp = 1:num_amps
    [pxx,f] = pwelch(data_allf{n_freq, n_amp, n_rep},500, 100, 500, fs);
    plot(f/1000, 10*log10(pxx), color=amp_col(n_amp,:))
end
xlabel('Frequency (kHz)')
ylabel('Power/frequency (dB/Hz)')
legend(amp_leg)
title(sprintf('var amp; freq=%.1fkHz; rep=%d', params.freqs_to_test(n_freq), n_rep))

% pwelch(data_all2{n_freq, 2},500, 100, 500, fs);
% pwelch(data_all2{n_freq, 3},500, 100, 500, fs);

%%
% fitting all individually
% x_data = params.amps_to_test;
% x_fit = x_data(1):0.01:x_data(end);
% 
% for n_freq = 1:num_freqs
%     y_data = squeeze(freq_amp_vol(n_freq,:,:));
%     fitm = fit(repmat(x_data', params.num_rep, 1), reshape(y_data, [], 1), 'smoothingspline', 'SmoothingParam', 0.3);
%     y_fit = fitm(x_fit);
%     figure; hold on;
%     plot(x_data, y_data, 'o-')
%     plot(x_data, mean(y_data,2), color='k', linewidth=1)
%     plot(x_fit, y_fit, color='r', linewidth=1)
% end


% cubic interpolation of everything together
freq_amp_vol_sm = mean(freq_amp_vol,3);
[freq_X, amp_Y] = meshgrid(params.freqs_to_test, params.amps_to_test);

fit_frq_amp = fit([reshape(freq_X,[],1), reshape(amp_Y,[],1)], reshape(freq_amp_vol_sm',[],1), 'cubicinterp');


calib = struct;
calib.fit_frq_amp = fit_frq_amp;
calib.params = calib;
calib.freq_amp_vol = freq_amp_vol;

save([save_path, 'calib_', fname], 'calib');

% amps_fit = (0:0.1:10)';
% freq_fit = ones(numel(amps_fit),1)*50;
% y_data = fitm([freq_fit, amps_fit]);
% 
% figure; hold on;
% plot(params.amps_to_test, freq_amp_vol_sm(params.freqs_to_test==60,:))
% plot(amps_fit, y_data)


% mbFilt = designfilt('highpassiir','FilterOrder',5, ...
%          'PassbandFrequency', 500,'PassbandRipple',0.01, ...
%          'SampleRate',fs);
% %fvtool(mbFilt)
% 
% data_out = filter(mbFilt, data_all2{n_freq, n_amp, n_rep});
% 
% figure()
% plot(data_out)
% 
% figure()
% plot(data_all2{n_freq, n_amp, n_rep})

% 885, 3220 , 5503



