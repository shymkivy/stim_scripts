% controls the minimal arduino script
clear;

% params

paradigm_duration = 10;  %  sec
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
arduino_port=serialport('COM4',9600);


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
        write(arduino_port, 3, 'uint8');
        write(arduino_port, 2, 'uint8'); % turn off LED
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

