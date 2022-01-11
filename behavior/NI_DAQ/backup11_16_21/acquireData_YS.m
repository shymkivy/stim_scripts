function acquireData_YS(channels, recording_length, pwd2)


global globalTime;
global globalData;
global timeIndex;

timeIndex = 1;

%% DAQ 

disp('Initializing DAQ...');
% Creating session
s = daq.createSession('ni');

% % which channels to record from
% channels = [4 7 1 3];

% Channels
% 0 - punishment
% 1 - lick right 1
% 2 - lick left 2
% 3 - reward
% 4 - vis stim
% 7 - locomotion

channel_key = [0 1 2 3 4 7];
channel_names = {'Punishment';
                 'Lick left (1)';
                 'Lick right (2)';
                 'Reward';
                 'Vistual stim';
                 'Locomotion'};
daq_ai_chan_map = containers.Map(channel_key,channel_names);

% initialize 
s.addAnalogInputChannel('Dev1',channels,'voltage');

% make the data acquisition 'SingleEnded, to separate the '
for nchan = 1:length(channels)
    if channels(nchan) <= 3 %strcmp(s.Channels(ii).ID, 'ai3')
        s.Channels(nchan).Range = [-10 10];
        s.Channels(nchan).TerminalConfig = 'SingleEnded';
        
    end
end

s.Rate = 1000; % Cannot exceed 1666.6667 for six channels.
if recording_length == 0
    s.DurationInSeconds = input('duration in sec: '); % Change this to change duration of experiment.
else
    s.DurationInSeconds = recording_length;
end

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
lh = s.addlistener('DataAvailable', @(src,event)writeData_YS(daq_data, event, fig_plt));

disp('Recording voltage...');
s.startBackground();
s.wait();
delete(lh);
disp('Finished voltage recording...');

end