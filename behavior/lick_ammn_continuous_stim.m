%% audio MMN tones script
%
%   last update: 1/22/20
%
%%
clear;

%% parameters
% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
% ------ Paradigm sequence ------
ops.paradigm_sequence = {'Control', 'MMN', 'flip_MMN'};     % 3 options {'Control', 'MMN', 'flip_MMN'}, concatenate as many as you want
ops.paradigm_trial_num = [400 800 800];%[800, 1200, 1200];                   % how many trials for each paradigm
ops.paradigm_MMN_pattern = [0,3, 3];                       % which patterns for MMN/flip (controls are ignored)
                                                            % 1= horz/vert; 2= 45deg;
% ------ MMN params ------
ops.initial_red_num = 20;                                   % how many redundants to start with
ops.inter_paradigm_pause_time = 60;  % 60                       % how long to pause between paragigms
ops.MMN_probab=[0.1*ones(1,20) .2 .25 .5 1]; 

% ----- stim params ----------
% {paradigm num, 'type', angle/range, volt out}
% type options: 'dev', 'cont'
% angle for cont will tag that freq
% range red: ex [-5 -2] will tag one of red in that relative range

ops.stim_trials_volt = {};

%ops.stim_trials_volt = {2, 'dev', [], 1};...
%                         2, 'dev', [], 2};%1, 'cont', 3, 1;...%};%...
%                         2, 'dev', [], 1;...3, 'dev', [], 1
%                         3, 'dev', [], 3};   
ops.stim_delay = .200; % in sec
ops.stim_trig_duration = 0.01; % sec

%ops.reward_trials = {};
% {paradigm num, 'type'}
ops.reward_trials = {1, 'cont', 5;...
                     2, 'dev', []};
        
ops.lick_to_get_reward = 1;
ops.reward_window = 1;

ops.water_dispense_duration_large = 0.03;% 0.04;
ops.water_dispense_duration_small = 0.03;% 0.03;

ops.reward_lick_rate_thersh_large = 1.5;          % licks per sec below thresh give reward
ops.reward_lick_rate_thersh_small = 3.5;        % licks per sec below thresh give reward1

ops.lick_thresh = 4;
ops.transition_thresh = 4;

%
ops.old_daq = 1;
ops.daq_dev = 'Dev1';
ops.sound_TD_amp = 1;

ops.volt_cmd = [0,0,0,0,0,0];
ops.stim_chan = 1;
ops.LED_chan = 2;
ops.trig_chan = 3;
ops.SLM_stim_chan = 4;
ops.LED_bh_chan = 5;
ops.reward_chan = 6;
                
% probability of deviants   % MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab
% ------ Other ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization

% ----- auditory stim params ------------
%ops.start_freq = 2000;
%ops.end_freq = 90000;

ops.start_freq = 1000;
ops.end_freq = 18000;
ops.num_freqs = 10;
ops.freq_scale = 'log'; % 'log' or 'linear'
ops.increase_factor = 1.5;

% ----- auditory tones stim params -------------

ops.MMN_patterns = [3,6; 4,7; 9,5];
ops.base_freq = 0.001; % baseline frequency
ops.modulation_amp = 4; % maybe use 2

%% predicted run time
run_time = (ops.stim_time+ops.isi_time+0.025)*(sum(ops.paradigm_trial_num)) + (numel(ops.paradigm_trial_num)-1)*ops.inter_paradigm_pause_time + 20 + 120;
fprintf('Expected run duration: %.1fmin (%.fsec)\n',run_time/60,run_time);

% mag = sqrt(angsy.^2 + angsx.^2);
%%
pwd1 = fileparts(mfilename('fullpath'));
if isempty(pwd1)
    pwd1 = pwd;
    %pwd1 = fileparts(which('ready_lick_ammn.m'));
end

addpath([pwd1 '\functions']);
addpath([pwd1 '\..\auditory_stim\functions']);
save_path = [pwd1 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd1 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';

temp_time = clock;
file_name = sprintf('aMMN_tones_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;
%% compute stim types sequence
stim_ctx_stdcount = cell(numel(ops.paradigm_sequence),1);
stim_ang = cell(numel(ops.paradigm_sequence),1);
for n_pr = 1:numel(ops.paradigm_sequence)
    if strcmpi(ops.paradigm_sequence{n_pr}, 'control')
        samp_seq = randperm(ops.paradigm_trial_num(n_pr));
        samp_pool = repmat(1:ops.num_freqs,1,ceil(ops.paradigm_trial_num(n_pr)/ops.num_freqs));    
        stim_ang{n_pr} = samp_pool(samp_seq)';
        fprintf('paradigm %d; %d trials per freq\n', n_pr, ops.paradigm_trial_num(n_pr)/ops.num_freqs);
    else
        stdcounts = 0;
        stim_ang{n_pr} = zeros(ops.paradigm_trial_num(n_pr),1);
        stim_ctx_stdcount{n_pr} = zeros(ops.paradigm_trial_num(n_pr),2);
        if strcmpi(ops.paradigm_sequence{n_pr}, 'mmn')
            curr_MMN_pattern = ops.MMN_patterns(ops.paradigm_MMN_pattern(n_pr),:);
        elseif strcmpi(ops.paradigm_sequence{n_pr}, 'flip_mmn')
            curr_MMN_pattern = fliplr(ops.MMN_patterns(ops.paradigm_MMN_pattern(n_pr),:));
        end
        for trl=1:ops.paradigm_trial_num(n_pr)
            if trl <= ops.initial_red_num
                ctxt = 1;
                stdcounts = stdcounts + 1;
            else
                curr_prob = ops.MMN_probab(rem(stdcounts,numel(ops.MMN_probab))+1);
                ctxt = (rand(1) < curr_prob) + 1;  % 1=red, 2=dev
                if ctxt==1
                    stdcounts=1+stdcounts;
                else
                    stdcounts=0;
                end
            end
            stim_ctx_stdcount{n_pr}(trl,:) = [ctxt, stdcounts];
            stim_ang{n_pr}(trl) = curr_MMN_pattern(ctxt);
        end
        fprintf('paradigm %d; %d deviants\n', n_pr, sum(stim_ctx_stdcount{n_pr}(:,1)==2));
    end
end


%% tag stim trials
stim_stim = cell(numel(ops.paradigm_sequence),1);
for n_tag = 1:size(ops.stim_trials_volt,1)
    pr_idx = ops.stim_trials_volt{n_tag,1};
    stim_stim_seq = f_get_stim_trials(ops.stim_trials_volt(n_tag,2:3), stim_ang{pr_idx}, stim_ctx_stdcount{pr_idx});
    if isempty(stim_stim{pr_idx})
        stim_stim{pr_idx} = stim_stim_seq*ops.stim_trials_volt{n_tag,4};
    else
        stim_stim{pr_idx}(logical(stim_stim_seq)) = ops.stim_trials_volt{n_tag,4};
    end
end

%% tag reward trials
rew_tr_seq = cell(numel(ops.paradigm_sequence),1);
for n_tag = 1:size(ops.reward_trials,1)
    pr_idx = ops.reward_trials{n_tag,1};
    rew_tr_seq{pr_idx} = f_get_stim_trials(ops.reward_trials(n_tag,2:3), stim_ang{pr_idx}, stim_ctx_stdcount{pr_idx});
end

%% initialize RZ6
if ops.sound_TD_amp
    circuit_path = [pwd1 '\..\RPvdsEx_circuits\'];
    circuit_file_name = 'sine_mod_play_YS.rcx';

    RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
    RP.Halt;
end

%% design stim
% generate control frequencies
% control_carrier_freq = zeros(1, ops.num_freqs);
% control_carrier_freq(1) = ops.start_freq;
% for ii = 2:ops.num_freqs
%     control_carrier_freq(ii) = control_carrier_freq(ii-1) * ops.increase_factor;
% end

if strcmpi(ops.freq_scale, 'log')
    ops.increase_factor = (ops.end_freq/ops.start_freq)^(1/(ops.num_freqs-1));
    control_carrier_freq = zeros(1, ops.num_freqs);
    control_carrier_freq(1) = ops.start_freq;
    for n_stim = 2:ops.num_freqs
        control_carrier_freq(n_stim) = control_carrier_freq(n_stim-1) * ops.increase_factor;
    end
elseif strcmpi(ops.freq_scale, 'linear')
    control_carrier_freq = linspace(ops.start_freq, ops.end_freq, ops.num_freqs);
end

stim_data.control_carrier_freq = control_carrier_freq;


stim_data.control_carrier_freq = control_carrier_freq;
%% initialize DAQ

if ops.old_daq
    session=daq.createSession('ni');
    session.addAnalogInputChannel(ops.daq_dev,'ai0','Voltage');
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addAnalogOutputChannel(ops.daq_dev,'ao0','Voltage');
    session.addAnalogOutputChannel(ops.daq_dev, 'ao1','Voltage');
    session.addAnalogOutputChannel(ops.daq_dev ,'ao2','Voltage'); % Prairie trig in (>2V)
    session.addAnalogOutputChannel(ops.daq_dev ,'ao3','Voltage'); % SLM indicator
    session.addDigitalChannel(ops.daq_dev,'Port0/Line0','OutputOnly');
    session.addDigitalChannel(ops.daq_dev,'Port0/Line1','OutputOnly'); % Reward
else
    session=daq('ni');
    session.addinput(ops.daq_dev,'ai0','Voltage'); % record licks from sensor
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addoutput(ops.daq_dev,'ao0','Voltage'); % Stim type
    session.addoutput(ops.daq_dev,'ao1','Voltage'); % LED
    session.addoutput(ops.daq_dev,'ao2','Voltage'); % Prairie trig in (>2V)
    session.addoutput(ops.daq_dev,'ao3','Voltage'); % SLM indicator
    session.addoutput(ops.daq_dev,'Port0/Line0','Digital'); % LEDbh
    session.addoutput(ops.daq_dev,'Port0/Line1','Digital'); % Reward
end
volt_cmd = ops.volt_cmd;
f_write_daq_out(session, volt_cmd, ops.old_daq);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

% start with some water
volt_cmd(ops.reward_chan) = 1;
f_write_daq_out(session, volt_cmd, ops.old_daq); % write(arduino_port, 3, 'uint8');
pause(ops.water_dispense_duration_large);
volt_cmd(ops.reward_chan) = 0;
f_write_daq_out(session, volt_cmd, ops.old_daq);

%% Run trials
if ops.sound_TD_amp
    RP.Run;
    RP.SetTagVal('ModulationAmp', ops.modulation_amp);
end

% create tone trace
if ~ops.sound_TD_amp
    Fs = 32768; %HZ
    tone_x = 1/Fs:1/Fs:ops.stim_time;
    all_tones = zeros(ops.num_freqs, numel(tone_x));
    for n_fr = 1:ops.num_freqs
        all_tones(n_fr,:) = sin(tone_x*control_carrier_freq(n_fr)*2*pi);
    end
    ops.Fs = Fs;
    
    stim_data.all_tones = all_tones;
    % figure; plot(train_tone)
    % tic
    % sound(train_tone, Fs)
    % toc
end


%%
state.start_paradigm=now*86400;%GetSecs();

f_pause_synch(10, session, ops.synch_pulse, ops)
stim_times = cell(numel(ops.paradigm_sequence),1);
data_behavior = cell(numel(ops.paradigm_sequence),1);

h = waitbar(0, 'initializeing...');

for n_pr = 1:numel(ops.paradigm_sequence)
    fprintf('Paradigm %d: %s, %d trials:\n',n_pr, ops.paradigm_sequence{n_pr}, ops.paradigm_trial_num(n_pr));
    
    % check what paradigm
    if strcmpi(ops.paradigm_sequence{n_pr}, 'control')
        cont_parad = 1;
    else
        cont_parad = 0;
    end
    stim_times{n_pr} = zeros(ops.paradigm_trial_num(n_pr),1);
    
    data.time_correct_lick = zeros(ops.paradigm_trial_num(n_pr),1);
    data.time_reward = zeros(ops.paradigm_trial_num(n_pr),1);
    data.reward_type = zeros(ops.paradigm_trial_num(n_pr),1);
    data.time_lick_on = zeros(5000,1);
    data.time_lick_off = zeros(5000,1);
    
    state.n_lick_on = 0;             % record all lick times
    state.n_lick_off = 0;
    state.last_lick_low_time = - 500;
    state.last_lick_high_time = - 500;
    state.last_lick_state = 0;
    state.lick_transition = 0;
    state.num_trial_licks = 0;
    state.last_volt = 0;
    state.start_reward = - 500;
    state.end_reward = - 500;
    state.reward_trial = 0;
    
    % run trials
    for trl=1:ops.paradigm_trial_num(n_pr)
        start_trial1 = now*86400;%GetSecs();
        
        state.n_trial = trl;
        state.stim_type = stim_ang{n_pr}(trl);
        if cont_parad
            state.volt_stim = state.stim_type/ops.num_freqs*4;
        else
            state.volt_stim = stim_ctx_stdcount{n_pr}(trl,1);
        end
        
        if ~isempty(stim_stim{n_pr})
            state.SLM_volt = stim_stim{n_pr}(trl);
            state.trig_volt = logical(state.SLM_volt)*5;
        else
            state.SLM_volt = 0;
            state.trig_volt = 0;
        end
        
        if ~isempty(rew_tr_seq{n_pr})
            state.reward_trial = rew_tr_seq{n_pr}(trl);
        end
        
        waitbar(trl/ops.paradigm_trial_num(n_pr), h, sprintf('Paradigm %d of %d: Trial %d, angle %d',n_pr, numel(ops.paradigm_sequence), trl, state.stim_type));
        % pause for isi
        
        % play
        state.start_stim = now*86400;%GetSecs();
        
        if state.reward_trial
            state.trial_lick_rate = 0;%state.num_trial_licks/(now*86400 - start_trial);
            if ops.lick_to_get_reward
                state.start_reward = state.start_stim;
                state.end_reward = state.start_reward + ops.reward_window;
            end
        end
        
        [state, data] = f_run_tone_stim(state, data, ops, RP, session, stim_data);
        
        
        state.end_pause = state.start_stim + ops.stim_time + ops.isi_time+rand(1)/20;
        [state, data] = f_run_reward_pause(state, data, ops, session);
        
        % record
        stim_times{n_pr}(trl) = state.start_stim-state.start_paradigm;
        %fprintf('; Angle %d\n', ang);
    end
    
    data_behavior{n_pr} = data;
    
    if n_pr < numel(ops.paradigm_sequence)
        f_pause_synch(ops.inter_paradigm_pause_time, session, ops.synch_pulse, ops);
    end
    
end
close(h);

%%
f_pause_synch(10, session, ops.synch_pulse, ops)

%% close all
f_write_daq_out(session, ops.volt_cmd, ops.old_daq);
RP.Halt;

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount', 'stim_stim', 'data_behavior');
fprintf('Done\n');
