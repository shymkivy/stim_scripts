if reward_trial
    % add flash if you want before reward starts
    if ops.reward_period_flash
        f_write_daq_out(session, [0,0,1,0], old_daq); %write(arduino_port, 1, 'uint8'); % turn on LED
        f_write_daq_out(session, [0,0,1,0], old_daq);
        pause(.005);
        f_write_daq_out(session, [0,0,0,0], old_daq); %write(arduino_port, 2, 'uint8'); % turn off LED
        f_write_daq_out(session, [0,0,0,0], old_daq);
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

if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
else
    sound(all_tones(stim_type,:), Fs);
end

volt = volt_stim;
f_write_daq_out(session, [volt,0,0,0], old_daq);
f_write_daq_out(session, [volt,0,0,0], old_daq);
%%
start_reward = start_stim;
reward_duration = ops.reward_window;

if ops.lick_to_get_reward
    s_run_reward_period;
else
    f_write_daq_out(session, [volt,0,0,1], old_daq); % write(arduino_port, 3, 'uint8');
    pause(ops.water_dispense_duration_large);
    f_write_daq_out(session, [volt,0,0,0], old_daq);
    reward_type(n_trial) = 3; 
    while (now*86400 - start_reward) < reward_duration
        data_in = f_read_daq_out(session, old_daq);
        s_get_lick_state;
    end
end
%%

if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', ops.base_freq);
end
f_write_daq_out(session, [0,0,0,0], old_daq);
f_write_daq_out(session, [0,0,0,0], old_daq);
volt = 0;