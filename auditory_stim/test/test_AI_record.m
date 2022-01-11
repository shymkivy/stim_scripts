clear;
close all;
rec_bgk = 1;    % record in foreground or background
global indx data_c timestamps_c;

s = daq.createSession('ni');
s.Rate = 200000;
s.DurationInSeconds = 30;
addAnalogInputChannel(s,'Dev2','ai3','Voltage');

disp('Starting rec...')
if ~rec_bgk
	[data, timestamps, ~] = startForeground(s);
else
    num_bins = ceil(s.Rate*s.DurationInSeconds/ceil(s.Rate/10));
    
    indx = 1;
    data_c = cell(num_bins,1);
    timestamps_c = cell(num_bins,1);

    lh = addlistener(s,'DataAvailable',@plotData);
    startBackground(s);
    
    %test_mic2
    
    pause(s.DurationInSeconds)
    delete(lh)
    % when finished recording
    data= cat(1, data_c{:});
    timestamps = cat(1, timestamps_c{:});
end
disp('Done')


%%


% plot stuff
DAQ_3 = timetable(seconds(timestamps),data(:,1));
figure;
plot(DAQ_3.Time, DAQ_3.Variables)
xlabel('Time')
ylabel('Amplitude (V)')
legend(DAQ_3.Properties.VariableNames)


figure;
pwelch(DAQ_3.Variables,[],[],[],200000)

%% mic params
% SPL = (20Log10(Vrms/S * Pref))
% Pref = 20*10^-6; 2e-5



Vrms = rms(DAQ_3.Variables);

Pref = 2e-5;
S = 2.2*10e-3; %mV/Pa

mic_SPL = 20*log10(Vrms/(S*Pref));

%% make sliding volume window
bin = .5;
dens = 0.10;
time_steps_vol = timestamps(1):dens:timestamps(end);
vol_db = zeros(numel(time_steps_vol),1);
for n_ts = 1:numel(time_steps_vol)
    n_ms = time_steps_vol(n_ts);
    
    [~, t_min]= min(abs(n_ms-bin-timestamps));
    [~, t_max]= min(abs(n_ms+bin-timestamps));
    Vrms = rms(data(t_min:t_max,1));
    vol_db(n_ts) = 20*log10(Vrms/(S*Pref));
end
%%
DAQ_3 = timetable(seconds(timestamps),data(:,1));
figure;
subplot(2,1,1);
plot(timestamps, data(:,1))
subplot(2,1,2);
plot(time_steps_vol, vol_db)
xlabel('Time')
ylabel('Amplitude (V)')
%legend(DAQ_3.Properties.VariableNames)



function plotData(src,event)
    global indx data_c timestamps_c;
    data_c{indx} = event.Data;
    timestamps_c{indx} = event.TimeStamps;
    indx = indx+1;    
    %plot(event.TimeStamps,event.Data)
end