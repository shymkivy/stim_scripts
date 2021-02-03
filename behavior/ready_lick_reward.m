% communicates with the "minimal.ino" arduino script
clear;

%% params
fname = 'nm_ready_lick_reward_day2';

paradigm_duration = 1800;  %  sec
post_reward_delay = 2;  % sec
trial_cap = 500;            % 200 - 400 typical with 25sol duration

pwd2 = fileparts(which('ready_lick_reward.m'));
%% Initialize arduino
arduino_port=serialport('COM19',9600);

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogInputChannel('Dev1','ai0','Voltage');
session.Channels(1).Range = [-10 10];
session.Channels(1).TerminalConfig = 'SingleEnded';
session.addAnalogOutputChannel('Dev1','ao0','Voltage'); % stim type
session.addAnalogOutputChannel('Dev1','ao1','Voltage'); % synch pulse LED
session.IsContinuous = true;
%session.Rate = 10000;

%% run paradigm

pause(5);
session.outputSingleScan([0,3]);
start_paragm = now*1e5;
pause(1);
session.outputSingleScan([0,0]);
pause(5);


lick_thresh = 4;
reward_times = zeros(trial_cap, 1);
num_trials = 0;
while and((now*1e5 - start_paragm)<paradigm_duration, num_trials<trial_cap)
    
    num_trials = 0;
    % reward available, wait for lick
    write(arduino_port, 1, 'uint8');
    while and(~num_trials, (now*1e5 - start_paragm)<paradigm_duration)
        data_in = inputSingleScan(session);
        if data_in > lick_thresh
            num_trials = 1;
        end
    end
    
    if num_trials
        write(arduino_port, 2, 'uint8'); % turn off LED
        write(arduino_port, 3, 'uint8');
        
        num_trials = num_trials + 1;
        reward_times(num_trials) = now*1e5 - start_paragm;
    end
    
    pause(post_reward_delay);
    
end
write(arduino_port, 2, 'uint8'); % turn off LED


pause(5);
session.outputSingleScan([0,3]);
end_time = now*1e5 - start_paragm;
pause(1);
session.outputSingleScan([0,0]);
pause(5);

reward_times(reward_times == 0) = [];

trial_data.reward_times = reward_times;
trial_data.num_licks = num_trials;
trial_data.paradigm_duration = paradigm_duration;
trial_data.post_reward_delay = post_reward_delay;
trial_data.trial_cap = trial_cap;
trial_data.end_time = end_time;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
save_path = [pwd2 '\..\..\stim_scripts_output\' file_name];
save(save_path, 'trial_data');
