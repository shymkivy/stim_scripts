function [state, data] = f_run_reward_pause(state, data, ops, session)

while now*86400 < state.end_pause
    data_in = f_read_daq_out(session, ops.old_daq);
    [state, data] = f_get_lick_state(data_in, state, data, ops);
    if state.lick_transition>0 % if a new lick
        if ~data.reward_type(state.n_trial) % if not rewarded yet continue
            % is still within reward period
            if now*86400 < state.end_reward
                data.time_correct_lick(state.n_trial) = now*86400 - state.start_paradigm;
                if state.trial_lick_rate<ops.reward_lick_rate_thersh_large
                    data.reward_type(state.n_trial) = 3;        % large reward
                    data.time_reward(state.n_trial) = now*86400 - state.start_paradigm;
                    f_write_daq_out(session, [state.volt_stim,0,0,1], ops.old_daq);
                    pause(ops.water_dispense_duration_large);
                    f_write_daq_out(session, [state.volt_stim,0,0,0], ops.old_daq);
                elseif state.trial_lick_rate<ops.reward_lick_rate_thersh_small
                    data.reward_type(state.n_trial) = 2;        % small reward
                    data.time_reward(state.n_trial) = now*86400 - state.start_paradigm;
                    f_write_daq_out(session, [state.volt_stim,0,0,1], ops.old_daq); % write(arduino_port, 3, 'uint8');
                    pause(ops.water_dispense_duration_small);
                    f_write_daq_out(session, [state.volt_stim,0,0,0], ops.old_daq);
                else
                    data.reward_type(state.n_trial) = 1;        % no reward
                end
            end
        end
    end
end

end