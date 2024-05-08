% teaching paradigm
% step 1 - train mouse to use lick port "ready_lick_reward"
% step 2 - train mouse to lick in response to tone "ready_lick_tone"

% no arduino script required, only as power source
clear;

pwd1 = fileparts(mfilename('fullpath'));
if isempty(pwd1)
    pwd1 = pwd;
    %pwd1 = fileparts(which('ready_lick_ammn.m'));
end
addpath([pwd1 '\functions'])
%% params

fname = 'mouseR_exp4_im';

ops.paradigm_duration = 2400;  %  sec
ops.trial_cap = 500;            % 200 - 400 typical with 25sol duration

% ------- trial bout params -----------
ops.initial_stop_lick_period = 0;
ops.lick_to_start_trial = 0;
ops.pre_trial_delay = 0;  % sec
ops.pre_trial_delay_rand = 0;
ops.lick_to_get_reward = 1;
ops.reward_window = 2;
ops.failure_timeout = 0;
ops.post_trial_delay = 2;  % sec was 2
ops.require_second_lick = 0;
ops.reward_period_flash = 0;

ops.water_dispense_duration_large = 0.03;% 0.04;
ops.water_dispense_duration_small = 0.04;% 0.03;

ops.reward_lick_rate_thersh_large = 1.5;          % licks per sec below thresh give reward
ops.reward_lick_rate_thersh_small = 2.5;        % licks per sec below thresh give reward1

% cont and mmn are dev trials fit among other trials
% quiet is dev trial coming in some time range
ops.daq_dev = 'Dev1';
ops.old_daq = 1;
ops.volt_cmd = [0, 0, 0, 0];
ops.stim_chan = 1;
ops.LED_chan = 2;
ops.LED_bh_chan = 3;
ops.reward_chan = 4;


% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
ops.rand_time_pad = .025;

ops.sound_TD_amp = 1;

% ----- auditory stim params ------------
if contains(fname, 'exp4')
    ops.start_freq = 2000;
    ops.end_freq = 76887;
    ops.num_freqs = 10;
    ops.dev_tone_list = 5; % list of possible 'deviant' tones that get rewarded

else
    ops.start_freq = 1000;
    ops.end_freq = 18000;
    ops.num_freqs = 10;
    ops.dev_tone_list = 5; % list of possible 'deviant' tones that get rewarded

end
ops.freq_scale = 'log'; % 'log' or 'linear'

% ------ trial structure ------------
ops.trial_ctx_type = 'quiet'; % 'control', 'mmn', 'quiet';

ops.dev_tone_list = 5; % list of possible 'deviant' tones that get rewarded

% 'mmn' params
ops.red_tone_list = [3 4 5 6 7]; % possible red tones for mmn
ops.red_num_pre_trial = 3;
ops.red_num_post_trial = 3;
ops.red_lim = 7; % min lim is 5; adjust for pretrial red padding
ops.dev_probab=[0.1*ones(1,max(ops.red_lim-4,1)) .2 .25 .5 1]; 
% MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab

% 'quiet' params
ops.quiet_dev_delay_range = [3 13];

% ----- sequences of trials structure -----------------
ops.stim_selection_type = 'sequences'; % 'randsamp', 'sequences', 'rand_sequences' 
ops.MMN_pat = [3, 6];
ops.seq_len = 50;


% ------ Other params ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization
ops.lick_thresh = 4;
ops.transition_thresh = 4;

% ----- TD amplifier params-----
ops.base_freq = 0.001; % baseline frequecy
ops.modulation_amp = 5;

%% Run script
%s_ready_lick_ammn_core;
s_ready_lick_tone_core;

%%
s_ready_lick_tone_save;

disp('Done')

