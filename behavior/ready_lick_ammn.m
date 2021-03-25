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
ops.transition_thresh = 4.5;

% ----- auditory stim params ------------
ops.start_freq = 2000;
% ops.end_freq = 90000;

ops.num_freqs = 10;
ops.increase_factor = 1.5;
ops.MMN_patterns = [3,6; 4,7; 3,8];
ops.base_freq = 0.001; % baseline frequency
ops.modulation_amp = 3;

%% Run script
s_ready_lick_ammn_core;
