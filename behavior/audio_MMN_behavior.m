%% audio MMN bahevior in bouts
%
%   last update: 1/8//21
%   trial structure:
%       trial start
%       
%   
%
%%
clear;

%% parameters
ops.num_trials = 400;

% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
ops.rand_time_pad = .05;

%% MMN trial params
ops.stim_range = [3 4 5 6 7];
ops.red_pre_trial = 3;
ops.red_post_trial = 3;
ops.red_lim = 20; % min lim is 5;
ops.MMN_probab=[0.1*ones(1,max(ops.red_lim-4,1)) .2 .25 .5 1]; 

%%
ops.intertrial_delay = 2;

% probability of deviants   % MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab
% ------ Other ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization

% ----- auditory stim params ------------
ops.start_freq = 2000;
% ops.end_freq = 90000;

ops.num_freqs = 10;
ops.increase_factor = 1.5;
ops.MMN_patterns = [3,6; 4,7; 3,8];
ops.base_freq = 0.001; % baseline frequency
ops.modulation_amp = 4 ;

%%
pwd2 = fileparts(which('audio_MMN_behavior.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';

temp_time = clock;
file_name = sprintf('aMMN_tones_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

%% design stim
% generate control frequencies
control_carrier_freq = zeros(1, ops.num_freqs);
control_carrier_freq(1) = ops.start_freq;
for n_stim = 2:ops.num_freqs
    control_carrier_freq(n_stim) = control_carrier_freq(n_stim-1) * ops.increase_factor;
end

%% design stim types sequence
dev_idx = zeros(ops.num_trials,1);
dev_ctx = 0;
for n_tr = 1:ops.num_trials
    n_stim = 1;
    while ~dev_ctx
        curr_prob = ops.MMN_probab(n_stim);
        dev_ctx = (rand(1) < curr_prob);
        if dev_ctx
            dev_idx(n_tr) = n_stim;
        else
            n_stim = n_stim + 1;
        end
    end
    dev_ctx = 0;
end
dev_idx = dev_idx + ops.red_pre_trial;

% stim types
mmn_red_dev_seq = zeros(ops.num_trials,2);
for n_tr = 1:ops.num_trials
    mmn_red_dev_seq(n_tr,:) = randsample(ops.stim_range, 2, 0);
end

% figure; histogram(dev_idx);
% figure; histogram(mmn_red_dev_seq(:,1));
% figure; histogram(mmn_red_dev_seq(:,2));


%% predicted run time
run_time = (ops.stim_time+ops.isi_time+ops.rand_time_pad/2)*sum(dev_idx+ops.red_post_trial) + (ops.num_trials)*ops.intertrial_delay + 20 + 60;
fprintf('Expected run duration: %.1fmin (%.fsec)\n',run_time/60,run_time);


%% initialize RZ6
RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
RP.Halt;

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,0]);

%% Run trials
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);
start_paradigm=now*1e5;%GetSecs();

IF_pause_synch(10, session, ops.synch_pulse)
h = waitbar(0, 'initializeing...');
trial_times = zeros(ops.num_trials,1);
stim_times = cell(ops.num_trials,1);
for n_tr = 1:ops.num_trials
    start_trial1 = now*1e5;%GetSecs();
    num_stim = dev_idx(n_tr)+ops.red_post_trial;
    
    trial_times(n_tr) = start_trial1 - start_paradigm;
    stim_times{n_tr} = zeros(num_stim,1);
    
    waitbar(n_tr/ops.num_trials, h, sprintf('Trial %d, red %d, dev %d', n_tr, mmn_red_dev_seq(n_tr,1), mmn_red_dev_seq(n_tr,2)));
    
    for n_stim = 1:num_stim

        if n_stim == dev_idx(n_tr)
            stim_type = mmn_red_dev_seq(n_tr,2);
        else
            stim_type = mmn_red_dev_seq(n_tr,1);
        end
        volt =  stim_type/ops.num_freqs*4;
        
        % play
        start_stim = now*1e5;%GetSecs();
        RP.SetTagVal('CarrierFreq', control_carrier_freq(stim_type));
        session.outputSingleScan([volt,0]);
        session.outputSingleScan([volt,0]);
        pause(ops.stim_time);
        RP.SetTagVal('CarrierFreq', ops.base_freq);
        session.outputSingleScan([0,0]);
        session.outputSingleScan([0,0]);
        
        % pause for isi
        pause(ops.isi_time+rand(1)*ops.rand_time_pad)
        
        % record
        stim_times{n_tr}(n_stim) = start_stim-start_paradigm;
        %fprintf('; Angle %d\n', ang);
        
    end
    
    pause(ops.intertrial_delay);
    
end
close(h);

%%
IF_pause_synch(10, session, ops.synch_pulse)

%% close all
session.outputSingleScan([0,0]);
RP.Halt;

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount');
fprintf('Done\n');

%% functions

function pulse_time = IF_pause_synch(pause_time, session, synch)
    
    LED_on = 3; %foltage. if diameter of light circle is 1mm, then use 1.5.
    %if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

    % synch artifact
    if synch
        pause((pause_time - 1)/2);
        session.outputSingleScan([0,LED_on]);
        pulse_time = now*1e5;
        pause(1);
        session.outputSingleScan([0,0]);
        pause((pause_time - 1)/2);
    else
        pause(pause_time);
    end

end
