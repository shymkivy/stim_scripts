function [state, data] = f_get_lick_state(data_in, state, data, ops)

transition_volt = data_in - state.last_volt;
lick_transition = 0;
if transition_volt > ops.transition_thresh % if lick state went low -> high
    time_now = now*86400;
    if (time_now - state.last_lick_low_time) > 0.005
        last_lick_high_time = time_now;
        state.n_lick_on = state.n_lick_on + 1;
        data.time_lick_on(state.n_lick_on) = last_lick_high_time - state.start_paradigm;
        lick_transition = 1;
        state.last_lick_state = 1;
        %disp('lick on');
        state.num_trial_licks = state.num_trial_licks + 1;
    end
elseif transition_volt < -ops.transition_thresh % if lick state went high -> low
    time_now = now*86400;
    if (time_now - state.last_lick_high_time) > 0.005
        last_lick_low_time = time_now;
        state.n_lick_off = state.n_lick_off + 1;
        data.time_lick_off(state.n_lick_off) = last_lick_low_time - state.start_paradigm;
        lick_transition = -1;
        state.last_lick_state = 0;
        %disp('lick off');
    end
end
state.last_volt = data_in;
state.lick_transition = lick_transition;

end
