function trial_data = f_ready_lick_ammn_core(ops, session, RP)


time_trial_start = zeros(ops.trial_cap, 1);
time_reward_period_start = zeros(ops.trial_cap, 1);
time_correct_lick = zeros(ops.trial_cap, 1);
time_stim = cell(ops.trial_cap,1);
time_lick = zeros(ops.trial_cap*50,1);
reward_onset_num_licks = zeros(ops.trial_cap, 1);
reward_type = zeros(ops.trial_cap, 1);
reward_onset_lick_rate = zeros(ops.trial_cap, 1);
n_lick = 0;             % record all lick times
n_trial = 0;            
start_reward_period = -500;
last_lick_off_time = -500;
last_lick_state = 0;
while and((now*86400 - start_paradigm)<ops.paradigm_duration, n_trial<=ops.trial_cap)
    % wait for animal to stop licking for some time
    last_lick2 = now*86400;
    while (now*86400 - last_lick2)<ops.initial_stop_lick_period
        data_in = inputSingleScan(session);
        lick_state = data_in > ops.lick_thresh;
        if (lick_state - last_lick_state) > 0.9
            last_lick2 = now*86400;
            if (last_lick2 - last_lick_off_time) > 0.005
                n_lick = n_lick + 1;
                time_lick(n_lick) = last_lick2 - start_paradigm;
            end
        elseif (lick_state - last_lick_state) < -0.9
            last_lick_off_time = now*86400;
        end
        last_lick_state = lick_state;
    end
    
    % trial available, wait for lick to start
    lick = 0;
    session.outputSingleScan([0,0,1,0]); %write(arduino_port, 1, 'uint8');
    while and(~lick, (now*86400 - start_paradigm)<ops.paradigm_duration)
        data_in = inputSingleScan(session);
        lick_state = data_in > ops.lick_thresh;
        if (lick_state - last_lick_state) > 0.9
            lick = 1;
            last_lick2 = now*86400;
            if (last_lick2 - last_lick_off_time) > 0.005
                n_lick = n_lick + 1;
                time_lick(n_lick) = last_lick2 - start_paradigm;
            end
        elseif (lick_state - last_lick_state) < -0.9
            last_lick_off_time = now*86400;
        end
        last_lick_state = lick_state;
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
        num_trial_licks2 = 0;
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
                reward_onset_num_licks(n_trial) = num_trial_licks2;
                reward_onset_lick_rate(n_trial) = num_trial_licks2/(now*86400 - start_trial);
            end
            RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
            session.outputSingleScan([volt,0,0,0]);
            session.outputSingleScan([volt,0,0,0]);
            while (now*86400 - start_stim) < ops.stim_time
                data_in = inputSingleScan(session);
                lick_state = data_in > ops.lick_thresh;
                if (lick_state - last_lick_state) > 0.9
                    last_lick2 = now*86400;
                    if (last_lick2 - last_lick_off_time) > 0.005 % to prevent recording noise
                        n_lick = n_lick + 1;
                        time_lick(n_lick) = last_lick2 - start_paradigm;
                        num_trial_licks2 = num_trial_licks2 + 1;
                    end
                    if ~reward_type(n_trial)
                        if (now*86400 - start_reward_period) < ops.reward_window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            if reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_large
                                reward_type(n_trial) = 3;        % large reward
                                session.outputSingleScan([volt,0,0,1]); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_large);
                                session.outputSingleScan([volt,0,0,0]);
                            elseif reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_small
                                reward_type(n_trial) = 2;        % small reward
                                session.outputSingleScan([volt,0,0,1]); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_small);
                                session.outputSingleScan([volt,0,0,0]);
                            else
                                reward_type(n_trial) = 1;        % no reward
                            end
                        end
                    end
                elseif (lick_state - last_lick_state) < -0.9
                    last_lick_off_time = now*86400;
                end
                last_lick_state = lick_state;
            end
            RP.SetTagVal('CarrierFreq', ops.base_freq);
            session.outputSingleScan([0,0,0,0]);
            session.outputSingleScan([0,0,0,0]);
            
            % pause for isi
            start_isi = now*86400;
            isi_duration = ops.isi_time+rand(1)*ops.rand_time_pad;
            while (now*86400 - start_isi) < isi_duration
                data_in = inputSingleScan(session);
                lick_state = data_in > ops.lick_thresh;
                if (lick_state - last_lick_state) > 0.9
                    last_lick2 = now*86400;
                    if (last_lick2 - last_lick_off_time) > 0.005
                        n_lick = n_lick + 1;
                        time_lick(n_lick) = last_lick2 - start_paradigm;
                        num_trial_licks2 = num_trial_licks2 + 1;
                    end
                    if ~reward_type(n_trial)
                        if (now*86400 - start_reward_period) < ops.reward_window
                            time_correct_lick(n_trial) = now*86400 - start_paradigm;
                            if reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_large
                                reward_type(n_trial) = 3;        % large reward
                                session.outputSingleScan([volt,0,0,1]); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_large);
                                session.outputSingleScan([volt,0,0,0]);
                            elseif reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_small
                                reward_type(n_trial) = 2;        % small reward
                                session.outputSingleScan([volt,0,0,1]); % write(arduino_port, 3, 'uint8');
                                pause(ops.water_dispense_duration_small);
                                session.outputSingleScan([volt,0,0,0]);
                            else
                                reward_type(n_trial) = 1;        % no reward
                            end
                        end
                    end
                elseif (lick_state - last_lick_state) < -0.9
                    last_lick_off_time = now*86400;
                end
                last_lick_state = lick_state;
            end
            
            time_stim{n_tr}(n_stim) = start_stim-start_paradigm;
            
            n_stim = n_stim  + 1;
        end
        fprintf('Trials=%d; correct licks=%d; lick rate=%.2f; reward type=%d; high=%d low=%d none=%d\n', n_trial, sum(reward_type>0), reward_onset_lick_rate(n_trial), reward_type(n_trial), sum(reward_type==3),sum(reward_type==2) ,sum(reward_type==1));
    end
    
    pause(ops.post_trial_delay);
    
end

%% cpllect data
trial_data.mmn_red_dev_seq = mmn_red_dev_seq;
trial_data.dev_idx = dev_idx;
trial_data.time_trial_start = time_trial_start;
trial_data.time_reward_period_start = time_reward_period_start;
trial_data.time_correct_lick = time_correct_lick;
trial_data.time_paradigm_end = time_paradigm_end;
trial_data.reward_onset_num_licks = reward_onset_num_licks;
trial_data.reward_onset_lick_rate = reward_onset_lick_rate;
trial_data.reward_type = reward_type;
trial_data.num_trials = n_trial;
trial_data.time_lick = time_lick(time_lick>0);

end