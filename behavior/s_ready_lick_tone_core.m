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
daq_dev = 'Dev2';
session=daq('ni');
session.addinput(daq_dev,'ai0','Voltage'); % record licks from sensor
session.Channels(1).Range = [-10 10];
session.Channels(1).TerminalConfig = 'SingleEnded';
session.addoutput(daq_dev,'ao0','Voltage'); % Stim type
session.addoutput(daq_dev,'ao1','Voltage'); % LED
session.addoutput(daq_dev,'Port0/Line0','Digital'); % LEDbh
session.addoutput(daq_dev,'Port0/Line1','Digital'); % Reward
session.write([0,0,0,0]);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

% start with some water
session.write([0,0,0,1]); % write(arduino_port, 3, 'uint8');
pause(ops.water_dispense_duration_large);
session.write([0,0,0,0]);

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
session.write([0,3,0,0]);
start_paradigm = now*86400;
pause(1);
session.write([0,0,0,0]);
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
    % wait for animal to stop licking for some time before trial can start
    while (now*86400 - last_lick_high_time)<ops.initial_stop_lick_period
        data_in = read(session, "OutputFormat","Matrix");
        s_get_lick_state;
    end
    
    
    
    % at this point trial is available, wait for lick to start
    if ops.lick_to_start_trial
        % turn on LED bh (hevavior)
        session.write([0,0,1,0]); %write(arduino_port, 1, 'uint8');
        while and(lick_transition<1, (now*86400 - start_paradigm)<ops.paradigm_duration)
            data_in = read(session, "OutputFormat","Matrix");
            s_get_lick_state;
        end
        % turn of LED bh
        session.write([0,0,0,0]);
    end
    
   
    if or(lick_transition>0, ~ops.lick_to_start_trial) % if there was lick new trial
        n_trial = n_trial + 1;
        start_trial = now*86400;
        time_trial_start(n_trial) = start_trial - start_paradigm;

        trial_delay = ops.pre_trial_delay+ops.pre_trial_delay_rand*rand(1);
        pause(trial_delay);
        
        stim_finish = 0;
        num_trial_licks = 0;
        % maybe add lick times here
        
        
        if strcmpi(ops.trial_ctx_type, 'quiet')
            while (now*86400 - start_trial - trial_delay) < dev_times(n_trial)
                data_in = read(session, "OutputFormat","Matrix");
                s_get_lick_state;
            end
            
            stim_type = dev_seq(n_trial); 
            reward_trial = 1;
            volt_stim = stim_type/ops.num_freqs*4;
            
            s_run_tone;
            
            % pause for remainder of reward period                
            start_reward = start_stim;
            reward_duration = ops.reward_window;
            s_run_reward_period;
            
            time_stim{n_trial} = start_stim-start_paradigm;
            
        else
            num_stim = dev_idx(n_trial)+ops.red_num_post_trial;
            time_stim{n_trial} = zeros(num_stim,1);
            n_stim = 1;

            % start stim
            while and(~stim_finish, n_stim<=num_stim)

                if n_stim == dev_idx(n_trial)
                    stim_type = dev_seq(n_trial); 
                    reward_trial = 1;
                else
                    stim_type = ctx_seq{n_trial}(n_stim);
                    reward_trial = 0;
                end
                volt_stim = stim_type/ops.num_freqs*4;
                
                s_run_tone;
                
                % pause for isi                
                start_reward = now*86400;
                reward_duration = ops.isi_time+rand(1)*ops.rand_time_pad;
                
                s_run_reward_period;

                % finish
                time_stim{n_trial}(n_stim) = start_stim-start_paradigm;
                n_stim = n_stim  + 1;
            end
        end
        fprintf('Trials=%d; correct licks=%d; lick rate=%.2f; reward type=%d; high=%d low=%d none=%d\n', n_trial, sum(reward_type>0), reward_onset_lick_rate(n_trial), reward_type(n_trial), sum(reward_type==3),sum(reward_type==2) ,sum(reward_type==1));
    end
    
    pause(ops.post_trial_delay);
    
end

%%
session.write([0,0,0,0]);
if ops.sound_TD_amp
    RP.Halt;
end
%write(arduino_port, 2, 'uint8'); % turn off LED

pause(5);
session.write([0,3,0,0]);
time_paradigm_end = now*86400 - start_paradigm;
pause(1);
session.write([0,0,0,0]);
pause(5);

%% collect data
%trial_data.mmn_red_dev_seq = mmn_red_dev_seq;
trial_data.dev_seq = dev_seq;
if strcmpi(ops.trial_ctx_type, 'quiet')
    trial_data.dev_times = dev_times;
else
    trial_data.dev_idx = dev_idx;
end
trial_data.time_trial_start = time_trial_start;
trial_data.time_reward_period_start = time_reward_period_start;
trial_data.time_correct_lick = time_correct_lick;
trial_data.reward_onset_num_licks = reward_onset_num_licks;
trial_data.reward_onset_lick_rate = reward_onset_lick_rate;
trial_data.reward_type = reward_type;
trial_data.num_trials = n_trial;
trial_data.time_lick = time_lick_on(time_lick_on>0);
trial_data.time_paradigm_end = time_paradigm_end;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name],  'trial_data', 'ops');

%% plot
reward_onset_lick_rate2 = reward_onset_lick_rate(reward_type>0);
full_thresh_50 = prctile(reward_onset_lick_rate2, 50);
full_thresh_15 = prctile(reward_onset_lick_rate2, 15);
if ~strcmpi(ops.trial_ctx_type, 'quiet')
    num_red = dev_idx(reward_type>0)-1;
    num_red_u = unique(num_red);

    var_thresh_50 = zeros(numel(num_red_u),1);
    var_thresh_15 = zeros(numel(num_red_u),1);
    for ii = 1:numel(num_red_u)
        temp_data = reward_onset_lick_rate2(num_red == num_red_u(ii));
        var_thresh_50(ii) = prctile(temp_data, 50);
        var_thresh_15(ii) = prctile(temp_data, 15);
    end
    
    figure; hold on;
    plot(num_red, reward_onset_lick_rate2, 'o');
    plot(num_red_u, var_thresh_50);
    plot(num_red_u, var_thresh_15);
    plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_50);
    plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_15);
    legend('lick rate', 'var thresh 50%', 'var thresh 15%', 'full thresh 50', 'full thresh 15');
    title('lick rate vs num redundants');
end
fprintf('Analysis: 50%% thresh = %.2f; 15%% thesh = %.2f\n', full_thresh_50, full_thresh_15);

