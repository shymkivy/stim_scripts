fileName = 'saved_sounds/fnoise.F32';
% plots the last npts data points
fs = 1.953125e5;

fid = fopen(fileName);

data = fread(fid, 'float32');
%data = freq_grating_stim;
fclose(fid);

time1 = (1:numel(data))/fs;

%% make sliding volume window
Pref = 2e-5;
S = 2.2;%*10e-3; %mV/Pa
bin = .05;
dens = 0.10;
time_steps_vol = time1(1):dens:time1(end);
vol_db = zeros(numel(time_steps_vol),1);
for n_ts = 1:numel(time_steps_vol)
    n_ms = time_steps_vol(n_ts);
    
    [~, t_min]= min(abs(n_ms-bin-time1));
    [~, t_max]= min(abs(n_ms+bin-time1));
    Vrms = rms(data(t_min:t_max));
    vol_db(n_ts) = 20*log10(Vrms/(S*Pref));
end
%%

figure;
subplot(2,1,1);
plot(time1, data)
subplot(2,1,2);
plot(time_steps_vol, vol_db)
xlabel('Time')
ylabel('Amplitude (V)')


% 
% Vrms = sqrt(mean(data.^2));
% SPL = 20*log10(Vrms/(2.2*10e-3*20*10e-6));
% fprintf('SPL is %.1f\n', SPL);
% 
% 
% figure;
% plot(data);   %plot([1:length(data)]/fs*1000,data);
% title('Speaker_rec')
% xlabel('Time, ms')
% % figure;
% % pwelch(data,2000, 50, 2000, fs, 'power');
% figure;
% pwelch(data,20000, 200, 20000, fs, 'power');
% title(sprintf('%s, SPL %.1f', fileName, SPL));
% % figure;
% % spectrogram(data, 200, 50, 200, 200000, 'yaxis');
% % 
% % [pxx,f] = pwelch(data, 2000, 50, 200, fs, 'power');
% % %[pxx,f] = pwelch(data, fs, 'power');
% % figure;
% % plot(f, 20*log10(sqrt(pxx)/(2.2*10e-3*20*10e-6)));
% % ylabel('dB');
% % 
% % figure;
% % plot(10*log10(fftshift(abs(fft(data)))));x1
% x1= round(2.715e6);
% x2= round(2.896e6);
% 
% figure;
% plot(data(1,x1:x2));
% 
% data2 = data(1,x1:x2);
% 
% Vrms = sqrt(mean(data2.^2));
% SPL = 20*log10(Vrms/(2.2*10e-3*20*10e-6));
% fprintf('SPL is %.1f\n', SPL);
