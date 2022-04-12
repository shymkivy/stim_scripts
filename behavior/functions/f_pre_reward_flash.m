function f_pre_reward_flash(reward_trial, session, ops)

if reward_trial
    % add flash if you want before reward starts
    if ops.reward_period_flash
        f_write_daq_out(session, [0,0,1,0], ops.old_daq); %write(arduino_port, 1, 'uint8'); % turn on LED
        f_write_daq_out(session, [0,0,1,0], ops.old_daq);
        pause(.005);
        f_write_daq_out(session, [0,0,0,0], ops.old_daq); %write(arduino_port, 2, 'uint8'); % turn off LED
        f_write_daq_out(session, [0,0,0,0], ops.old_daq);
    end
end
