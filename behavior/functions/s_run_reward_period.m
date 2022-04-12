while (now*86400 - start_reward) < reward_duration
    data_in = f_read_daq_out(session, old_daq);
    s_get_lick_state;
    if lick_transition>0 % if a new lick
        if ~reward_type(n_trial) % if not rewarded yet continue
            % is still within reward period
            if (now*86400 - start_reward_period) < ops.reward_window
                time_correct_lick(n_trial) = now*86400 - start_paradigm;
                if reward_onset_lick_rate(n_trial)<ops.reward_lick_rate_thersh_large
                    reward_type(n_trial) = 3;        % large reward
                    f_write_daq_out(session, [volt,0,0,1], old_daq);
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