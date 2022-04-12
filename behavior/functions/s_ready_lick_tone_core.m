%%
pwd2 = fileparts(which('ready_lick_ammn.m'));

addpath([pwd2 '\..\auditory_stim\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\behavior\'];

%% design stim,  generate control frequencies
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


%% design stim types sequence
% 'quiet' has variable quiet period followed by one of the devs

if numel(ops.dev_tone_list) == 1
    dev_seq = ones(ops.trial_cap,1)*ops.dev_tone_list;
else
    dev_seq = randsample(ops.dev_tone_list, ops.trial_cap, 1); 
end


if strcmpi(ops.trial_ctx_type, 'quiet')
    % get dev trial time
    dev_times = rand(ops.trial_cap,1)*(ops.quiet_dev_delay_range(2)-ops.quiet_dev_delay_range(1))+ops.quiet_dev_delay_range(1);
else
    ctx_seq = cell(ops.trial_cap,1);
    % get dev trial index
    dev_idx = zeros(ops.trial_cap,1);
    dev_ctx = 0;
    for n_trial = 1:ops.trial_cap
        n_stim = 1;
        while ~dev_ctx
            curr_prob = ops.dev_probab(n_stim);
            dev_ctx = (rand(1) < curr_prob);
            if dev_ctx
                dev_idx(n_trial) = n_stim;
            else
                n_stim = n_stim + 1;
            end
        end
        dev_ctx = 0;
    end
    dev_idx = dev_idx + ops.red_num_pre_trial;

    if strcmpi(ops.trial_ctx_type, 'mmn')
        
        
    elseif strcmpi(ops.trial_ctx_type, 'control')
        
    end
end
% 
% 
% % stim types
% if strcmpi(ops.stim_selection_type, 'randsamp')
%     mmn_red_dev_seq = zeros(ops.trial_cap,2); % 1 - red 2 - dev
%     for n_trial = 1:ops.trial_cap
%         mmn_red_dev_seq(n_trial,1) = randsample(ops.red_tone_list, 1, 1); 
%         if numel(ops.reward_tone_list) == 1
%             mmn_red_dev_seq(n_trial,2) = ops.reward_tone_list;
%         else
%             mmn_red_dev_seq(n_trial,2) = randsample(ops.reward_tone_list, 1, 1); 
%         end
%     end
% else
%     num_pat = size(ops.MMN_pat,1)*2;
%     pat_all = repmat([ops.MMN_pat;fliplr(ops.MMN_pat)], ceil(ops.trial_cap/ops.seq_len/num_pat), 1, ops.seq_len);
%     if strcmpi(ops.stim_selection_type, 'sequences')
%         mmn_red_dev_seq = reshape(permute(pat_all, [3 1 2]), [], 2);
%     elseif strcmpi(ops.stim_selection_type, 'rand_sequences')
%         rand_seq = randperm(size(pat_all,1));
%         mmn_red_dev_seq = reshape(permute(pat_all(rand_seq,:,:), [3 1 2]), [], 2);
%     end
% end
% 

%figure; histogram(dev_idx);

%% initialize DAQ
if old_daq
    session=daq.createSession('ni');
    session.addAnalogInputChannel(daq_dev,'ai0','Voltage');
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addAnalogOutputChannel(daq_dev,'ao0','Voltage');
    session.addAnalogOutputChannel(daq_dev,'ao1','Voltage');
    session.addDigitalChannel(daq_dev,'Port0/Line0','OutputOnly');
    session.addDigitalChannel(daq_dev,'Port0/Line1','OutputOnly'); % Reward
else
    session=daq('ni');
    session.addinput(daq_dev,'ai0','Voltage'); % record licks from sensor
    session.Channels(1).Range = [-10 10];
    session.Channels(1).TerminalConfig = 'SingleEnded';
    session.addoutput(daq_dev,'ao0','Voltage'); % Stim type
    session.addoutput(daq_dev,'ao1','Voltage'); % LED
    session.addoutput(daq_dev,'Port0/Line0','Digital'); % LEDbh
    session.addoutput(daq_dev,'Port0/Line1','Digital'); % Reward
end
f_write_daq_out(session, [0,0,0,0], old_daq);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

% start with some water
f_write_daq_out(session, [0,0,0,1], old_daq); % write(arduino_port, 3, 'uint8');
pause(ops.water_dispense_duration_large);
f_write_daq_out(session, [0,0,0,0], old_daq);
%% initialize RZ6

if ops.sound_TD_amp
    circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
    circuit_file_name = 'sine_mod_play_YS.rcx';

    RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
    RP.Halt;
end


%% run paradigm
if ops.sound_TD_amp
    RP.Run;
    RP.SetTagVal('ModulationAmp', ops.modulation_amp);
end


%%
% chreate tone trace
if ~ops.sound_TD_amp
    
    Fs = 32768; %HZ
    tone_x = 1/Fs:1/Fs:ops.stim_time;
    all_tones = zeros(ops.num_freqs, numel(tone_x));
    for n_fr = 1:ops.num_freqs
        all_tones(n_fr,:) = sin(tone_x*control_carrier_freq(n_fr)*2*pi);
    end
    ops.Fs = Fs;
    % figure; plot(train_tone)
    % tic
    % sound(train_tone, Fs)
    % toc
end

%%

pause(5);
f_write_daq_out(session, [0,3,0,0], ops.old_daq);
state.start_paradigm = now*86400;
pause(1);
f_write_daq_out(session, [0,0,0,0], ops.old_daq);
pause(5);

%%
data.time_trial_start = zeros(ops.trial_cap, 1);
data.time_reward_period_start = zeros(ops.trial_cap, 1);
data.time_reward_period_end = zeros(ops.trial_cap, 1);
data.time_correct_lick = zeros(ops.trial_cap, 1);
data.time_reward = zeros(ops.trial_cap, 1);
data.time_stim = cell(ops.trial_cap,1);
data.reward_onset_num_licks = zeros(ops.trial_cap, 1);
data.reward_type = zeros(ops.trial_cap, 1);
data.reward_onset_lick_rate = zeros(ops.trial_cap, 1);
data.time_lick_on = zeros(ops.trial_cap*50,1);
data.time_lick_off = zeros(ops.trial_cap*50,1);

state.n_lick_on = 0;             % record all lick times
state.n_lick_off = 0;
state.last_lick_low_time = now*86400;
state.last_lick_high_time = now*86400;
state.last_lick_state = 0;
state.lick_transition = 0;
state.num_trial_licks = 0;
state.last_volt = 0;
state.start_reward = - 500;
state.end_reward = - 500;
state.n_trial = 0;  

while and((now*86400 - start_paradigm)<ops.paradigm_duration, state.n_trial<ops.trial_cap)
    % wait for animal to stop licking for some time before trial can start
    while (now*86400 - last_lick_high_time)<ops.initial_stop_lick_period
        data_in = f_read_daq_out(session, ops.old_daq);
        [state, data] = f_get_lick_state(data_in, state, data, ops);
    end
    
    % at this point trial is available, wait for lick to start
    if ops.lick_to_start_trial
        % turn on LED bh (hevavior)
        f_write_daq_out(session, [0,0,1,0], ops.old_daq);
        while and(lick_transition<1, (now*86400 - state.start_paradigm)<ops.paradigm_duration)
            data_in = f_read_daq_out(session, ops.old_daq);
            [state, data] = f_get_lick_state(data_in, state, data, ops);
        end
        % turn of LED bh
        f_write_daq_out(session, [0,0,0,0], ops.old_daq);
    end
    
   
    if or(state.lick_transition>0, ~ops.lick_to_start_trial) % if there was lick new trial
        state.n_trial = state.n_trial + 1;
        start_trial = now*86400;
        data.time_trial_start(state.n_trial) = start_trial - state.start_paradigm;
        
        % pretrial delay
        trial_delay = ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1);
        while (now*86400 - start_trial) < trial_delay
            data_in = f_read_daq_out(session, ops.old_daq);
            [state, data] = f_get_lick_state(data_in, state, data, ops);
        end
        
        % reset state
        stim_finish = 0;
        state.num_trial_licks = 0;
        if strcmpi(ops.trial_ctx_type, 'quiet')
            
            % wait until time of tone
            while (now*86400 - start_trial - trial_delay) < dev_times(state.n_trial)
                data_in = f_read_daq_out(session, ops.old_daq);
                [state, data] = f_get_lick_state(data_in, state, data, ops);
            end
            
            stim_type = dev_seq(state.n_trial); 
            reward_trial = 1;
            state.volt_stim = stim_type/ops.num_freqs*4;
            
            f_pre_reward_flash(reward_trial, session, ops);
            
            state.start_stim = now*86400;%GetSecs();

            if reward_trial
                state.trial_lick_rate = state.num_trial_licks/(now*86400 - start_trial);
                if ops.lick_to_get_reward
                    start_reward = state.start_stim;
                    end_reward = start_reward + ops.reward_window;
                end
            end
            
            [state, data] = f_run_tone(state, data, ops, RP, session, all_tones);
            
            % wait for reward window to end  
            state.end_pause = max([end_reward, state.start_stim + ops.stim_time]);
            [state, data] = f_run_reward_pause(state, data, ops, session);
            
            % gather info
            data.time_stim{state.n_trial} = state.start_stim-state.start_paradigm;
            if reward_trial
                data.reward_onset_num_licks(state.n_trial) = num_trial_licks;
                data.reward_onset_lick_rate(state.n_trial) = trial_lick_rate;
                if ops.lick_to_get_reward
                    data.time_reward_period_start(state.n_trial) = start_reward - state.start_paradigm;
                    data.time_reward_period_end(state.n_trial) = end_reward - state.start_paradigm;
                end
            end
        else
            num_stim = dev_idx(state.n_trial)+ops.red_num_post_trial;
            data.time_stim{state.n_trial} = zeros(num_stim,1);
            state.n_stim = 1;

            % start stim
            while and(~stim_finish, state.n_stim<=num_stim)

                if state.n_stim == dev_idx(state.n_trial)
                    stim_type = dev_seq(state.n_trial); 
                    reward_trial = 1;
                else
                    stim_type = ctx_seq{state.n_trial}(state.n_stim);
                    reward_trial = 0;
                end
                state.volt_stim = stim_type/ops.num_freqs*4;
                
                f_pre_reward_flash(reward_trial, session, ops);
            
                state.start_stim = now*86400;%GetSecs();

                if reward_trial
                    state.trial_lick_rate = state.num_trial_licks/(now*86400 - start_trial);
                    if ops.lick_to_get_reward
                        start_reward = state.start_stim;
                        end_reward = start_reward + ops.reward_window;
                    end
                end
                
                [state, data] = f_run_tone(state, data, ops, RP, session, all_tones);
                
                % pause for isi    
                state.end_pause = state.start_stim + ops.stim_time + ops.isi_time+rand(1)*ops.rand_time_pad;
                [state, data] = f_run_reward_pause(state, data, ops, session);
            
                % finish
                data.time_stim{state.n_trial}(state.n_stim) = state.start_stim-state.start_paradigm;
                if reward_trial
                    data.reward_onset_num_licks(state.n_trial) = state.num_trial_licks;
                    data.reward_onset_lick_rate(state.n_trial) = state.trial_lick_rate;
                    if ops.lick_to_get_reward
                        data.time_reward_period_start(state.n_trial) = start_reward - state.start_paradigm;
                        data.time_reward_period_end(state.n_trial) = end_reward - state.start_paradigm;
                    end
                end
                
                state.n_stim = state.n_stim  + 1;
            end
        end
        fprintf('Trials=%d; correct licks=%d; lick rate=%.2f; reward type=%d; high=%d low=%d none=%d\n', state.n_trial, sum(data.reward_type>0), data.reward_onset_lick_rate(state.n_trial), data.reward_type(state.n_trial), sum(data.reward_type==3),sum(data.reward_type==2) ,sum(data.reward_type==1));
    end
    
    pause(ops.post_trial_delay);
    
end
