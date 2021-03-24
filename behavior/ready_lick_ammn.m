% communicates with the "minimal" arduino script
clear;

%% params

fname = 'nm_day44_RL_ammn_1';

ops.paradigm_duration = 3600;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

ops.initial_stop_lick_period = 1.5;
ops.pre_trial_delay = 0;  % sec
ops.pre_trial_delay_rand = 0;
ops.reward_window = 2;
ops.failure_timeout = 5;
ops.post_trial_delay = 2;  % sec was 2
ops.require_second_lick = 1;
ops.reward_period_flash = 0;

ops.water_dispense_duration_large = 0.04;
ops.water_dispense_duration_small = 0.025;

ops.reward_lick_rate_thersh_large = 1.2;          % licks per sec below thresh give reward
ops.reward_lick_rate_thersh_small = 1.6;        % licks per sec below thresh give reward1

ops.lick_thresh = 4;

ops.stim_selection_type = 'sequences'; % 'randsamp', 'sequences', 'rand_sequences' 
ops.MMN_pat = [3, 6];
ops.num_seq = 50;

% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
ops.rand_time_pad = .05;

% MMN trial params
ops.stim_range = [3 4 5 6 7];
ops.red_pre_trial = 3;
ops.red_post_trial = 3;
ops.red_lim = 7; % min lim is 5; adjust for pretrial red padding
ops.MMN_probab=[0.1*ones(1,max(ops.red_lim-4,1)) .2 .25 .5 1]; 
% MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab

% ------ Other ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization
ops.lick_thresh = 4;

% ----- auditory stim params ------------
ops.start_freq = 2000;
% ops.end_freq = 90000;

ops.num_freqs = 10;
ops.increase_factor = 1.5;
ops.MMN_patterns = [3,6; 4,7; 3,8];
ops.base_freq = 0.001; % baseline frequency
ops.modulation_amp = 3;
%%
pwd2 = fileparts(which('ready_lick_ammn.m'));

addpath([pwd2 '\..\auditory_stim\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\behavior\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';
%% Initialize arduino
%arduino_port=serialport('COM19',9600);

%% initialize RZ6
RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
RP.Halt;

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogInputChannel('Dev1','ai0','Voltage');
session.Channels(1).Range = [-10 10];
session.Channels(1).TerminalConfig = 'SingleEnded';
session.addAnalogOutputChannel('Dev1','ao0','Voltage'); % stim type
session.addAnalogOutputChannel('Dev1','ao1','Voltage'); % synch pulse LED
session.addDigitalChannel('dev1','Port0/Line0:1','OutputOnly');
session.outputSingleScan([0,0,0,0]);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

% start with some water
session.outputSingleScan([0,0,0,1]); % write(arduino_port, 3, 'uint8');
pause(ops.water_dispense_duration_large);
session.outputSingleScan([0,0,0,0]);

%% run paradigm
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);

pause(5);
session.outputSingleScan([0,3,0,0]);
start_paradigm = now*86400;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

%% Run script
trial_data = f_ready_lick_ammn_core(ops, session, RP, start_paradigm);

%%
session.outputSingleScan([0,0,0,0]);
RP.Halt;
%write(arduino_port, 2, 'uint8'); % turn off LED

pause(5);
session.outputSingleScan([0,3,0,0]);
time_paradigm_end = now*86400 - start_paradigm;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

%% save data
trial_data.time_paradigm_end = time_paradigm_end;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name],  'trial_data', 'ops');

%% plot 
num_red = dev_idx(reward_type>0)-1;
num_red_u = unique(num_red);
reward_onset_lick_rate2 = reward_onset_lick_rate(reward_type>0);
var_thresh_50 = zeros(numel(num_red_u),1);
var_thresh_15 = zeros(numel(num_red_u),1);
for ii = 1:numel(num_red_u)
    temp_data = reward_onset_lick_rate2(num_red == num_red_u(ii));
    var_thresh_50(ii) = prctile(temp_data, 50);
    var_thresh_15(ii) = prctile(temp_data, 15);
end
full_thresh_50 = prctile(reward_onset_lick_rate2, 50);
full_thresh_15 = prctile(reward_onset_lick_rate2, 15);
figure; hold on;
plot(num_red, reward_onset_lick_rate2, 'o');
plot(num_red_u, var_thresh_50);
plot(num_red_u, var_thresh_15);
plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_50);
plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_15);
legend('lick rate', 'var thresh 50%', 'var thresh 15%', 'full thresh 50', 'full thresh 15');
title('lick rate vs num redundants');

fprintf('Analysis: 50%% thresh = %.2f; 15%% thesh = %.2f\n', full_thresh_50, full_thresh_15);

