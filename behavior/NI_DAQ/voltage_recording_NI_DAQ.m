%% Run script to start voltage recording with NI-DAQ
clear;
close all;

%% Input paramterets

tic
acquisition_file_name = 'test';

recording_length = 1; % in sec

% Select NI-DAQ AI channels to record from:
% 0 - Lick
% 1 - Stim type
% 2 - LED
% 3 - Loco
% 4 - LED bh
% 5 - Reward
channels = [0 1 2 3 4 5];


%% output file name generation
pwd2 = fileparts(which('voltage_recording_NI_DAQ.m'));
save_path = [pwd2 '\..\..\..\stim_scripts_output\NI_daq_output\'];

if ~exist(save_path, 'dir')
    mkdir(save_path);
end

% add time info to saved file name
temp_time = clock;
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_h', num2str(temp_time(4)), '_m', num2str(temp_time(5))];
acquisition_file_path = [save_path, acquisition_file_name,time_stamp];
clear save_path temp_time;

%% run DAQ here
% the data is acquired in buffers of 100ms and dumped into csv files in
% temp data folder
f_acquireData(channels, recording_length, pwd2);

%% load acquired data from csvs and save as mat
disp('Saving data...');

daq_data.time = csvread([pwd2 '\temp_data\temp_time.csv']);
daq_data.voltage = zeros(length(daq_data.time), length(channels));
for nfile = 1:numel(channels)
    daq_data.voltage(:,nfile) = csvread([pwd2 '\temp_data\temp_volt_data_', num2str(nfile), '.csv']);
end
clear nfile;

% save recorded data
save([acquisition_file_path '.mat'], 'daq_data');

%%
% plot everything
figure;
hold on;
plot(daq_data.time, daq_data.voltage(:,1), 'k');
plot(daq_data.time, daq_data.voltage(:,6), 'r');
plot(daq_data.time, daq_data.voltage(:,2), 'b');
legend('lick', 'reward', 'vis stim');

%%
disp('Done');
toc

