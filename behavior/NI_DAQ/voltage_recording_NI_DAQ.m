%% Run script to start voltage recording with NI-DAQ
clear;
close all;
tic

%% Input paramterets

acquisition_file_name = 'SZR_M4_23_19_d9';

recording_length = 3000; % in sec

% Select NI-DAQ AI channels to record from:
% 0 - punishment
% 1 - lick left 1
% 2 - lick right 2
% 3 - reward
% 4 - vis stim
% 7 - locomotion
channels = [4 7 1 3];


%% output file name generation

save_path = '.\output_data\';
% add time info to saved file name
temp_time = clock;
save_note = '';
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];
acquisition_file_path = [save_path, acquisition_file_name,time_stamp];
clear save_path temp_time;

%% run DAQ here
% the data is acquired in buffers of 100ms and dumped into csv files in
% temp data folder
acquireData_YS(channels, recording_length);

%% load acquired data from csvs and save as mat
disp('Saving data...');

daq_data.time = csvread('C:\Users\rylab_901c\Desktop\Yuriy_scripts\behavior\NI_DAQ\temp_data\temp_time.csv');
daq_data.voltage = zeros(length(daq_data.time), length(channels));
for nfile = 1:numel(channels)
    daq_data.voltage(:,nfile) = csvread(['C:\Users\rylab_901c\Desktop\Yuriy_scripts\behavior\NI_DAQ\temp_data\temp_volt_data_', num2str(nfile), '.csv']);
end
clear nfile;

% save recorded data
save([acquisition_file_path '.mat'], 'daq_data');

%%
% plot everything
figure;
hold on;
plot(daq_data.time, daq_data.voltage(:,3), 'k');
plot(daq_data.time, daq_data.voltage(:,4), 'r');
plot(daq_data.time, daq_data.voltage(:,1), 'b');
legend('lick', 'reward', 'vis stim');

%%
disp('Done');
toc

