% communicates with the "minimal.ino" arduino script
clear;

%% params
fname = 'nm_ready_lick_reward_day3';

ops.paradigm_duration = 1800;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

ops.pre_trial_delay = 1;  % sec
ops.reward_window = 2;
ops.failure_timeout = 0;
ops.post_trial_delay = 5;  % sec
ops.require_second_lick = 1;
ops.reward_period_flash = 1;

ops.water_dispense_duration = 0.025;

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
session.IsContinuous = true;
session.addDigitalChannel('dev1','Port0/Line0:1','OutputOnly');
session.outputSingleScan([0,0,0,0]);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]


%% run paradigm

pause(5);
session.outputSingleScan([0,3,0,0]);
start_paradigm = now*1e5;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

start_trial_times = zeros(ops.trial_cap, 1);
reward_times = zeros(ops.trial_cap, 1);
n_trial = 0;
n_reward = 0;
while and((now*1e5 - start_paradigm)<ops.paradigm_duration, n_reward<=ops.trial_cap)
    
    % trial available, wait for lick to start
    lick = 0;
    session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8');
    while and(~lick, (now*1e5 - start_paradigm)<ops.paradigm_duration)
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
        start_trial = now*1e5;
        start_trial_times(n_trial) = now*1e5 - start_paradigm;
        pause(ops.pre_trial_delay);
        if ops.reward_period_flash
            session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8'); % turn on LED
            pause(.005);
            session.outputSingleScan([0,0,0,0]); %write(arduino_port, 2, 'uint8'); % turn off LED
        end
        while and(~lick, (now*1e5 - start_trial)<(ops.pre_trial_delay+ops.reward_window))
            data_in = inputSingleScan(session);
            if data_in > ops.lick_thresh
                lick = 1;
            end
        end
        
        if lick
            n_reward = n_reward + 1;
            reward_times(n_trial) = now*1e5 - start_paradigm;
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


pause(5);
session.outputSingleScan([0,3,0,0]);
end_time = now*1e5 - start_paradigm;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);

%% save data
reward_times(reward_times == 0) = [];

trial_data.reward_times = reward_times;
trial_data.num_trials = n_trial;
trial_data.num_rewards = n_reward;
trial_data.end_time = end_time;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name], 'trial_data', 'ops');
