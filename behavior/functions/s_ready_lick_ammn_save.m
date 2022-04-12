%%
f_write_daq_out(session, [0,0,0,0], old_daq);
RP.Halt;
%write(arduino_port, 2, 'uint8'); % turn off LED

pause(5);
f_write_daq_out(session, [0,3,0,0], old_daq);
time_paradigm_end = now*86400 - start_paradigm;
pause(1);
f_write_daq_out(session, [0,0,0,0], old_daq);
pause(5);

%% collect data
trial_data.mmn_red_dev_seq = mmn_red_dev_seq;
trial_data.dev_idx = dev_idx;
trial_data.time_trial_start = time_trial_start;
trial_data.time_reward_period_start = time_reward_period_start;
trial_data.time_correct_lick = time_correct_lick;
trial_data.reward_onset_num_licks = reward_onset_num_licks;
trial_data.reward_onset_lick_rate = reward_onset_lick_rate;
trial_data.reward_type = reward_type;
trial_data.num_trials = n_trial;
trial_data.time_lick = time_lick_on(time_lick_on>0);
trial_data.time_paradigm_end = time_paradigm_end;

temp_time = clock;
file_name = sprintf('%s_%d_%d_%d_%dh_%dm.mat',fname, temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
save([save_path file_name],  'trial_data', 'ops');

%% plot 
num_red = dev_idx(reward_type>0)-1;
num_red_u = unique(num_red);
reward_onset_lick_rate2 = reward_onset_lick_rate(reward_type>0);
var_thresh_50 = zeros(numel(num_red_u),1);
var_thresh_15 = zeros(numel(num_red_u),1);
for ii = 1:numel(num_red_u)
    temp_data = reward_onset_lick_rate2(num_red == num_red_u(ii));
    var_thresh_50(ii) = prctile(temp_data, 50);
    var_thresh_15(ii) = prctile(temp_data, 15);
end
full_thresh_50 = prctile(reward_onset_lick_rate2, 50);
full_thresh_15 = prctile(reward_onset_lick_rate2, 15);
figure; hold on;
plot(num_red, reward_onset_lick_rate2, 'o');
plot(num_red_u, var_thresh_50);
plot(num_red_u, var_thresh_15);
plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_50);
plot(num_red_u, ones(numel(num_red_u),1)*full_thresh_15);
legend('lick rate', 'var thresh 50%', 'var thresh 15%', 'full thresh 50', 'full thresh 15');
title('lick rate vs num redundants');

fprintf('Analysis: 50%% thresh = %.2f; 15%% thesh = %.2f\n', full_thresh_50, full_thresh_15);

