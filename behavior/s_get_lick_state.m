temp_lick_state = data_in > ops.lick_thresh;
temp_lick_transition = temp_lick_state - last_lick_state;
lick_transition = 0;
if temp_lick_transition > 0.9 % if lick state went low -> high
    time_now = now*86400;
    if (time_now - last_lick_low_time) > 0.005
        last_lick_high_time = time_now;
        n_lick_on = n_lick_on + 1;
        time_lick_on(n_lick_on) = last_lick_high_time - start_paradigm;
        last_lick_state = temp_lick_state;
        lick_transition = temp_lick_transition;
    end
elseif temp_lick_transition < -0.9 % if lick state went high -> low
    time_now = now*86400;
    if (time_now - last_lick_high_time) > 0.005
        last_lick_low_time = time_now;
        n_lick_off = n_lick_off + 1;
        time_lick_off(n_lick_off) = last_lick_low_time - start_paradigm;
        last_lick_state = temp_lick_state;
        lick_transition = temp_lick_transition;
    end
end

