%%

pwd1 = mfilename('fullpath');
if isempty(pwd1)
    pwd1 = pwd;
    %pwd1 = fileparts(which('ready_lick_ammn.m'));
end

addpath([pwd1 '\..\auditory_stim\functions']);
save_path = [pwd1 '\..\..\stim_scripts_output\behavior\'];
%circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
%circuit_file_name = 'sine_mod_play_YS.rcx';
%% Initialize arduino
%arduino_port=serialport('COM19',9600);

%% initialize RZ6
% RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
% RP.Halt;

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
if strcmpi(ops.stim_selection_type, 'randsamp')
    mmn_red_dev_seq = zeros(ops.trial_cap,2);
    for n_tr = 1:ops.trial_cap
        mmn_red_dev_seq(n_tr,:) = randsample(ops.stim_range, 2, 0);
    end
else
    num_pat = size(ops.MMN_pat,1)*2;
    pat_all = repmat([ops.MMN_pat;fliplr(ops.MMN_pat)], ceil(ops.trial_cap/ops.num_seq/num_pat), 1, ops.num_seq);
    if strcmpi(ops.stim_selection_type, 'sequences')
        mmn_red_dev_seq = reshape(permute(pat_all, [3 1 2]), [], 2);
    elseif strcmpi(ops.stim_selection_type, 'rand_sequences')
        rand_seq = randperm(size(pat_all,1));
        mmn_red_dev_seq = reshape(permute(pat_all(rand_seq,:,:), [3 1 2]), [], 2);
    end
end
%figure; histogram(dev_idx);
%% run paradigm
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);

pause(5);
f_write_daq_out(session, [0,3,0,0], old_daq);
start_paradigm = now*86400;
pause(1);
f_write_daq_out(session, [0,0,0,0], old_daq);
pause(5);

%%
time_trial_start = zeros(ops.trial_cap, 1);
time_reward_period_start = zeros(ops.trial_cap, 1);
time_correct_lick = zeros(ops.trial_cap, 1);
time_stim = cell(ops.trial_cap,1);
reward_onset_num_licks = zeros(ops.trial_cap, 1);
reward_type = zeros(ops.trial_cap, 1);
reward_onset_lick_rate = zeros(ops.trial_cap, 1);

n_lick_on = 0;             % record all lick times
n_lick_off = 0;
last_lick_low_time = now*86400;
last_lick_high_time = now*86400;
last_lick_state = 0;
time_lick_on = zeros(ops.trial_cap*50,1);
time_lick_off = zeros(ops.trial_cap*50,1);
lick_transition = 0;

num_trial_licks = 0;
last_volt = 0;
start_reward_period = -500;
n_trial = 0;  
while and((now*86400 - start_paradigm)<ops.paradigm_duration, n_trial<ops.trial_cap)
    % wait for animal to stop licking for some time
    while (now*86400 - last_lick_high_time)<ops.initial_stop_lick_period
        data_in = f_read_daq_out(session, ops.old_daq);
        s_get_lick_state;
    end
    
    % trial available, wait for lick to start
    f_write_daq_out(session, [0,0,1,0], old_daq); %write(arduino_port, 1, 'uint8');
    while and(lick_transition<1, (now*86400 - start_paradigm)<ops.paradigm_duration)
        data_in = f_read_daq_out(session, old_daq);
        s_get_lick_state;
    end
    f_write_daq_out(session, [0,0,0,0], old_daq); %write(arduino_port, 2, 'uint8'); % turn off LED
    
    if lick_transition>0
        n_trial = n_trial + 1;
        start_trial = now*86400;
        time_trial_start(n_trial) = start_trial - start_paradigm;
       
        trial_delay = ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1);
        pause(trial_delay);
        
        stim_finish = 0;
        num_trial_licks = 0;
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
                    f_write_daq_out(session, [0,0,1,0], old_daq); %write(arduino_port, 1, 'uint8'); % turn on LED
                    pause(.005);
                    f_write_daq_out(session, [0,0,0,0], old_daq); %write(arduino_port, 2, 'uint8'); % turn off LED
                end
            end
            % play
            start_stim = now*86400;%GetSecs();
            
            if reward_trial
                start_reward_period = start_stim;
                time_reward_period_start(n_trial) = start_reward_period - start_paradigm;
                reward_onset_num_licks(n_trial) = num_trial_licks;
                reward_onset_lick_rate(n_trial) = num_trial_licks/(now*86400 - start_trial);
            end
            RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
            f_write_daq_out(session, [volt,0,0,0], old_daq);
            f_write_daq_out(session, [volt,0,0,0], old_daq);
            while (now*86400 - start_stim) < ops.stim_time
                data_in = f_read_daq_out(session, old_daq);
                s_get_lick_state;
                if lick_transition>0
                    if ~reward_type(n_trial) % if not rewarded yet
                        if (now*86400 - start_reward_period) < ops.reward_window % if within window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            if reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_large
                                reward_type(n_trial) = 3;        % large reward
                                f_write_daq_out(session, [volt,0,0,1], old_daq);% write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_large);
                                f_write_daq_out(session, [volt,0,0,0], old_daq);
                            elseif reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_small
                                reward_type(n_trial) = 2;        % small reward
                                f_write_daq_out(session, [volt,0,0,1], old_daq); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_small);
                                f_write_daq_out(session, [volt,0,0,0], old_daq);
                            else
                                reward_type(n_trial) = 1;        % no reward
                            end
                        end
                    end
                end
            end
            RP.SetTagVal('CarrierFreq', ops.base_freq);
            f_write_daq_out(session, [0,0,0,0], old_daq);
            f_write_daq_out(session, [0,0,0,0], old_daq);
            
            % pause for isi
            start_isi = now*86400;
            isi_duration = ops.isi_time+rand(1)*ops.rand_time_pad;
            while (now*86400 - start_isi) < isi_duration
                data_in = inputSingleScan(session);
                s_get_lick_state;
                if lick_transition>0
                    if ~reward_type(n_trial)
                        if (now*86400 - start_reward_period) < ops.reward_window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            if reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_large
                                reward_type(n_trial) = 3;        % large reward
                                f_write_daq_out(session, [volt,0,0,1], old_daq); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_large);
                                f_write_daq_out(session, [volt,0,0,0], old_daq);
                            elseif reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_small
                                reward_type(n_trial) = 2;        % small reward
                                f_write_daq_out(session, [volt,0,0,1], old_daq); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_small);
                                f_write_daq_out(session, [volt,0,0,0], old_daq);
                            else
                                reward_type(n_trial) = 1;        % no reward
                            end
                        end
                    end
                end
            end
            
            time_stim{n_tr}(n_stim) = start_stim-start_paradigm;
            
            n_stim = n_stim  + 1;
        end
        fprintf('Trials=%d; correct licks=%d; lick rate=%.2f; reward type=%d; high=%d low=%d none=%d\n', n_trial, sum(reward_type>0), reward_onset_lick_rate(n_trial), reward_type(n_trial), sum(reward_type==3),sum(reward_type==2) ,sum(reward_type==1));
    end
    
    pause(ops.post_trial_delay);
    
end

