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
addpath([pwd '\functions'])
%% params
fname = 'mouseR_exp3';

ops.paradigm_duration = 1200;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

ops.initial_stop_lick_period = 0;
ops.pre_trial_delay = 0;  % sec
ops.pre_trial_delay_rand = 0;
ops.reward_window = 2;
ops.failure_timeout = 0;
ops.post_trial_delay = 3;  % sec
ops.require_second_lick = 0;
ops.reward_period_flash = 0;

ops.water_dispense_duration = .02; % or .2 for more trials  
ops.old_daq = 1;
ops.daq_dev = 'Dev1';

ops.lick_thresh = 4;
%%
pwd2 = fileparts(which('ready_lick_reward.m'));
save_path = [pwd2 '\..\..\stim_scripts_output\behavior\'];

%% Initialize arduino
%arduino_port=serialport('COM19',9600);

%% initialize DAQ
if ops.old_daq
    session=daq.createSession('ni');
    session.addAnalogInputChannel(ops.daq_dev,'ai0','Voltage');
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addAnalogOutputChannel(ops.daq_dev,'ao0','Voltage');
    session.addAnalogOutputChannel(ops.daq_dev,'ao1','Voltage');
    session.addDigitalChannel(ops.daq_dev,'Port0/Line0','OutputOnly');
    session.addDigitalChannel(ops.daq_dev,'Port0/Line1','OutputOnly'); % Reward
else
    session=daq('ni');
    session.addinput(ops.daq_dev,'ai0','Voltage'); % record licks from sensor
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addoutput(ops.daq_dev,'ao0','Voltage'); % Stim type
    session.addoutput(ops.daq_dev,'ao1','Voltage'); % LED
    session.addoutput(ops.daq_dev,'Port0/Line0','Digital'); % LEDbh
    session.addoutput(ops.daq_dev,'Port0/Line1','Digital'); % Reward
end
f_write_daq_out(session, [0,0,0,0], ops.old_daq);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

%% run paradigm

% pause(5);
% session.write([0,3,0,0]);
state.start_paradigm = now*86400;
% pause(1);
% session.write([0,0,0,0]);
% pause(5);

data.time_trial_start = zeros(ops.trial_cap, 1);
data.time_reward_period_start = zeros(ops.trial_cap, 1);
data.time_correct_lick = zeros(ops.trial_cap, 1);
state.n_trial = 0;
state.n_reward = 0;
while and((now*86400 - state.start_paradigm)<ops.paradigm_duration, state.n_reward<=ops.trial_cap)
    
    % wait for animal to stop licking for some time
    state.last_lick = now*86400;
    while (now*86400 - state.last_lick)<ops.initial_stop_lick_period
        data_in = f_read_daq_out(session, ops.old_daq);
        if data_in > ops.lick_thresh
            state.last_lick = now*86400;
        end
    end
    
    % trial available, wait for lick to start
    state.lick = 0;
    f_write_daq_out(session, [0,0,1,0], ops.old_daq); %write(arduino_port, 1, 'uint8');
    while and(~state.lick, (now*86400 - state.start_paradigm)<ops.paradigm_duration)
        data_in = f_read_daq_out(session, ops.old_daq);
        if data_in > ops.lick_thresh
            state.lick = 1;
        end
    end

    f_write_daq_out(session, [0,0,0,0], ops.old_daq);  %write(arduino_port, 2, 'uint8'); % turn off LED
    
    if state.lick
        state.n_trial = state.n_trial + 1;
        if ops.require_second_lick
            state.lick = 0;
        end
        state.start_trial = now*86400; 
        data.time_trial_start(state.n_trial) = state.start_trial - state.start_paradigm;
        
        % trial delay
        pause(ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1));
        
        if ops.reward_period_flash
            f_write_daq_out(session, [0,0,1,0], ops.old_daq); %write(arduino_port, 1, 'uint8'); % turn on LED
            pause(.005);
            f_write_daq_out(session, [0,0,0,0], ops.old_daq); %write(arduino_port, 2, 'uint8'); % turn off LED
        end
        state.reward_period_start = now*86400;
        data.time_reward_period_start(n_trial) = state.reward_period_start - state.start_paradigm;
        while and(~state.lick, (now*86400 - state.reward_period_start)<(ops.reward_window))
            data_in = f_read_daq_out(session, ops.old_daq);
            if data_in > ops.lick_thresh
                state.lick = 1;
                data.time_correct_lick(n_trial) = now*86400 - state.start_paradigm;
            end
        end
        
        if state.lick
            state.n_reward = state.n_reward + 1;
            f_write_daq_out(session, [0,0,0,1], ops.old_daq);% write(arduino_port, 3, 'uint8');; 
            pause(ops.water_dispense_duration);
            f_write_daq_out(session, [0,0,0,0], ops.old_daq);
        else
            pause(ops.failure_timeout);
        end
        fprintf('n_trial = %d, n_reward = %d\n', n_trial, state.n_reward);
    end
    pause(ops.post_trial_delay);
end

f_write_daq_out(session, [0,0,0,0], ops.old_daq);
pause(5);
f_write_daq_out(session, [0,3,0,0], ops.old_daq);
time_paradigm_end = now*86400 - state.start_paradigm;
pause(1);
f_write_daq_out(session, [0,0,0,0], ops.old_daq);
pause(5);

%% save data
%reward_times(reward_times == 0) = [];
trial_data = data;
trial_data.num_trials = state.n_trial;
trial_data.num_rewards = state.n_reward;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name], 'trial_data', 'ops');
