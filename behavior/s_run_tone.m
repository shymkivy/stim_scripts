if reward_trial
    % add flash if you want before reward starts
    if ops.reward_period_flash
        session.write([0,0,1,0]); %write(arduino_port, 1, 'uint8'); % turn on LED
        session.write([0,0,1,0]);
        pause(.005);
        session.write([0,0,0,0]); %write(arduino_port, 2, 'uint8'); % turn off LED
        session.write([0,0,0,0]);
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
session.write([volt,0,0,0]);
session.write([volt,0,0,0]);

%%
start_reward = start_stim;
reward_duration = ops.stim_time;

s_run_reward_period;
%%

if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', ops.base_freq);
end
session.write([0,0,0,0]);
session.write([0,0,0,0]);
volt = 0;