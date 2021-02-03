% controls the minimal arduino script
clear;

% params

fname = 'nm_lick_reward_day2';

pwd2 = fileparts(which('lick_reward_matlab.m'));

paradigm_duration = 1800;  %  sec
post_reward_delay = 2;  % sec
trial_cap = 500;

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogInputChannel('Dev1','ai0','Voltage');
session.Channels(1).Range = [-10 10];
session.Channels(1).TerminalConfig = 'SingleEnded';
session.IsContinuous = true;
%session.Rate = 10000;

%% Initialize arduino
arduino_port=serialport('COM19',9600);


%% run paradigm

lick_thresh = 4;
start_paragm = now*1e5;

reward_times = zeros(trial_cap ,1);
num_licks = 0;
while and((now*1e5 - start_paragm)<paradigm_duration, num_licks<trial_cap)
    
    lick = 0;
    % reward available, wait for lick
    write(arduino_port, 1, 'uint8');
    while and(~lick, (now*1e5 - start_paragm)<paradigm_duration)
        data_in = inputSingleScan(session);
        if data_in > lick_thresh
            lick = 1;
        end
    end
    
    if lick
        write(arduino_port, 2, 'uint8'); % turn off LED
        write(arduino_port, 3, 'uint8');
        
        num_licks = num_licks + 1;
        reward_times(num_licks) = now*1e5 - start_paragm;
    end
    
    pause(post_reward_delay);
    
end
write(arduino_port, 2, 'uint8'); % turn off LED

reward_times(reward_times == 0) = [];

trial_data.reward_times = reward_times;
trial_data.num_licks = num_licks;
trial_data.paradigm_duration = paradigm_duration;
trial_data.post_reward_delay = post_reward_delay;
trial_data.trial_cap = trial_cap;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
save_path = [pwd2 '\..\..\stim_scripts_output\' file_name];
save(save_path, 'trial_data');
