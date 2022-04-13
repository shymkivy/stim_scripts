function [state, data] = f_run_tone_stim(state, data, ops, RP, session, stim_data)

% play
if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', stim_data.control_carrier_freq(state.stim_type));
else
    sound(stim_data.all_tones(state.stim_type,:), Fs);
end

volt_cmd = ops.volt_cmd;
volt_cmd(ops.stim_chan) = state.volt_stim;
volt_cmd(ops.SLM_stim_chan) = state.SLM_volt;
f_write_daq_out(session, volt_cmd, ops.old_daq);
f_write_daq_out(session, volt_cmd, ops.old_daq);

if ~ops.lick_to_get_reward
    data.time_reward(state.n_trial) = now*86400 - state.start_paradigm;
    volt_cmd(ops.reward_chan) = 1;
    f_write_daq_out(session, volt_cmd, ops.old_daq); % write(arduino_port, 3, 'uint8');
    pause(ops.water_dispense_duration_large);
    volt_cmd(ops.reward_chan) = 0;
    f_write_daq_out(session, volt_cmd, ops.old_daq);
    data.reward_type(state.n_trial) = 3;
end

state.end_pause = state.start_stim + ops.stim_delay;
[state, data] = f_run_reward_pause(state, data, ops, session);
volt_cmd(ops.trig_chan) = trig_volt;
f_write_daq_out(session, volt_cmd, ops.old_daq);
f_write_daq_out(session, volt_cmd, ops.old_daq);

state.end_pause = state.start_stim + ops.stim_delay + ops.stim_trig_duration;
[state, data] = f_run_reward_pause(state, data, ops, session);
volt_cmd(ops.trig_chan) = 0;
f_write_daq_out(session, volt_cmd, ops.old_daq);
f_write_daq_out(session, volt_cmd, ops.old_daq);

state.end_pause = state.start_stim + ops.stim_time;
[state, data] = f_run_reward_pause(state, data, ops, session);

if ops.sound_TD_amp
    RP.SetTagVal('CarrierFreq', ops.base_freq);
end
f_write_daq_out(session, ops.volt_cmd, ops.old_daq);
f_write_daq_out(session, ops.volt_cmd, ops.old_daq);
state.volt_stim = 0;

end
