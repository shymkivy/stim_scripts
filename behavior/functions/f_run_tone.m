function [state, data] = f_run_tone(state, data, ops, RP, session, all_tones)

% play
if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
else
    sound(all_tones(stim_type,:), Fs);
end

volt = state.volt_stim;
f_write_daq_out(session, [volt,0,0,0], ops.old_daq);
f_write_daq_out(session, [volt,0,0,0], ops.old_daq);

if ~ops.lick_to_get_reward
    data.time_reward(n_trial) = now*86400 - start_paradigm;
    f_write_daq_out(session, [volt,0,0,1], ops.old_daq); % write(arduino_port, 3, 'uint8');
    pause(ops.water_dispense_duration_large);
    f_write_daq_out(session, [volt,0,0,0], ops.old_daq);
    data.reward_type(n_trial) = 3;
end

state.end_pause = state.start_stim + ops.stim_time;
[state, data] = f_run_reward_pause(state, data, ops, session);

if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', ops.base_freq);
end
f_write_daq_out(session, [0,0,0,0], ops.old_daq);
f_write_daq_out(session, [0,0,0,0], ops.old_daq);
state.volt_stim = 0;

end
