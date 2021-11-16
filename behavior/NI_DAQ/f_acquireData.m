function f_acquireData(channels, recording_length, pwd2)

global globalTime;
global globalData;
global timeIndex;

timeIndex = 1;

%% DAQ 

disp('Initializing DAQ...');
% Creating session
s = daq('ni');

% hich channels to record from
% Channels
% 0 - Lick
% 1 - Stim type
% 2 - LED
% 3 - Loco
% 4 - LED bh
% 5 - Reward

channel_key = [0 1 2 3 4 5];
channel_names = {'Lick';
                 'Stim type';
                 'LED';
                 'Locomotion';
                 'LED bh';
                 'Reward'};
             
daq_ai_chan_map = containers.Map(channel_key,channel_names);

% initialize 
s.addinput('Dev1',channels,'Voltage');

% make the data acquisition 'SingleEnded, to separate the '
for nchan = 1:numel(channels)
    if channels(nchan) <= 3 %strcmp(s.Channels(ii).ID, 'ai3')
        s.Channels(nchan).Range = [-10 10];
        s.Channels(nchan).TerminalConfig = 'SingleEnded';
        
    end
end

s.Rate = 1000; % Cannot exceed 1666.6667 for six channels.
% if recording_length == 0
%     s.DurationInSeconds = input('duration in sec: '); % Change this to change duration of experiment.
% else
%     s.DurationInSeconds = recording_length;
% end

%% Create temporary files to write  data from DAQ as it is recording
daq_data.time = fopen([pwd2 '\temp_data\temp_time.csv'], 'w');
for ii = 1:numel(channels)
    daq_data.voltage(ii) = fopen([pwd2 '\temp_data\temp_volt_data_', num2str(ii), '.csv'], 'w');
end

%% Plotting data

globalTime = zeros(s.Rate*120,1);
globalData = zeros(s.Rate*120,size(channels,2));

% change subplot dim if using fewer channels
if length(channels) == 6
    subplot_dim = [3, 2];
elseif length(channels) < 6
    subplot_dim = [length(channels), 1];
end

% create plot for voltage data
figure;
for nchan = 1:length(channels)
    fig_plt.subplt(nchan) = subplot(subplot_dim(1), subplot_dim(2),nchan);
    fig_plt.plt(nchan) = plot(globalTime,globalData(:,nchan));
    xlim([0 120]);
    if channels(nchan) == 7
        ylim([-0.5 3]); % for locomotion
    else
        ylim([-0.5 5.5]);
    end
    title(daq_ai_chan_map(channels(nchan)))
end

%% Data acqusition

% Handle (whenever data is available, call the function inside)
%lh = s.addlistener('DataAvailable', @(src,event)f_writeData(daq_data, event, fig_plt));

s.ScansAvailableFcn = @(obj,event)f_writeData(obj,event, daq_data, fig_plt); % (daq_data, event, fig_plt)
disp('Recording voltage...');
s.start("Duration",recording_length)
pause(recording_length);
%delete(s);
disp('Finished voltage recording...');

end