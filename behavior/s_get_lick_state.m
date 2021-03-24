transition_volt = data_in - last_volt;
lick_transition = 0;
if transition_volt > ops.transition_thresh % if lick state went low -> high
    time_now = now*86400;
    if (time_now - last_lick_low_time) > 0.005
        last_lick_high_time = time_now;
        n_lick_on = n_lick_on + 1;
        time_lick_on(n_lick_on) = last_lick_high_time - start_paradigm;
        last_lick_state = 1;
        lick_transition = 1;
        %disp('lick on');
        num_trial_licks = num_trial_licks + 1;
    end
elseif transition_volt < -ops.transition_thresh % if lick state went high -> low
    time_now = now*86400;
    if (time_now - last_lick_high_time) > 0.005
        last_lick_low_time = time_now;
        n_lick_off = n_lick_off + 1;
        time_lick_off(n_lick_off) = last_lick_low_time - start_paradigm;
        lick_transition = -1;
        last_lick_state = 0;
        %disp('lick off');
    end
end
last_volt = data_in;
