% communicates with the "minimal.ino" arduino script
% day 1, 2 lick reward
%       require_second_lick = 0;
% day 3 ready lick reward 
%       pretrial delay = 1;
%       posttrial delay = 5;
% day 4 rlr
%       pretrial delay = 2;
%       pretrial rand delay = 4;
%       posttrial delay = 5
clear;

%% params
fname = 'nm_ready_lick_reward_day4';

ops.paradigm_duration = 3600;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

ops.pre_trial_delay = 2;  % sec
ops.pre_trial_delay_rand = 4;
ops.reward_window = 2;
ops.failure_timeout = 0;
ops.post_trial_delay = 5;  % sec
ops.require_second_lick = 1;
ops.reward_period_flash = 1;

ops.water_dispense_duration = 0.025; % or .2 for more trials  
% .025 ~ 137 trials and .5g weight gain

ops.lick_thresh = 4;
%%
pwd2 = fileparts(which('ready_lick_reward.m'));
save_path = [pwd2 '\..\..\stim_scripts_output\behavior\'];

%% Initialize arduino
%arduino_port=serialport('COM19',9600);

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogInputChannel('Dev1','ai0','Voltage');
session.Channels(1).Range = [-10 10];
session.Channels(1).TerminalConfig = 'SingleEnded';
session.addAnalogOutputChannel('Dev1','ao0','Voltage'); % stim type
session.addAnalogOutputChannel('Dev1','ao1','Voltage'); % synch pulse LED
session.addDigitalChannel('dev1','Port0/Line0:1','OutputOnly');
session.outputSingleScan([0,0,0,0]);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

%% run paradigm

pause(5);
session.outputSingleScan([0,3,0,0]);
start_paradigm = now*86400;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

time_trial_start = zeros(ops.trial_cap, 1);
time_reward_period_start = zeros(ops.trial_cap, 1);
time_correct_lick = zeros(ops.trial_cap, 1);
n_trial = 0;
n_reward = 0;
while and((now*86400 - start_paradigm)<ops.paradigm_duration, n_reward<=ops.trial_cap)
    
    % trial available, wait for lick to start
    lick = 0;
    session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8');
    while and(~lick, (now*86400 - start_paradigm)<ops.paradigm_duration)
        data_in = inputSingleScan(session);
        if data_in > ops.lick_thresh
            lick = 1;
        end
    end
    session.outputSingleScan([0,0,0,0]); %write(arduino_port, 2, 'uint8'); % turn off LED
    
    if lick
        n_trial = n_trial + 1;
        if ops.require_second_lick
            lick = 0;
        end
        start_trial = now*86400; 
        time_trial_start(n_trial) = start_trial - start_paradigm;
        
        trial_delay = ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1);
        pause(trial_delay);
        
        if ops.reward_period_flash
            session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8'); % turn on LED
            pause(.005);
            session.outputSingleScan([0,0,0,0]); %write(arduino_port, 2, 'uint8'); % turn off LED
        end
        reward_period_start = now*86400;
        time_reward_period_start(n_trial) = reward_period_start - start_paradigm;
        while and(~lick, (now*86400 - reward_period_start)<(ops.reward_window))
            data_in = inputSingleScan(session);
            if data_in > ops.lick_thresh
                lick = 1;
                time_correct_lick(n_trial) = now*86400 - start_paradigm;
            end
        end
        
        if lick
            n_reward = n_reward + 1;
            session.outputSingleScan([0,0,0,1]); % write(arduino_port, 3, 'uint8');
            pause(ops.water_dispense_duration);
            session.outputSingleScan([0,0,0,0]);
        else
            pause(ops.failure_timeout);
        end
        fprintf('n_trial = %d, n_reward = %d\n', n_trial, n_reward);
    end
    pause(ops.post_trial_delay);
end
session.outputSingleScan([0,0,0,0]);

pause(5);
session.outputSingleScan([0,3,0,0]);
time_paradigm_end = now*86400 - start_paradigm;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

%% save data
%reward_times(reward_times == 0) = [];
trial_data.time_trial_start = time_trial_start;
trial_data.time_reward_period_start = time_reward_period_start;
trial_data.time_correct_lick = time_correct_lick;
trial_data.time_paradigm_end = time_paradigm_end;
trial_data.num_trials = n_trial;
trial_data.num_rewards = n_reward;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name], 'trial_data', 'ops');
