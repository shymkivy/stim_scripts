% communicates with the "minimal" arduino script
clear;

%% params
fname = 'nm_day5_RL_ammn_3';

ops.paradigm_duration = 1800;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

ops.pre_trial_delay = .5;  % sec
ops.pre_trial_delay_rand = 0;
ops.reward_window = 2;
ops.failure_timeout = 5;
ops.post_trial_delay = 5;  % sec was 2
ops.require_second_lick = 1;
ops.reward_period_flash = 0;

ops.water_dispense_duration = 0.025;

ops.lick_thresh = 4;

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
ops.modulation_amp = 2 ;
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

%% design stim
% generate control frequencies
control_carrier_freq = zeros(1, ops.num_freqs);
control_carrier_freq(1) = ops.start_freq;
for n_stim = 2:ops.num_freqs
    control_carrier_freq(n_stim) = control_carrier_freq(n_stim-1) * ops.increase_factor;
end

%% design stim types sequence
dev_idx = zeros(ops.trial_cap,1);
dev_ctx = 0;
for n_tr = 1:ops.trial_cap
    n_stim = 1;
    while ~dev_ctx
        curr_prob = ops.MMN_probab(n_stim);
        dev_ctx = (rand(1) < curr_prob);
        if dev_ctx
            dev_idx(n_tr) = n_stim;
        else
            n_stim = n_stim + 1;
        end
    end
    dev_ctx = 0;
end
dev_idx = dev_idx + ops.red_pre_trial;

% stim types
mmn_red_dev_seq = zeros(ops.trial_cap,2);
for n_tr = 1:ops.trial_cap
    mmn_red_dev_seq(n_tr,:) = randsample(ops.stim_range, 2, 0);
end

%figure; histogram(dev_idx);
%% run paradigm
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);

pause(5);
session.outputSingleScan([0,3,0,0]);
start_paradigm = now*86400;
pause(1);
session.outputSingleScan([0,0,0,0]);
pause(5);


time_trial_start = zeros(ops.trial_cap, 1);
time_reward_period_start = zeros(ops.trial_cap, 1);
time_correct_lick = zeros(ops.trial_cap, 1);
time_stim = cell(ops.trial_cap,1);
n_trial = 0;
n_reward = 0;
start_reward_period = -500;
while and((now*86400 - start_paradigm)<ops.paradigm_duration, n_trial<=ops.trial_cap)
    
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
        lick = 0;
        start_trial = now*86400;
        time_trial_start(n_trial) = start_trial - start_paradigm;
       
        trial_delay = ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1);
        pause(trial_delay);
        
        stim_finish = 0;
        reward_received = 0;
        num_stim = dev_idx(n_trial)+ops.red_post_trial;
        time_stim{n_tr} = zeros(num_stim,1);
        n_stim = 1;
        
        % start stim
        while and(~stim_finish, n_stim<=num_stim)
            if n_stim == dev_idx(n_trial)
                stim_type = mmn_red_dev_seq(n_trial,2);
                reward_trial = 1;
            else
                stim_type = mmn_red_dev_seq(n_trial,1);
                reward_trial = 0;
            end
            volt =  stim_type/ops.num_freqs*4;
            
            if reward_trial
                if ops.reward_period_flash
                    session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8'); % turn on LED
                    pause(.005);
                    session.outputSingleScan([0,0,0,0]); %write(arduino_port, 2, 'uint8'); % turn off LED
                end
            end
            % play
            start_stim = now*86400;%GetSecs();
            if reward_trial
                start_reward_period = start_stim;
                time_reward_period_start(n_trial) = start_reward_period - start_paradigm;
            end
            RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
            session.outputSingleScan([volt,0,0,0]);
            session.outputSingleScan([volt,0,0,0]);
            while (now*86400 - start_stim) < ops.stim_time
                data_in = inputSingleScan(session);
                if data_in > ops.lick_thresh
                    if ~reward_received
                        if (now*86400 - start_reward_period) < ops.reward_window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            reward_received = 1;
                            session.outputSingleScan([volt,0,0,1]); % write(arduino_port, 3, 'uint8');
                            pause(ops.water_dispense_duration);
                            session.outputSingleScan([volt,0,0,0]);
                            n_reward = n_reward + 1;
                        end
                    end
                end
            end
            RP.SetTagVal('CarrierFreq', ops.base_freq);
            session.outputSingleScan([0,0,0,0]);
            session.outputSingleScan([0,0,0,0]);
            
            % pause for isi
            start_isi = now*86400;
            isi_duration = ops.isi_time+rand(1)*ops.rand_time_pad;
            while (now*86400 - start_isi) < isi_duration
                data_in = inputSingleScan(session);
                if data_in > ops.lick_thresh
                    if ~reward_received
                        if (now*86400 - start_reward_period) < ops.reward_window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            reward_received = 1;
                            session.outputSingleScan([0,0,0,1]); % write(arduino_port, 3, 'uint8');
                            pause(ops.water_dispense_duration);
                            session.outputSingleScan([0,0,0,0]);
                            n_reward = n_reward + 1;
                        end
                    end
                end
            end
            
            time_stim{n_tr}(n_stim) = start_stim-start_paradigm;
            
            n_stim = n_stim  + 1;
        end
        fprintf('n_trial = %d, n_reward = %d\n', n_trial, n_reward);
    end
    
    pause(ops.post_trial_delay);
    
end
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
save([save_path file_name],  'trial_data', 'ops');
